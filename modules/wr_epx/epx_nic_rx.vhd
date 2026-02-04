-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  10G NIC - RX part
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;
use work.epx_pkg.all;

entity epx_nic_rx is
  generic (
    g_rx_log_sz : natural := 10;  -- 8*(2**g_rx_log_sz) data bytes
    g_rx_log_desc : positive := 3  -- 2**g_rx_log_desc rx descriptors
  );
  port (
    --  For the WB port
    clk_sys_i : in std_logic;
    rst_sys_n_i : in std_logic;

    clk_rx_i : in std_logic;
    rst_rx_n_i : in std_logic;

    --  User reset
    --  Cloked by clk_sys_i
    reset_rx_i : in std_logic;

    --  Data ram
    --  Clocked by clk_sys_i
    buf_addr_i : in std_logic_vector(g_rx_log_sz - 1 downto 0);
    buf_data_o : out std_logic_vector(63 downto 0);

    --  Current descriptor.
    --  Valid only if pkt_ready_o is set to '1'.
    --  pkt_addr_o is the address in the data ram, pkt_len_o is the coded
    --  length:
    --  vvvv000: vvvv * 8B block, the last 8B are valid
    --  vvvv001: vvvv * 8B block, the last 1B is valid
    --  vvvv010: vvvv * 8B block, the last 2B are valid
    --  ...
    --  vvvv111: vvvv * 8B block, the last 7B are valid
    --  The packet can be discarded (once consummed) by generating a pulse on
    --  pkt_done_i.
    pkt_addr_o : out std_logic_vector(g_rx_log_sz - 1 downto 0);
    pkt_len_o : out std_logic_vector(g_rx_log_sz + 2 downto 0);
    pkt_ready_o : out std_logic;
    pkt_done_i : in std_logic;
    --  TODO: add timestamp, filter flags...

    --  Source from transceiver
    --  Clocked by clk_rx_i
    data_i : in std_logic_vector(63 downto 0);
    valid_i : in std_logic;
    start_i : in std_logic;
    last_i : in std_logic;
    len_i : in std_logic_vector(2 downto 0);
    err_i : in std_logic;
    crc_ok_i : in std_logic
  );
end epx_nic_rx;

architecture arch of epx_nic_rx is
  type t_rx_state is (SR_IDLE, SR_DATA);

  type t_state is record
    state : t_rx_state;

    --  One extra bit for address to make the difference between all full and
    --  all empty.
    rx_cur_addr, rx_pkt_addr : unsigned(g_rx_log_sz downto 0);

    rx_pkt_len : unsigned(g_rx_log_sz - 1 downto 0);
    rx_data : std_logic_vector(63 downto 0);
    rx_wea : std_logic;

    --  To be written to the descriptor
    desc_len : std_logic_vector(g_rx_log_sz + 2 downto 0);
    desc_buff : std_logic_vector(g_rx_log_sz - 1 downto 0);
    desc_done : std_logic;
    desc_idx : unsigned(g_rx_log_desc downto 0);

    --  Extended index of the next descriptor to be filled
    desc_nxt : unsigned(g_rx_log_desc downto 0);
  end record;

  signal state, n_state : t_state;

  --  reset_rx_i in the clk_rx_i domain
  signal reset_rx_rx : std_logic;

  signal rx_last_addr : unsigned(g_rx_log_sz downto 0);
  signal rx_addr : std_logic_vector(g_rx_log_sz - 1 downto 0);

  signal desc_len_out : std_logic_vector(g_rx_log_sz + 2 downto 0);

  signal desc_last : std_logic_vector(g_rx_log_desc downto 0);
  signal desc_last_gray : std_logic_vector(g_rx_log_desc downto 0);

  --  Descriptors
  signal desc_done_d : std_logic;
  signal desc_addr : std_logic_vector(g_rx_log_desc - 1 downto 0) := (others => '0');
  constant desc_init : std_logic_vector(g_rx_log_desc downto 0) :=
    '1' & (g_rx_log_desc - 1 downto 0 => '0');

  --  desc_idx: index of the next descriptor that will be filled by rx
  --  desc_cur: index of the next descriptor for the user.  Filled as soon as
  --   desc_idx is different from it.
  signal desc_idx_gray, desc_idx_gray_sys : std_logic_vector(g_rx_log_desc downto 0);
  signal desc_cur_gray, desc_cur_gray_rx : std_logic_vector(g_rx_log_desc downto 0);
  signal desc_cur_usr : unsigned(g_rx_log_desc downto 0);

  signal desc_we, desc_rd : std_logic;

  signal pkt_addr : unsigned(g_rx_log_sz - 1 downto 0);
  signal pkt_len : std_logic_vector(g_rx_log_sz + 2 downto 0);
