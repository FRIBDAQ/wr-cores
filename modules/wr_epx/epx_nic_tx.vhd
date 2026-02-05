-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  Mini-NIC for 10G endpoint - TX part
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;
use work.epx_pkg.all;

entity epx_nic_tx is
  generic (
    g_tx_log_sz : natural := 10  -- 8*(2**g_tx_log_sz) data bytes
  );
  port (
    --  For the WB port
    clk_sys_i : in std_logic;
    rst_sys_n_i : in std_logic;

    clk_tx_i : in std_logic;
    rst_tx_n_i : in std_logic;

    --  User reset
    --  Cloked by clk_sys_i
    reset_tx_i : in std_logic;

    --  Data ram
    --  Clocked by clk_sys_i
    buf_addr_i : in std_logic_vector(g_tx_log_sz - 1 downto 0);
    buf_data_i : in std_logic_vector(63 downto 0);
    buf_we_i : in std_logic;

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
    pkt_addr_i : in std_logic_vector(g_tx_log_sz - 1 downto 0);
    pkt_len_i : in std_logic_vector(g_tx_log_sz + 2 downto 0);
    pkt_ready_i : in std_logic;
    pkt_done_o : out std_logic;
    --  TODO: add timestamp, filter flags...

    --  Source to framer
    --  Clocked by clk_tx_i
    data_o : out std_logic_vector(63 downto 0);
    ready_i : in std_logic;
    start_o : out std_logic;
    last_o : out std_logic;
    len_o : out std_logic_vector(2 downto 0)
  );
end epx_nic_tx;

architecture arch of epx_nic_tx is
  type t_tx_state is (S_IDLE, S_DATA);

  type t_state is record
    state : t_tx_state;

    --  One extra bit for address to make the difference between all full and
    --  all empty.
    tx_addr : unsigned(g_tx_log_sz - 1 downto 0);

    tx_pkt_len : unsigned(g_tx_log_sz - 1 downto 0);
    tx_nbytes : std_logic_vector(2 downto 0);
    tx_start : std_logic;
    tx_last : std_logic;
  end record;

  signal state, n_state : t_state;

  --  reset_tx_i in the clk_tx_i domain
  signal reset_tx_tx : std_logic;

  signal sync_pkt_in, sync_pkt_out : std_logic_vector(2 * g_tx_log_sz + 2 downto 0);
  signal sync_pkt_tx : std_logic;
  signal pkt_addr_tx : std_logic_vector(g_tx_log_sz - 1 downto 0);
  signal pkt_len_tx : std_logic_vector(g_tx_log_sz + 2 downto 0);

  signal pkt_done_tx, pkt_done_p : std_logic;
begin

  --  Synchronizer from clk_sys to clk_tx.
  sync_pkt_in <= pkt_len_i & pkt_addr_i;
  pkt_addr_tx <= sync_pkt_out(g_tx_log_sz - 1 downto 0);
  pkt_len_tx <= sync_pkt_out(2*g_tx_log_sz + 2 downto g_tx_log_sz);

  inst_sync_pkt: entity work.gc_sync_word_wr
    generic map (
      g_auto_wr => false,
      g_width => 2 * g_tx_log_sz + 3
    )
    port map (
      clk_in_i => clk_sys_i,
      rst_in_n_i => rst_sys_n_i,
      clk_out_i => clk_tx_i,
      rst_out_n_i => rst_tx_n_i,
      data_i => sync_pkt_in,
      wr_i => pkt_ready_i,
      busy_o => open,
      ack_o => open,
      data_o => sync_pkt_out,
      wr_o => sync_pkt_tx
    );
  
  p_rx_data: process (clk_tx_i)
  begin
    if rising_edge(clk_tx_i) then
      if rst_tx_n_i = '0' or reset_tx_tx = '1' then
        state <= (state => S_IDLE,
                  tx_addr => (others => '0'),
                  tx_pkt_len => (others => 'X'),
                  tx_nbytes => (others => 'X'),
                  tx_start => '0',
                  tx_last => '0');
      else
        state <= n_state;
      end if;
    end if;
  end process;

  --  Sync for done.
  pkt_done_tx <= '1' when state.state = S_IDLE else '0';
  inst_sync_done: entity work.gc_sync_ffs
    port map (
      clk_i => clk_sys_i,
      rst_n_i => rst_sys_n_i,
      data_i => pkt_done_tx,
      synced_o => open,
      npulse_o => open,
      ppulse_o => pkt_done_p
    );

  process (clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_sys_n_i = '0' then
        pkt_done_o <= '1';
      else
        if pkt_ready_i = '1' then
          pkt_done_o <= '0';
        elsif pkt_done_p = '1' then
          pkt_done_o <= '1';
        end if;
      end if;
    end if;
  end process;
  
  len_o <= state.tx_nbytes;
  last_o <= state.tx_last;
  start_o <= state.tx_start;

  p_tx_data_comb: process (state, ready_i, sync_pkt_tx, pkt_addr_tx, pkt_len_tx)
  begin
    n_state <= state;

    case state.state is
      when S_IDLE =>
        if sync_pkt_tx = '1' then
          --  Save address and length
          n_state.tx_nbytes <= pkt_len_tx(2 downto 0);
          n_state.tx_pkt_len <= unsigned(pkt_len_tx(g_tx_log_sz + 2 downto 3));
          n_state.tx_addr <= unsigned(pkt_addr_tx);
          n_state.tx_start <= '1';
          n_state.tx_last <= '0';
          n_state.state <= S_DATA;
        end if;
      when S_DATA =>
        if ready_i = '1' then
          --  Beat has been accepted.
          n_state.tx_start <= '0';
          if state.tx_last = '1' then
            n_state.state <= S_IDLE;
            n_state.tx_last <= '0';
          else
            n_state.tx_addr <= state.tx_addr + 1;
            n_state.tx_pkt_len <= state.tx_pkt_len - 1;
            if state.tx_pkt_len = 2 then
              --  The next one is the last beat.
              n_state.tx_last <= '1';
            end if;
          end if;
        end if;
      end case;
  end process;

  inst_tx_dpram: entity work.generic_dpram
    generic map (
      g_data_width               => 64,
      g_size                     => 2**g_tx_log_sz,
      g_with_byte_enable         => false,
      g_addr_conflict_resolution => open,
      g_init_file                => open,
      g_fail_if_file_not_found   => open,
      g_implementation_hint      => open)
    port map (
      rst_n_i => rst_tx_n_i,
      clka_i  => clk_tx_i,
      bwea_i  => (others => '1'),
      wea_i   => '0',
      aa_i    => std_logic_vector(n_state.tx_addr),
      da_i    => (others => 'X'),
      qa_o    => data_o,

      clkb_i  => clk_sys_i,
      bweb_i  => (others => '1'),
      web_i   => buf_we_i,
      ab_i    => buf_addr_i,
      db_i    => buf_data_i,
      qb_o    => open);

  inst_sync_rx_reset: entity work.gc_pulse_synchronizer2
    port map (
      clk_in_i => clk_sys_i,
      rst_in_n_i => rst_sys_n_i,
      clk_out_i => clk_tx_i,
      rst_out_n_i => rst_tx_n_i,
      d_ready_o => open,
      d_ack_p_o => open,
      d_p_i => reset_tx_i,
      q_p_o => reset_tx_tx);
end arch;
