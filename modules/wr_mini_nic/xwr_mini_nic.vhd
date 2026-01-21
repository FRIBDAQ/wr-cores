-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2010 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : Mini Embedded DMA Network Interface Controller
-- Project    : WhiteRabbit Core
-------------------------------------------------------------------------------
-- File       : xwrsw_mini_nic.vhd
-- Author     : Grzegorz Daniluk, Tomasz Wlostowski
-- Company    : CERN BE-Co-HT
-- Created    : 2010-07-26
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wr_fabric_pkg.all;
use work.wishbone_pkg.all;
use work.wr_mini_nic_map_pkg.all;

entity xwr_mini_nic is
  generic (
    g_tx_fifo_size         : integer                        := 1024;
    g_rx_fifo_size         : integer                        := 2048;
    g_buffer_little_endian : boolean                        := false);
  port (
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

-------------------------------------------------------------------------------
-- Pipelined Wishbone interface
-------------------------------------------------------------------------------

    -- WBP Master (TX)
    src_o : out t_wrf_source_out;
    src_i : in  t_wrf_source_in;

    -- WBP Slave (RX)
    snk_o : out t_wrf_sink_out;
    snk_i : in  t_wrf_sink_in;

-------------------------------------------------------------------------------
-- TXTSU i/f
-------------------------------------------------------------------------------

    txtsu_port_id_i     : in  std_logic_vector(4 downto 0);
    txtsu_frame_id_i    : in  std_logic_vector(16 - 1 downto 0);
    txtsu_tsval_i       : in  std_logic_vector(28 + 4 - 1 downto 0);
    txtsu_tsincorrect_i : in  std_logic;
    txtsu_stb_i         : in  std_logic;
    txtsu_ack_o         : out std_logic;

-------------------------------------------------------------------------------
-- Wishbone slave
-------------------------------------------------------------------------------

  wb_i : in  t_wishbone_slave_in;
  wb_o : out t_wishbone_slave_out;

-------------------------------------------------------------------------------
-- Interrupt output
-------------------------------------------------------------------------------

  int_o : out std_logic
    );
end xwr_mini_nic;

architecture wrapper of xwr_mini_nic is

  constant c_NTX_TIMEOUT : integer := 100;
  constant c_WRF_BYTESEL : std_logic_vector(1 downto 0) := "11";

  function f_swap_endian_16
    (
      data : std_logic_vector(15 downto 0)
      ) return std_logic_vector is
  begin
    if(g_buffer_little_endian = true) then
      return data(7 downto 0) & data(15 downto 8);
    else
      return data;
    end if;
  end function f_swap_endian_16;

  signal src_cyc_int   : std_logic;
  signal src_stb_int   : std_logic;
  signal snk_stall_int : std_logic;

-----------------------------------------------------------------------------
-- FIFO interface signals
-----------------------------------------------------------------------------

  signal tx_fifo_d : std_logic_vector(17 downto 0);
  signal tx_fifo_q : std_logic_vector(17 downto 0);
  alias  txf_type is tx_fifo_q(17 downto 16);
  alias  txf_data is tx_fifo_q(15 downto 0);
  signal tx_fifo_we, tx_fifo_rd : std_logic;
  signal tx_fifo_empty, tx_fifo_full : std_logic;
  signal rx_fifo_d : std_logic_vector(17 downto 0);
  signal rx_fifo_q : std_logic_vector(17 downto 0);
  signal rx_fifo_we, rx_fifo_rd : std_logic;
  signal rx_fifo_empty, rx_fifo_full : std_logic;
  signal rx_fifo_afull : std_logic;

  signal txf_ferror : std_logic;
  signal txf_fnew   : std_logic;
  signal tx_status_word : t_wrf_status_reg;


-------------------------------------------------------------------------------
-- TX FSM stuff
-------------------------------------------------------------------------------

  type t_tx_fsm_state is (TX_IDLE, TX_STATUS, TX_PACKET, TX_FLUSH, TX_END_PACKET);

  signal ntx_timeout_is_zero : std_logic;
  signal ntx_timeout         : unsigned(7 downto 0);

  signal ntx_ack_count     : unsigned(2 downto 0);

  signal ntx_state         : t_tx_fsm_state;
  signal ntx_rst_ts_ready  : std_logic;

  signal ntx_stored_dat : std_logic_vector(15 downto 0);
  signal ntx_stored_type : std_logic_vector(1 downto 0);
  signal ntx_flush_last  : std_logic;

