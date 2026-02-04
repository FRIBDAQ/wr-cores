-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  Mini-NIC for 10G endpoint
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;
use work.gencores_pkg.all;
use work.epx_pkg.all;

entity epx_mininic is
  generic (
    g_rx_log_sz : natural := 10;  -- 8*(2**g_rx_log_sz) data bytes
    g_tx_log_sz : natural := 10;  -- 8*(2**g_rx_log_sz) data bytes
    g_rx_log_desc : positive := 3  -- 2**g_rx_log_desc rx descriptors
  );
  port (
    --  For the WB port
    clk_sys_i : in std_logic;
    rst_sys_n_i : in std_logic;

    --  Clock for the RX port
    clk_rx_i   : in std_logic;
    rst_rx_n_i : in std_logic;

    --  Clock for the RX port
    clk_tx_i   : in std_logic;
    rst_tx_n_i : in std_logic;

    --  User port (clocked by clk_sys_i)
    wb_i       : in    t_wishbone_slave_in;
    wb_o       : out   t_wishbone_slave_out;

    --  Source from transceiver
    --  Clocked by clk_rx_i
    rx_data_i : in std_logic_vector(63 downto 0);
    rx_valid_i : in std_logic;
    rx_start_i : in std_logic;
    rx_last_i : in std_logic;
    rx_len_i : in std_logic_vector(2 downto 0);
    rx_err_i : in std_logic;
    rx_crc_ok_i : in std_logic;
    rx_locked_i : in std_logic;

        --  Source to framer
    --  Clocked by clk_tx_i
    tx_data_o : out std_logic_vector(63 downto 0);
    tx_ready_i : in std_logic;
    tx_start_o : out std_logic;
    tx_last_o : out std_logic;
    tx_len_o : out std_logic_vector(2 downto 0)

  );
end epx_mininic;

architecture arch of epx_mininic is
  signal rx_reset, tx_reset : std_logic;

  subtype t_rx_addr_range is natural range g_rx_log_sz -1 downto 0;
  subtype t_tx_addr_range is natural range g_tx_log_sz -1 downto 0;

  signal rxbuf_addr : std_logic_vector(t_rx_addr_range);
  signal rxbuf_data : std_logic_vector(63 downto 0);
  signal rxbuf_rd : std_logic;

  signal txbuf_addr : std_logic_vector(t_tx_addr_range);
  signal txbuf_addr_ext : std_logic_vector(31 downto 0) := (others => '0');
  signal txbuf_data : std_logic_vector(63 downto 0);
  signal tx_pkt_done : std_logic;
  signal tx_pkt_len : std_logic_vector(g_rx_log_sz+2 downto 0);
  signal txlen_len8 : std_logic_vector(12 downto 0);
  signal txlen_nbytes : std_logic_vector(2 downto 0);
  signal txlen_wr : std_logic;
  signal txbuf_wr : std_logic;

  signal rxlen_len8, rxlen_rem8 : std_logic_vector(12 downto 0);
  signal rxlen_nbytes : std_logic_vector(2 downto 0);
  signal stat_rxpkt, stat_rxpkt_d : std_logic;

  signal rxpkt_addr  : std_logic_vector(t_rx_addr_range);
  signal rxpkt_len   : std_logic_vector(g_rx_log_sz + 2 downto 0);
  signal rxpkt_ready : std_logic;
  signal rxpkt_done  : std_logic;

  type t_rxstate is (RX_IDLE, RX_READ);
  signal rxstate : t_rxstate;