begin
  p_rx_data: process (clk_rx_i)
  begin
    if rising_edge(clk_rx_i) then
      if rst_rx_n_i = '0' or reset_rx_rx = '1' then
        state <= (state => SR_IDLE,
                  rx_cur_addr => (others => '0'),
                  rx_pkt_addr => (others => '0'),
                  rx_pkt_len => (others => 'X'),
                  rx_data => (others => 'X'),
                  rx_wea => '0',
                  desc_nxt => (others => '0'),
                  desc_idx => (others => 'X'),
                  desc_buff => (others => 'X'),
                  desc_len => (others => 'X'),
                  desc_done => '0');
      else
        state <= n_state;
      end if;
    end if;
  end process;

  p_rx_data_comb: process (state, valid_i, start_i, last_i, err_i, data_i, desc_last, rx_last_addr, len_i)
  begin
    n_state <= state;

    n_state.rx_wea <= '0';
    n_state.desc_done <= '0';

    case state.state is
      when SR_IDLE =>
        if valid_i = '1' and start_i = '1' and err_i = '0' then
          --  Start of a new packet.
          assert last_i = '0' severity failure;
          --  Can accept if descriptor is free and memory is free.
          if state.desc_nxt /= unsigned(desc_last)
            and state.rx_cur_addr /= rx_last_addr
          then
            --  Store first beat
            n_state.rx_data <= data_i;
            n_state.rx_wea <= '1';
            n_state.rx_cur_addr <= state.rx_pkt_addr;
            n_state.rx_pkt_len <= to_unsigned(1, g_rx_log_sz);
            n_state.state <= SR_DATA;
          end if;
        end if;
      when SR_DATA =>
        if err_i = '1' then
          --  Discard
          n_state.state <= SR_IDLE;
        elsif valid_i = '1' then
          if state.rx_cur_addr = rx_last_addr then
            --  RAM full, discard
            n_state.state <= SR_IDLE;
          else
            n_state.rx_data <= data_i;
            n_state.rx_wea <= '1';
            n_state.rx_cur_addr <= state.rx_cur_addr + 1;
            n_state.rx_pkt_len <= state.rx_pkt_len + 1;
            if last_i = '1' then
              n_state.rx_pkt_addr <= state.rx_cur_addr + 2;

              --  Write desc
              n_state.desc_len <=
                std_logic_vector(state.rx_pkt_len + 1) & len_i;
              n_state.desc_buff <= std_logic_vector(state.rx_pkt_addr(g_rx_log_sz - 1 downto 0));
              n_state.desc_idx <= state.desc_nxt;
              n_state.desc_done <= '1';

              n_state.desc_nxt <= state.desc_nxt + 1;

              n_state.state <= SR_IDLE;
            end if;
          end if;
        end if;
    end case;
  end process;

  --  Handle descriptors (RX side)
  p_desc_rx: process (clk_rx_i)
  begin
    if rising_edge(clk_rx_i) then
      desc_we <= '0';

      if rst_rx_n_i = '0' or reset_rx_rx = '1' then
        desc_last <= desc_init;
        desc_last_gray <= f_gray_encode(desc_init);

        rx_last_addr <= (others => '0');
        rx_last_addr(g_rx_log_sz) <= '1';

        desc_rd <= '0';

        desc_idx_gray <= (others => '0');
      else
        if desc_rd = '1' then
          --  Length is available from the released descriptor.
          rx_last_addr <= rx_last_addr
              + unsigned(desc_len_out(g_rx_log_sz + 3 - 1 downto 3));
          desc_rd <= '0';
          desc_last <= std_logic_vector(unsigned(desc_last) + 1);
          desc_last_gray <= f_gray_encode(std_logic_vector(unsigned(desc_last) + 1));
          --  Save desc_done
          desc_done_d <= state.desc_done;
        elsif state.desc_done = '1' or desc_done_d = '1' then
          --  Write descriptor once a packet has been received.
          desc_addr <= std_logic_vector(state.desc_idx(g_rx_log_desc - 1 downto 0));
          desc_we <= '1';
          desc_done_d <= '0';
          desc_idx_gray <= f_gray_encode(std_logic_vector(state.desc_idx + 1));
        elsif f_gray_encode(desc_last xor desc_init) /= desc_cur_gray_rx then
          --  A descriptor has been released by the user
          --  Read length and add to rx_last_addr
          desc_addr <= desc_last(g_rx_log_desc - 1 downto 0);
          desc_we <= '0';
          desc_rd <= '1';
        end if;
      end if;
    end if;
  end process;

  --  Descriptor handling (from sys domain)
  p_desc_sys: process (clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_sys_n_i = '0' or reset_rx_i = '1' then
        desc_cur_usr <= (others => '0');
        desc_cur_gray <= (others => '0');
        pkt_ready_o <= '0';
        pkt_addr <= (others => '0');
      else
        if desc_cur_gray /= desc_idx_gray_sys then
          --  At least one descriptor is available
          if pkt_done_i = '1' then
            desc_cur_usr <= desc_cur_usr + 1;
            desc_cur_gray <= f_gray_encode(std_logic_vector(desc_cur_usr + 1));
            --  We don't know yet if more than one.  Simply pretend no more
            --  descriptors available, it will be adjusted at the next cycle.
            pkt_ready_o <= '0';
            --  Update address
            pkt_addr <= pkt_addr
                + unsigned (pkt_len(g_rx_log_sz + 3 - 1 downto 3));
          else
            --  For sure, there is a descriptor available.
            pkt_ready_o <= '1';
          end if;
        else
          --  Should already be '0'.
          pkt_ready_o <= '0';
        end if;
      end if;
    end if;
  end process;

  rx_addr <= std_logic_vector(state.rx_cur_addr(g_rx_log_sz - 1 downto 0));

  inst_rx_dpram: entity work.generic_dpram
    generic map (
      g_data_width               => 64,
      g_size                     => 2**g_rx_log_sz,
      g_with_byte_enable         => false,
      g_addr_conflict_resolution => open,
      g_init_file                => open,
      g_fail_if_file_not_found   => open,
      g_implementation_hint      => open)
    port map (
      rst_n_i => rst_rx_n_i,
      clka_i  => clk_rx_i,
      bwea_i  => (others => '1'),
      wea_i   => state.rx_wea,
      aa_i    => rx_addr,
      da_i    => state.rx_data,
      qa_o    => open,

      clkb_i  => clk_sys_i,
      bweb_i  => (others => '1'),
      web_i   => '0',
      ab_i    => buf_addr_i,
      db_i    => (others => 'X'),
      qb_o    => buf_data_o);

  inst_desc_dpram: entity work.generic_dpram
    generic map (
      g_data_width               => g_rx_log_sz + 3,
      g_size                     => 2**g_rx_log_desc,
      g_with_byte_enable         => false,
      g_addr_conflict_resolution => open,
      g_init_file                => open,
      g_fail_if_file_not_found   => open,
      g_implementation_hint      => open)
    port map (
      rst_n_i => rst_rx_n_i,
      clka_i  => clk_rx_i,
      bwea_i  => (others => '1'),
      wea_i   => desc_we,
      aa_i    => desc_addr,
      da_i    => state.desc_len,
      qa_o    => desc_len_out,

      clkb_i  => clk_sys_i,
      bweb_i  => (others => '1'),
      web_i   => '0',
      ab_i    => std_logic_vector(desc_cur_usr(g_rx_log_desc - 1 downto 0)),
      db_i    => (others => 'X'),
      qb_o    => pkt_len);

  pkt_len_o <= pkt_len;
  pkt_addr_o <= std_logic_vector(pkt_addr);
  
  inst_sync_rx_reset: entity work.gc_pulse_synchronizer2
    port map (
      clk_in_i => clk_sys_i,
      rst_in_n_i => rst_sys_n_i,
      clk_out_i => clk_rx_i,
      rst_out_n_i => rst_rx_n_i,
      d_ready_o => open,
      d_ack_p_o => open,
      d_p_i => reset_rx_i,
      q_p_o => reset_rx_rx);

  inst_sync_desc_idx : entity work.gc_sync_register
    generic map (
      g_width => desc_idx_gray'length)
    port map (
      clk_i     => clk_sys_i,
      rst_n_a_i => rst_sys_n_i,
      d_i       => desc_idx_gray,
      q_o       => desc_idx_gray_sys);

  inst_sync_desc_cur : entity work.gc_sync_register
    generic map (
      g_width => desc_cur_gray'length)
    port map (
      clk_i     => clk_rx_i,
      rst_n_a_i => rst_rx_n_i,
      d_i       => desc_cur_gray,
      q_o       => desc_cur_gray_rx);

end arch;