-------------------------------------------------------------------------------
-- RX FSM stuff
-------------------------------------------------------------------------------

  signal snk_cyc_d0 : std_logic;
  signal nrx_sof : std_logic;
  signal nrx_eof : std_logic;
  alias rxf_type is rx_fifo_d(17 downto 16);
  alias rxf_data is rx_fifo_d(15 downto 0);

  type t_rx_fsm_state is (RX_WAIT_FRAME, RX_FRAME, RX_FULL);
  signal nrx_state    : t_rx_fsm_state;

-------------------------------------------------------------------------------
-- Classic Wishbone slave signals
-------------------------------------------------------------------------------

  signal regs_in  : t_mini_nic_regs_master_in;
  signal regs_out : t_mini_nic_regs_master_out;

  signal mcr_rx_en : std_logic;
begin
  regs_in.mcr_ver         <= x"1";

-------------------------------------------------------------------------------
-- Tx / Rx FIFO
-----------------------------------------------------------------------------
  TX_FIFO: entity work.generic_sync_fifo
    generic map(
      g_data_width => 18,
      g_size       => g_tx_fifo_size,
      g_with_almost_empty => false,
      g_with_almost_full  => false,
      g_with_count        => false,
      g_show_ahead        => true)
    port map (
      rst_n_i => rst_n_i,
      clk_i   => clk_sys_i,
      d_i     => tx_fifo_d,
      we_i    => tx_fifo_we,
      q_o     => tx_fifo_q,
      rd_i    => tx_fifo_rd,
      empty_o => tx_fifo_empty,
      full_o  => tx_fifo_full,
      count_o => open,
      almost_empty_o => open,
      almost_full_o => open);

  RX_FIFO: entity work.generic_sync_fifo
    generic map(
      g_data_width => 18,
      g_size       => g_rx_fifo_size,
      g_with_almost_empty => false,
      g_with_almost_full  => true,
      g_with_count        => false,
      g_almost_full_threshold => g_rx_fifo_size/2,
      g_show_ahead        => true)
    port map (
      rst_n_i => rst_n_i,
      clk_i   => clk_sys_i,
      d_i     => rx_fifo_d,
      we_i    => rx_fifo_we,
      q_o     => rx_fifo_q,
      rd_i    => rx_fifo_rd,
      empty_o => rx_fifo_empty,
      full_o  => rx_fifo_full,
      count_o => open,
      almost_full_o => rx_fifo_afull,
      almost_empty_o => open);

  tx_fifo_d  <= regs_out.tx_fifo_type & regs_out.tx_fifo_dat;
  tx_fifo_we <= regs_out.tx_fifo_wr;
  regs_in.mcr_tx_empty <= tx_fifo_empty;
  regs_in.mcr_tx_full  <= tx_fifo_full;

  regs_in.mcr_rx_empty  <= rx_fifo_empty;
  regs_in.rx_fifo_empty <= rx_fifo_empty;
  regs_in.mcr_rx_full   <= rx_fifo_full;
  regs_in.rx_fifo_full  <= rx_fifo_full;
  regs_in.rx_fifo_type  <= rx_fifo_q(17 downto 16);
  regs_in.rx_fifo_dat   <= rx_fifo_q(15 downto 0);
  rx_fifo_rd <= regs_out.rx_fifo_rd;

-------------------------------------------------------------------------------
-- TX Path  (Host -> Fabric)
-------------------------------------------------------------------------------