begin
  inst_regs_map: entity work.epx_mininic_map
    port map (
      rst_n_i => rst_sys_n_i,
      clk_i => clk_sys_i,
      wb_i => wb_i,
      wb_o => wb_o,
      ctrl_rxreset_o => rx_reset,
      stat_rxpkt_i => stat_rxpkt,
      stat_rxlocked_i => rx_locked_i,
      stat_txdone_i => tx_pkt_done,
      rxlen_nbytes_i => rxlen_nbytes,
      rxlen_len8_i => rxlen_len8,
      rxlen_rem8_i => rxlen_rem8,
      rxdatah_i => rxbuf_data(63 downto 32),
      rxdatal_i => rxbuf_data(31 downto 0),
      rxdatal_rd_o => rxbuf_rd,
      txaddr_i => txbuf_addr_ext,
      txlen_nbytes_o => txlen_nbytes,
      txlen_len8_o => txlen_len8,
      txlen_wr_o => txlen_wr,
      txdatah_o => txbuf_data(63 downto 32),
      txdatal_o => txbuf_data(31 downto 0),
      txdatal_wr_o => txbuf_wr
      );

  txbuf_addr_ext(t_tx_addr_range) <= txbuf_addr;

  p_rx: process (clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      rxpkt_done <= '0';

      if rst_sys_n_i = '0' or rx_reset = '1' then
        rxstate <= RX_IDLE;
        rxbuf_addr <= (others => '0');
        stat_rxpkt <= '0';
        stat_rxpkt_d <= '0';
        rxlen_len8 <= (others => '0');
        rxlen_rem8 <= (others => '0');
      else
        stat_rxpkt_d <= stat_rxpkt;

        case rxstate is
          when RX_IDLE =>
            --  Also check stat_rxpkt_d to allow a delay for the FSM.
            if rxpkt_ready = '1' and stat_rxpkt_d = '0' then
              rxbuf_addr <= rxpkt_addr;
              rxlen_len8(t_rx_addr_range) <= rxpkt_len(g_rx_log_sz + 2 downto 3);
              rxlen_rem8(t_rx_addr_range) <= rxpkt_len(g_rx_log_sz + 2 downto 3);
              rxlen_nbytes <= rxpkt_len(2 downto 0);
              stat_rxpkt <= '1';
              rxstate <= RX_READ;
            end if;
          when RX_READ =>
            if rxbuf_rd = '1' then
              if unsigned(rxlen_rem8) = 1 then
                rxpkt_done <= '1';
                stat_rxpkt <= '0';
                rxstate <= RX_IDLE;
              else
                rxlen_rem8(t_rx_addr_range) <= std_logic_vector(unsigned(rxlen_rem8(t_rx_addr_range)) - 1);
                rxbuf_addr <= std_logic_vector(unsigned(rxbuf_addr) + 1);
              end if;
            end if;
        end case;
      end if;
    end if;
  end process;

  inst_nic_rx: entity work.epx_nic_rx
    generic map (
      g_rx_log_sz => g_rx_log_sz,
      g_rx_log_desc => g_rx_log_desc
      )
    port map (
      clk_sys_i => clk_sys_i,
      rst_sys_n_i => rst_sys_n_i,
      clk_rx_i => clk_rx_i,
      rst_rx_n_i => rst_rx_n_i,
      reset_rx_i => rx_reset,

      buf_addr_i => rxbuf_addr,
      buf_data_o => rxbuf_data,

      pkt_addr_o => rxpkt_addr,
      pkt_len_o => rxpkt_len,
      pkt_ready_o => rxpkt_ready,
      pkt_done_i => rxpkt_done,

      data_i   => rx_data_i,
      valid_i  => rx_valid_i,
      start_i  => rx_start_i,
      last_i   => rx_last_i,
      len_i    => rx_len_i,
      err_i    => rx_err_i,
      crc_ok_i => rx_crc_ok_i
      );

  p_tx: process (clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if txlen_wr = '1' then
        txbuf_addr <= (others => '0');
      elsif txbuf_wr = '1' then
        txbuf_addr <= std_logic_vector(unsigned(txbuf_addr) + 1);
      end if;
    end if;
  end process;

inst_nic_tx: entity work.epx_nic_tx
  generic map (
    g_tx_log_sz => g_tx_log_sz
  )
  port map (
    clk_sys_i => clk_sys_i,
    rst_sys_n_i => rst_sys_n_i,
    clk_tx_i => clk_tx_i,
    rst_tx_n_i => rst_tx_n_i,
    reset_tx_i => tx_reset,
    buf_addr_i => txbuf_addr,
    buf_data_i => txbuf_data,
    buf_we_i => txbuf_wr,
    pkt_addr_i => (others => '0'),
    pkt_len_i => tx_pkt_len,
    pkt_ready_i => txlen_wr,
    pkt_done_o => tx_pkt_done,
    data_o => tx_data_o,
    ready_i => tx_ready_i,
    start_o => tx_start_o,
    last_o => tx_last_o,
    len_o => tx_len_o
  );

  tx_pkt_len(2 downto 0) <= txlen_nbytes;
  tx_pkt_len(g_tx_log_sz + 2 downto 3) <= txlen_len8(t_tx_addr_range);
end arch;