-- helper signals to avoid big IF conditions in the FSM
  ntx_timeout_is_zero <= '1' when (ntx_timeout = to_unsigned(0, ntx_timeout'length)) else '0';

  p_count_acks : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' or src_cyc_int = '0' or src_i.err = '1' then
        ntx_ack_count <= (others => '0');
      else
        if(src_stb_int = '1' and src_i.stall = '0' and src_i.ack = '0') then
          ntx_ack_count <= ntx_ack_count + 1;
        elsif(src_i.ack = '1' and not(src_stb_int = '1' and src_i.stall = '0')) then
          ntx_ack_count <= ntx_ack_count - 1;
        end if;
      end if;
    end if;
  end process;

  tx_status_word <= f_unmarshall_wrf_status(tx_fifo_q(15 downto 0));
  -- signals error in transmitted frame (set by software
  -- by writing again status register to TX Fifo
  txf_ferror <= '1' when (tx_fifo_empty = '0' and txf_type = c_WRF_STATUS and tx_status_word.error = '1') else
                '0';
  txf_fnew   <= '1' when (tx_fifo_empty = '0' and txf_type = c_WRF_STATUS and tx_status_word.error = '0') else
                '0';

  process (clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        mcr_rx_en <= '0';
      elsif regs_out.mcr_wr = '1' then
        mcr_rx_en <= regs_out.mcr_rx_en;
      end if;
    end if;
  end process;

  regs_in.mcr_rx_en <= mcr_rx_en;

  p_tx_fsm: process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if (rst_n_i = '0') then
        src_cyc_int <= '0';
        src_stb_int <= '0';
        src_o.sel   <= "11";
        src_o.adr   <= c_WRF_DATA;
        tx_fifo_rd  <= '0';
        ntx_rst_ts_ready <= '0';
        ntx_state   <= TX_IDLE;
        ntx_stored_dat <= (others=>'0');
        ntx_stored_type <= (others=>'0');
        ntx_flush_last <= '0';
      else
        case ntx_state is
          when TX_IDLE =>
            regs_in.mcr_tx_error <= '0';
            src_cyc_int <= '0';
            src_stb_int <= '0';
            src_o.sel   <= "11";
            src_o.adr   <= txf_type;
            ntx_timeout <= to_unsigned(c_NTX_TIMEOUT, ntx_timeout'length);
            ntx_flush_last <= '0';
            if (tx_fifo_empty = '0' and txf_fnew = '0') then
              -- if there is something in the fifo but it's not a status word,
              -- we read until we find a valid status. In this case we indicate
              -- that Minic is busy by driving wbreg bit tx_idle to 0.
              tx_fifo_rd <= '1';
              ntx_rst_ts_ready <= '0';
              regs_in.mcr_tx_idle  <= '0';
            elsif (tx_fifo_empty = '0' and txf_fnew = '1'
                   and regs_out.mcr_wr = '1' and regs_out.mcr_tx_start = '1')
            then
              -- we have a new frame to be sent, proceed..
              src_cyc_int <= '1';
              tx_fifo_rd <= '1';
              ntx_rst_ts_ready <= '1';
              regs_in.mcr_tx_idle  <= '0';
              ntx_state  <= TX_STATUS;
            else
              -- wait quietly for something to be written to FIFO
              tx_fifo_rd <= '0';
              ntx_rst_ts_ready <= '0';
              regs_in.mcr_tx_idle  <= '1';
            end if;

          when TX_STATUS =>
            -- read first word of the frame from fifo and start transmission
            regs_in.mcr_tx_idle <= '0';
            ntx_rst_ts_ready      <= '0';
            src_cyc_int <= '1';
            src_stb_int <= '1';
            src_o.sel   <= "11";
            src_o.adr   <= c_WRF_STATUS;
            src_o.dat   <= f_swap_endian_16(txf_data);
            tx_fifo_rd <= '1';
            ntx_flush_last <= '0';
            ntx_state <= TX_PACKET;

          when TX_PACKET =>
            regs_in.mcr_tx_idle <= '0';
            ntx_rst_ts_ready      <= '0';
            src_cyc_int <= '1';
            if (tx_fifo_empty = '0' and src_i.stall = '0' and txf_ferror = '0' and txf_type = c_WRF_DATA) then
              -- normal situation, we send the payload of a frame
              src_o.adr   <= c_WRF_DATA;
              src_o.dat   <= f_swap_endian_16(txf_data);
              src_o.sel   <= "11";
              src_stb_int <= '1';
              tx_fifo_rd  <= '1';
              ntx_flush_last <= '0';
            elsif (tx_fifo_empty = '0' and src_i.stall = '0' and txf_ferror = '0' and txf_type = c_WRF_BYTESEL) then
              -- almost normal situation, only one byte of data is valid
              src_o.adr   <= c_WRF_DATA;
              src_o.dat   <= f_swap_endian_16(txf_data);
              src_o.sel   <= "10";
              src_stb_int <= '1';
              tx_fifo_rd  <= '1';
              ntx_flush_last <= '0';
            elsif (tx_fifo_empty = '0' and src_i.stall = '0' and txf_ferror = '0' and txf_type = c_WRF_OOB) then
              -- we got OOB in TXed frame, let's send it
              src_o.adr   <= c_WRF_OOB;
              src_o.dat   <= f_swap_endian_16(txf_data);
              src_o.sel   <= "11";
              src_stb_int <= '1';
              tx_fifo_rd  <= '1';
              ntx_flush_last <= '0';
            elsif ((tx_fifo_empty = '1' or txf_fnew = '1') and src_i.stall = '0') then
              -- we done with this frame
              src_o.adr  <= c_WRF_DATA;
              src_o.dat  <= f_swap_endian_16(txf_data);
              src_o.sel  <= "11";
              src_stb_int <= '0';
              tx_fifo_rd  <= '0';
              ntx_flush_last <= '0';
              ntx_state   <= TX_END_PACKET;
            else
              -- e.g. snk is stalling, we wait
              tx_fifo_rd  <= '0';
              src_stb_int <= '1';
              ntx_stored_dat <= txf_data;
              ntx_stored_type <= txf_type;
              if (tx_fifo_empty = '1') then
                ntx_flush_last <= '1';
              else
                ntx_flush_last <= '0';
              end if;
              ntx_state   <= TX_FLUSH;
            end if;

          when TX_FLUSH =>
            regs_in.mcr_tx_idle <= '0';
            ntx_rst_ts_ready      <= '0';
            src_cyc_int <= '1';
            if (src_i.stall = '0' and (ntx_stored_type = c_WRF_DATA or ntx_stored_type = c_WRF_OOB)) then
              src_o.adr   <= ntx_stored_type;
              src_o.dat   <= f_swap_endian_16(ntx_stored_dat);
              src_o.sel   <= "11";
            elsif (src_i.stall = '0' and ntx_stored_type = c_WRF_BYTESEL) then
              src_o.adr   <= c_WRF_DATA;
              src_o.dat   <= f_swap_endian_16(ntx_stored_dat);
              src_o.sel   <= "10";
            else
              src_stb_int <= '1';
              tx_fifo_rd  <= '0';
            end if;

            if (ntx_flush_last = '0' and src_i.stall = '0') then
              src_stb_int <= '1';
              tx_fifo_rd  <= '1';
              ntx_state   <= TX_PACKET;
            elsif (ntx_flush_last = '1' and src_i.stall = '0') then
              src_stb_int <= '0';
              tx_fifo_rd  <= '0';
              ntx_state   <= TX_END_PACKET;
            else
              src_stb_int <= '1';
              tx_fifo_rd  <= '0';
              ntx_state   <= TX_FLUSH;
            end if;

          when TX_END_PACKET =>
            regs_in.mcr_tx_idle <= '0';
            ntx_rst_ts_ready      <= '0';
            src_stb_int <= '0';
            -- timeout counter in case we never get all ACKs.
            ntx_timeout <= ntx_timeout - 1;
            if (ntx_ack_count = 0 or ntx_timeout_is_zero = '1') then
              regs_in.mcr_tx_error <= ntx_timeout_is_zero;
              src_cyc_int <= '0';
              src_o.sel   <= "11";
              tx_fifo_rd  <= '0';
              ntx_state   <= TX_IDLE;
            end if;
        end case;
      end if;
    end if;
  end process;

-- these are never used:
  src_o.we  <= '1';
  src_o.stb <= src_stb_int;
  src_o.cyc <= src_cyc_int;

-------------------------------------------------------------------------------
-- RX Path (Fabric ->  Host)
-------------------------------------------------------------------------------

  p_rx_gen_ack : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        snk_o.ack <= '0';
      else
        if(snk_i.cyc = '1' and snk_i.stb = '1' and snk_stall_int = '0') then
          snk_o.ack <= '1';
        else
          snk_o.ack <= '0';
        end if;
      end if;
    end if;

  end process;

  nrx_sof <= '1' when(snk_cyc_d0 = '0' and snk_i.cyc = '1') else
             '0';
  nrx_eof <= '1' when(snk_cyc_d0 = '1' and snk_i.cyc = '0') else
             '0';

  process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if (rst_n_i = '0') then
        snk_cyc_d0 <= '0';
        rx_fifo_we <= '0';
        rxf_type   <= (others=>'0');
        rxf_data   <= (others=>'0');
        snk_stall_int <= '0';
        regs_in.mcr_rx_ready <= '0';
        nrx_state  <= RX_WAIT_FRAME;

      else
        snk_cyc_d0 <= snk_i.cyc;

        case nrx_state is
          when RX_WAIT_FRAME =>
            rx_fifo_we <= '0';
            rxf_type   <= (others=>'0');
            rxf_data   <= (others=>'0');
            regs_in.mcr_rx_error  <= '0';
            if (mcr_rx_en = '1') then
              --  Stall at start of frame, will accept in RX_FRAME state.
              snk_stall_int <= not nrx_sof;
            else
              -- RX path is disabled, don't stall any traffic
              snk_stall_int <= '0';
            end if;

            -- wait for software to enable RX path and a start of new frame
            if (mcr_rx_en = '1' and nrx_sof = '1' and rx_fifo_full = '0') then
              nrx_state <= RX_FRAME;
            end if;

          when RX_FRAME =>
            snk_stall_int <= '0';
            -- receive frame, write it to FIFO
            if (snk_i.stb = '1' and snk_i.sel = "11") then
              rxf_type   <= snk_i.adr;
              rxf_data   <= f_swap_endian_16(snk_i.dat);
              rx_fifo_we <= '1';
            elsif (snk_i.stb = '1' and snk_i.sel = "10") then
              rxf_type   <= c_WRF_BYTESEL;
              rxf_data   <= f_swap_endian_16(snk_i.dat);
              rx_fifo_we <= '1';
            else
              rxf_type   <= (others=>'0');
              rxf_data   <= (others=>'0');
              rx_fifo_we <= '0';
            end if;

            if ((mcr_rx_en = '0' or nrx_eof = '1') and rx_fifo_full = '0') then
              -- stop writing FIFO if sw disables RX path
              -- or if we're done with current frame
              regs_in.mcr_rx_ready <= '1';
              regs_in.mcr_rx_error  <= '0';
              nrx_state              <= RX_WAIT_FRAME;
            elsif ((mcr_rx_en = '0' or nrx_eof = '1') and rx_fifo_full = '1') then
              -- the difference with the previous condition is that if the fifo
              -- is full on the last word, we don't set rx_error, because the
              -- frame was not cut (it fits in the FIFO). Besides that, we have
              -- to go to RX_FULL state to wait for the FIFO to be half-empty
              -- and receive more frames.
              regs_in.mcr_rx_ready <= '1';
              regs_in.mcr_rx_error  <= '0';
              nrx_state              <= RX_FULL;
            elsif (rx_fifo_full = '1') then
              -- error if fifo gets full needs to be recovered
              regs_in.mcr_rx_ready <= '1';
              regs_in.mcr_rx_error  <= '1';
              nrx_state <= RX_FULL;
            else
              regs_in.mcr_rx_ready <= '0';
              regs_in.mcr_rx_error  <= '0';

            end if;

          when RX_FULL =>
            snk_stall_int <= '0';
            rx_fifo_we <= '0';
            rxf_type   <= (others=>'0');
            rxf_data   <= (others=>'0');

            -- recovering means disabling RX path and reading everything from
            -- the FIFO
            --if (mcr_rx_en = '0' and rx_fifo_empty = '1') then
            --  nrx_state <= RX_WAIT_FRAME;
            --end if;
            if (snk_i.cyc = '0' and rx_fifo_afull = '0') then
              nrx_state <= RX_WAIT_FRAME;
            end if;
        end case;
      end if;
    end if;
  end process;


  snk_o.stall <= snk_stall_int;
  snk_o.err   <= '0';

-------------------------------------------------------------------------------
-- TX Timestamping unit
-------------------------------------------------------------------------------
  tsu_fsm : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if(rst_n_i = '0') then
        regs_in.mcr_tx_ts_ready <= '0';
        regs_in.tsr0_valid <= '0';
        regs_in.tsr0_pid   <= (others => '0');
        regs_in.tsr0_fid   <= (others => '0');
        regs_in.tsr1_tsval <= (others => '0');
        txtsu_ack_o          <= '0';
      else
        -- Make sure the timestamp is written to the FIFO only once.

        if(ntx_rst_ts_ready = '1') then
          regs_in.mcr_tx_ts_ready <= '0';
        elsif(txtsu_stb_i = '1') then
          regs_in.mcr_tx_ts_ready <= '1';
          regs_in.tsr0_valid <= not txtsu_tsincorrect_i;
          regs_in.tsr0_fid   <= txtsu_frame_id_i;
          regs_in.tsr0_pid   <= txtsu_port_id_i;
          regs_in.tsr1_tsval <= txtsu_tsval_i;
          txtsu_ack_o        <= '1';
        else
          txtsu_ack_o <= '0';
        end if;
      end if;
    end if;
  end process;

  inst_wr_minic_map: entity work.wr_mini_nic_map
    port map (
      rst_n_i          => rst_n_i,
      clk_i            => clk_sys_i,
      wb_i             => wb_i,
      wb_o             => wb_o,
      mini_nic_regs_i  => regs_in,
      mini_nic_regs_o  => regs_out);
end wrapper;
