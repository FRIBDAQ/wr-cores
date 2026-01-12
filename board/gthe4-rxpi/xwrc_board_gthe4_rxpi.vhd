-------------------------------------------------------------------------------
-- Title      : WRPC reference design for KR260 board
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- Company    : CERN (BE-CO-HT)
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Copyright (c) 2024 CERN
-------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
--
-- This source file is free software; you can redistribute it
-- and/or modify it under the terms of the GNU Lesser General
-- Public License as published by the Free Software Foundation;
-- either version 2.1 of the License, or (at your option) any
-- later version.
--
-- This source is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
-- PURPOSE.  See the GNU Lesser General Public License for more
-- details.
--
-- You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi4_pkg.all;
--use work.gencores_pkg.all;
use work.wishbone_pkg.all;
use work.endpoint_pkg.all;
use work.wr_fabric_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity xwrc_board_gthe4_rxpi is
  generic (
    --  Frequency of refclk0
    g_refclk0_freq : natural := 156_250_000;

    --  From wrc_core
    g_board_name  : string                         := "NA  ";
    g_dpram_initf : string                         := "";
    g_dpram_size  : integer                        := 192*1024/4;  --in 32-bit words
    g_hwbld_date  : std_logic_vector(31 downto 0)  := (others => 'X');
    g_dac_bits    : integer                        := 16
    );
  port (
    --  GTHe4 ref clock 0
    refclk0_n_i : in std_logic;
    refclk0_p_i : in std_logic;

    --  ODIV2 output of the IBUFDS_GTE4 fro refclk0 (not not divided, so at g_refclk0_freq)
    refclk0_int_o   : out std_logic;
    --  For other GTH
    refclk0_gt_o     : out std_logic;

    --  System clock (derived from refclk0_o) for WR core
    clk_62m5_i  : in std_logic;
    rst_n_i     : in std_logic;

    --  WR clock 62.5Mhz (from txoutclk)
    clk_ref_o   : out std_logic;

    --  GTHe4 rx/tx
    pad_txn_o : out std_logic;
    pad_txp_o : out std_logic;
    pad_rxn_i : in std_logic;
    pad_rxp_i : in std_logic;

    --  SFP leds
    led_act_o : out std_logic;
    led_link_o : out std_logic;

    --  SFP io
    sfp_tx_fault_i : in std_logic := '0';
    sfp_tx_disable_o : out std_logic;
    sfp_mod_abs_i : in std_logic := '0';
    sfp_sda_b : inout std_logic;
    sfp_scl_b : inout std_logic;

    --  WB bus to the WR PTP core [clk_62m5_i]
    wb_wrpc_host_i: in  t_wishbone_slave_in;
    wb_wrpc_host_o: out t_wishbone_slave_out;

    wb_wrpc_dev_i: in  t_wishbone_slave_in;
    wb_wrpc_dev_o: out t_wishbone_slave_out;
    irq_o : out std_logic;

    wb_wrpc_aux_i: in  t_wishbone_slave_in;
    wb_wrpc_aux_o: out t_wishbone_slave_out;

    --  Abscal signals
    abscal_txts_o       : out std_logic;
    abscal_rxts_o       : out std_logic;

    --  SPI flash
    spi_sclk_o : out std_logic;
    spi_ncs_o  : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic := '0';

    --  i2c eeprom
    eeprom_scl_b : inout std_logic;
    eeprom_sda_b : inout std_logic;

    --  UART
    uart_rxd_i : in  std_logic := '0';
    uart_txd_o : out std_logic;

    --  WR fabric.
    wrf_snk_i  : in  t_wrf_sink_in := c_dummy_snk_in;
    wrf_snk_o  : out t_wrf_sink_out;
    wrf_src_i  : in  t_wrf_source_in := c_dummy_src_in;
    wrf_src_o  : out t_wrf_source_out;

    dac_dpll_load_p1_o : out std_logic;
    dac_dpll_data_o    : out std_logic_vector(g_dac_bits-1 downto 0);

    tm_link_up_o         : out std_logic;
    -- Timecode output
    tm_time_valid_o      : out std_logic;
    tm_tai_o             : out std_logic_vector(39 downto 0);
    tm_cycles_o          : out std_logic_vector(27 downto 0);
    -- 1PPS output
    pps_valid_o          : out std_logic;
    pps_p_o              : out std_logic;
    pps_led_o            : out std_logic
  );
end;

architecture top of xwrc_board_gthe4_rxpi is
  COMPONENT gthe4_phy
  PORT (
    gtwiz_userclk_tx_active_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_active_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_done_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_done_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userdata_tx_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    gtwiz_userdata_rx_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dmonitorclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    drpaddr_in : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    drpclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    drpdi_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    drpen_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    drpwe_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthrxn_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthrxp_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtrxreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gttxreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll0clk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll0refclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll1clk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll1refclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rx8b10ben_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxbufreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxcommadeten_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxmcommaalignen_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxpcommaalignen_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxpcsreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxpd_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    rxpmareset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxprogdivreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxslide_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxuserrdy_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxusrclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxusrclk2_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    tx8b10ben_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txctrl0_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    txctrl1_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    txctrl2_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    txpcsreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpd_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    txpippmen_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpippmovrden_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpippmpd_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpippmsel_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpippmstepsize_in : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    txpllclksel_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    txpmareset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txprogdivreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txuserrdy_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txusrclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txusrclk2_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    dmonitorout_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dmonitoroutclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    drpdo_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    drprdy_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthtxn_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthtxp_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtpowergood_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxbyteisaligned_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxbyterealign_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxcdrlock_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxcommadet_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxctrl0_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    rxctrl1_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    rxctrl2_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rxctrl3_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rxoutclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxpmaresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    txoutclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpmaresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    txresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0) 
  );
END COMPONENT;

  --  QPLL config
  type t_qpll_config is record
    fbdiv : natural;
    fbdiv_g3 : natural;  --  Probably unused ?
    lpf : std_logic_vector(9 downto 0);
  end record;

  --  To handle a new frequency, use the gth wizard (and use CORE for common
  --  block), generate files and extract values from:
  --   gthe4_sdm_gthe4_common_wrapper.v
  function get_qpll_config (refclk0_freq : natural) return t_qpll_config is
  begin
    case refclk0_freq is
      when 156_250_000 =>
        return (fbdiv => 64,
                fbdiv_g3 => 160,
                lpf => "1000111111");
      when 250_000_000 =>
        return (fbdiv => 40,
                fbdiv_g3 => 64,
                lpf => "1101111111");
      when others =>
        assert false report "unhandled refclk0_freq" severity failure;
    end case;
  end get_qpll_config;

  constant qpll0_config : t_qpll_config := get_qpll_config(g_refclk0_freq);

  signal refclk0 : std_logic;

  signal qpll0_reset, qpll1_reset, qpll0_lock, qpll1_lock : std_logic;
  signal qpll0_outclk, qpll0_outrefclk : std_logic;
  signal qpll1_outclk, qpll1_outrefclk : std_logic;

  signal gth_rst : std_logic;
  signal gth_tx_rst, gth_rx_rst : std_logic;
  signal sfp_scl_out, sfp_sda_out : std_logic;

  signal phy16_out : t_phy_16bits_from_wrc;
  signal phy16_in : t_phy_16bits_to_wrc;

  signal rx_cdr_stable_out : std_logic;

  signal gth_rx_data_in : std_logic_vector(15 downto 0);
  signal gth_tx_data_out : std_logic_vector(15 downto 0);
  signal gth_rx_slide : std_logic;
  signal gth_rx_k_in, gth_rx_disp_err_in : std_logic_vector(15 downto 0);
  signal gth_rx_comma_in, gth_rx_dec_err_in : std_logic_vector(7 downto 0);
  signal gth_tx_k_out : std_logic_vector(7 downto 0) := (others => '0');
  signal gth_rx_byte_aligned_in : std_logic;
  signal gth_rx_comma_det_in : std_logic;
  signal gth_rx_pma_reset_done_in : std_logic;
  signal gth_tx_pma_reset_done_in : std_logic;

  signal gth_powergood : std_logic;
  signal gth_tx_prg_div_reset_done : std_logic;
  signal gth_tx_pd, gth_rx_pd : std_logic;

  signal gtrxreset, gttxreset : std_logic;
  signal rx_reset_done, tx_reset_done : std_logic;
  signal rxusrrdy, txusrrdy : std_logic;
  signal rxbufreset, rxpcsreset, rxpmareset : std_logic;
  signal txpcsreset, txpmareset : std_logic;
  signal phy_rst : std_logic;

  signal mpll_data_out : std_logic_vector(15 downto 0);
  signal mpll_load : std_logic;

  signal hpll_data, mpll_data : std_logic_vector(24 downto 0);
  signal hpll_toggle, mpll_toggle : std_logic;

  signal rxoutclk_out, rxoutclk : std_logic;
  signal txoutclk_out, txoutclk : std_logic;
  
  signal dmonitorout : std_logic_vector(15 downto 0);
  signal gth_dmon_clk, gth_dmon_clk_out  : std_logic;

  signal rxpi_data : std_logic_vector(31 downto 0);
  signal rxpi_valid : std_logic;

  signal gth_status_a, gth_status : std_logic_vector(15 downto 0) := (others => '0');

  signal bitslide_val : std_logic_vector(4 downto 0);
  signal rdy_in, rdy_out_62m5 : std_logic;

  signal eeprom_scl_out, eeprom_sda_out : std_logic;
begin
  inst_ibufds_gt : IBUFDS_GTE4
    generic map (
      REFCLK_EN_TX_PATH  => '0',
      REFCLK_HROW_CK_SEL => "00",
      REFCLK_ICNTL_RX    => "00")
    port map (
      O     => refclk0,
      ODIV2 => refclk0_int_o,
      CEB   => '0',
      I     => refclk0_p_i,
      IB    => refclk0_n_i);

  refclk0_gt_o <= refclk0;

  sfp_tx_disable_o <= phy16_out.sfp_tx_disable;
  phy16_in.sfp_tx_fault <= sfp_tx_fault_i;
 
  sfp_sda_b <= '0' when sfp_sda_out = '0' else 'Z';
  sfp_scl_b <= '0' when sfp_scl_out = '0' else 'Z';

  --  The common part of the gthe4.
  --  The values can be found in the top-level module generated when the common
  --  part is included.
  inst_gth_common: gthe4_common
    generic map (
      AEN_QPLL0_FBDIV       =>          '1',
      AEN_QPLL1_FBDIV       =>          '1',
      AEN_SDM0TOGGLE        =>          '0',
      AEN_SDM1TOGGLE        =>          '0',
      A_SDM0TOGGLE          =>          '0',
      A_SDM1DATA_HIGH       =>          "000000000",
      A_SDM1DATA_LOW        =>          "0000000000000000",
      A_SDM1TOGGLE          =>          '0',
      BIAS_CFG0             =>          "0000000000000000",
      BIAS_CFG1             =>          "0000000000000000",
      BIAS_CFG2             =>          "0000000100100100",
      BIAS_CFG3             =>          "0000000001000001",
      BIAS_CFG4             =>          "0000000000010000",
      BIAS_CFG_RSVD         =>          "0000000000000000",
      COMMON_CFG0           =>          "0000000000000000",
      COMMON_CFG1           =>          "0000000000000000",
      POR_CFG               =>          "0000000000000000",
      PPF0_CFG              =>          "0000011000000000",
      PPF1_CFG              =>          "0000011000000000",
      QPLL0CLKOUT_RATE      =>          "HALF",
      QPLL0_CFG0            =>          "0011001100011100",
      QPLL0_CFG1            =>          "1101000000111000",
      QPLL0_CFG1_G3         =>          "1101000000111000",
      QPLL0_CFG2            =>          "0000111111000000",
      QPLL0_CFG2_G3         =>          "0000111111000000",
      QPLL0_CFG3            =>          "0000000100100000",
      QPLL0_CFG4            =>          "0000000000000011",
      QPLL0_CP              =>          "0011111111",
      QPLL0_CP_G3           =>          "0000001111",
      QPLL0_FBDIV           =>          qpll0_config.fbdiv,
      QPLL0_FBDIV_G3        =>          qpll0_config.fbdiv_g3,
      QPLL0_INIT_CFG0       =>          "0000001010110010",
      QPLL0_INIT_CFG1       =>          "00000000",
      QPLL0_LOCK_CFG        =>          "0010010111101000",
      QPLL0_LOCK_CFG_G3     =>          "0010010111101000",
      QPLL0_LPF             =>          qpll0_config.lpf,
      QPLL0_LPF_G3          =>          "0111010101",
      QPLL0_PCI_EN          =>          '0',
      QPLL0_RATE_SW_USE_DRP =>          '1',
      QPLL0_REFCLK_DIV      =>          1,
      QPLL0_SDM_CFG0        =>          "0000000000000000",
      QPLL0_SDM_CFG1        =>          "0000000000000000",
      QPLL0_SDM_CFG2        =>          "0000000000000000",
      QPLL1CLKOUT_RATE      =>          "HALF",
      QPLL1_CFG0            =>          "0011001100011100",
      QPLL1_CFG1            =>          "1101000000111000",
      QPLL1_CFG1_G3         =>          "1101000000111000",
      QPLL1_CFG2            =>          "0000111111000011",
      QPLL1_CFG2_G3         =>          "0000111111000011",
      QPLL1_CFG3            =>          "0000000100100000",
      QPLL1_CFG4            =>          "0000000000000011",
      QPLL1_CP              =>          "0011111111",
      QPLL1_CP_G3           =>          "0001111111",
      QPLL1_FBDIV           =>          64,  -- 160
      QPLL1_FBDIV_G3        =>          80,  -- 80
      QPLL1_INIT_CFG0       =>          "0000001010110010",
      QPLL1_INIT_CFG1       =>          "00000000",
      QPLL1_LOCK_CFG        =>          "0010010111101000",
      QPLL1_LOCK_CFG_G3     =>          "0010010111101000",
      QPLL1_LPF             =>          "1000011111",
      QPLL1_LPF_G3          =>          "0111010100",
      QPLL1_PCI_EN          =>          '0',
      QPLL1_RATE_SW_USE_DRP =>          '1',
      QPLL1_REFCLK_DIV      =>          1,
      QPLL1_SDM_CFG0        =>          "0000000000000000",
      QPLL1_SDM_CFG1        =>          "0000000000000000",
      QPLL1_SDM_CFG2        =>          "0000000000000000",
      RSVD_ATTR0            =>          "0000000000000000",
      RSVD_ATTR1            =>          "0000000000000000",
      RSVD_ATTR2            =>          "0000000000000000",
      RSVD_ATTR3            =>          "0000000000000000",
      RXRECCLKOUT0_SEL      =>          "00",
      RXRECCLKOUT1_SEL      =>          "00",
      SARC_ENB              =>          '0',
      SARC_SEL              =>          '0',
      SDM0INITSEED0_0       =>          "0000000100010001",
      SDM0INITSEED0_1       =>          "000010001",
      SIM_DEVICE            =>          "ULTRASCALE_PLUS",
      SIM_MODE              =>          "FAST",
      SIM_RESET_SPEEDUP     =>          "TRUE"
    )
    port map (
      BGBYPASSB => '1',
      BGMONITORENB => '1',
      BGPDB => '1',
      BGRCALOVRD => "11111",
      BGRCALOVRDENB => '1',

      DRPADDR => (others => '0'),
      DRPCLK => clk_62m5_i,
      DRPDI => (others => '0'),
      DRPEN => '0',
      DRPWE => '0',
      DRPDO => open,
      DRPRDY => open,

      GTGREFCLK0 => '0',
      GTGREFCLK1 => '0',
      GTNORTHREFCLK00 => '0',
      GTNORTHREFCLK01 => '0',
      GTNORTHREFCLK10 => '0',
      GTNORTHREFCLK11 => '0',
      GTREFCLK00 => refclk0,
      GTREFCLK01 => refclk0,
      GTREFCLK10 => '0',
      GTREFCLK11 => '0',
      GTSOUTHREFCLK00 => '0',
      GTSOUTHREFCLK01 => '0',
      GTSOUTHREFCLK10 => '0',
      GTSOUTHREFCLK11 => '0',

      PCIERATEQPLL0 => "000",
      PCIERATEQPLL1 => "000",
      PMARSVD0 => x"00",
      PMARSVD1 => x"00",

      QPLL0CLKRSVD0 => '0',
      QPLL0CLKRSVD1 => '0',
      QPLL0FBDIV => x"40",
      QPLL0LOCKDETCLK => '0',
      QPLL0LOCKEN => '1',
      QPLL0PD => '0',
      QPLL0REFCLKSEL => "001", -- gtrefclk0
      QPLL0RESET => qpll0_reset,
      QPLL1CLKRSVD0 => '0',
      QPLL1CLKRSVD1 => '0',
      QPLL1FBDIV => x"40",
      QPLL1LOCKDETCLK => '0',
      QPLL1LOCKEN => '1',
      QPLL1PD => '0',
      QPLL1REFCLKSEL => "001",
      QPLL1RESET => qpll1_reset,
      QPLLRSVD1 => x"00",
      QPLLRSVD2 => "00000",
      QPLLRSVD3 => "00000",
      QPLLRSVD4 => x"00",
      RCALENB => '1',
      SDM0DATA => mpll_data,
      SDM0RESET => '0',
      SDM0TOGGLE => mpll_toggle,
      SDM0WIDTH => "00",  -- 00:24b
      SDM1DATA => hpll_data,
      SDM1RESET => '0',
      SDM1TOGGLE => hpll_toggle,
      SDM1WIDTH => "00",  -- 00:24b
      TCONGPI => b"00_0000_0000",
      TCONPOWERUP => '0',
      TCONRESET => "00",
      TCONRSVDIN1 => "00",
      PMARSVDOUT0 => open,
      PMARSVDOUT1 => open,
      QPLL0FBCLKLOST => open,
      QPLL0LOCK => qpll0_lock,
      QPLL0OUTCLK => qpll0_outclk,
      QPLL0OUTREFCLK => qpll0_outrefclk,
      QPLL0REFCLKLOST => open,
      QPLL1FBCLKLOST => open,
      QPLL1LOCK => qpll1_lock,
      QPLL1OUTCLK => qpll1_outclk,
      QPLL1OUTREFCLK => qpll1_outrefclk,
      QPLL1REFCLKLOST => open,
      QPLLDMONITOR0 => open,
      QPLLDMONITOR1 => open,
      REFCLKOUTMONITOR0 => open,
      REFCLKOUTMONITOR1 => open,
      RXRECCLK0SEL => open,
      RXRECCLK1SEL => open,
      SDM0FINALOUT => open,
      SDM0TESTDATA => open,
      SDM1FINALOUT => open,
      SDM1TESTDATA => open,
      TCONGPO => open,
      TCONRSVDOUT0 => open
  );


  inst_gth_channel: gthe4_phy
    port map (
      gthrxn_in(0)  => pad_rxn_i,
      gthrxp_in(0)  => pad_rxp_i,
      gthtxn_out(0) => pad_txn_o,
      gthtxp_out(0) => pad_txp_o,

      gtrxreset_in(0) => gtrxreset,
      gttxreset_in(0) => gttxreset,
      rxpd_in(0)      => gth_rx_pd,
      rxpd_in(1)      => gth_rx_pd,
      txpd_in(0)      => gth_tx_pd,
      txpd_in(1)      => gth_tx_pd,
      txuserrdy_in(0) => txusrrdy,
      rxuserrdy_in(0) => rxusrrdy,

      txprogdivreset_in(0) => '0',
      rxprogdivreset_in(0) => '0',
      rxbufreset_in(0) => rxbufreset,
      rxpcsreset_in(0) => rxpcsreset,
      rxpmareset_in(0) => rxpmareset,
      txpmareset_in(0) => txpmareset,
      txpcsreset_in(0) => txpcsreset,

      rxoutclk_out(0) => rxoutclk_out,
      rxusrclk_in(0) => rxoutclk,
      rxusrclk2_in(0) => rxoutclk,
      txoutclk_out(0) => txoutclk_out,
      txusrclk_in(0) => txoutclk,
      txusrclk2_in(0) => txoutclk,

      rxcdrlock_out(0) => rx_cdr_stable_out,
      rxresetdone_out(0) => rx_reset_done,
      txresetdone_out(0) => tx_reset_done,

      gtwiz_userclk_tx_active_in(0) => '1',
      gtwiz_userclk_rx_active_in(0) => '1',
      gtwiz_reset_tx_done_in(0) => tx_reset_done,
      gtwiz_reset_rx_done_in(0) => tx_reset_done,

--      gtwiz_reset_qpll0reset_out(0) => qpll0_reset,
--      gtwiz_reset_qpll0lock_in(0) => qpll0_lock,
--      gtwiz_reset_qpll1reset_out(0) => qpll1_reset,
--      gtwiz_reset_qpll1lock_in(0) => qpll1_lock,
--      gtwiz_reset_clk_freerun_in(0) => clk_62m5,
--      gtwiz_reset_all_in(0) => gtwiz_reset_all_out,
--      gtwiz_reset_tx_pll_and_datapath_in(0) => '0',
--      gtwiz_reset_tx_datapath_in(0) => '0',
--      gtwiz_reset_rx_pll_and_datapath_in(0) => '0',
--      gtwiz_reset_rx_datapath_in(0) => '0',
--      gtwiz_reset_rx_cdr_stable_out(0) => gtwiz_reset_rx_cdr_stable_out, --gth_status_a(2),
--      gtwiz_reset_tx_done_out(0) => gtwiz_reset_tx_done_in, --gth_status_a(3),
--      gtwiz_reset_rx_done_out(0) => gtwiz_reset_rx_done_in, -- gth_status_a(4),
      gtwiz_userdata_tx_in => gth_tx_data_out,
      gtwiz_userdata_rx_out => gth_rx_data_in,

      qpll0clk_in(0) => qpll0_outclk,
      qpll0refclk_in(0) => qpll0_outrefclk,
      qpll1clk_in(0) => qpll1_outclk,
      qpll1refclk_in(0) => qpll1_outrefclk,

      txpllclksel_in => "11", --  11: QPLL0
      rx8b10ben_in(0) => '1',
      rxcommadeten_in(0) => '1',
      rxmcommaalignen_in(0) => '0',
      rxpcommaalignen_in(0) => '0',
      rxslide_in(0) => gth_rx_slide,
      tx8b10ben_in(0) => '1',
      txctrl0_in => x"0000",
      txctrl1_in => x"0000",
      txctrl2_in => gth_tx_k_out,
      gtpowergood_out(0) => gth_powergood,
      rxbyteisaligned_out(0) => gth_rx_byte_aligned_in,
      rxbyterealign_out => open,
      rxcommadet_out(0) => gth_rx_comma_det_in,
      rxctrl0_out => gth_rx_k_in,
      rxctrl1_out => gth_rx_disp_err_in,
      rxctrl2_out => gth_rx_comma_in,
      rxctrl3_out => gth_rx_dec_err_in,
      rxpmaresetdone_out(0) => gth_rx_pma_reset_done_in,
      txpmaresetdone_out(0) => gth_tx_pma_reset_done_in,
--      txprgdivresetdone_out(0) => gth_tx_prg_div_reset_done,

      txpippmen_in(0) => '0',
      txpippmovrden_in(0) => '0',
      txpippmsel_in(0) => '1',
      txpippmpd_in(0) => '0',
      txpippmstepsize_in => b"1_0001", -- txpippmstepsize, -- b"1_0000",

      drpaddr_in => (others => '0'),
      drpclk_in(0) => clk_62m5_i,
      drpdi_in => (others => '0'),
      drpdo_out   => open,
      drpen_in(0) => '0',
      drpwe_in(0) => '0',
      drprdy_out => open,

      dmonitorout_out => dmonitorout,
      dmonitoroutclk_out(0) => gth_dmon_clk_out,
      dmonitorclk_in(0) => gth_dmon_clk
  );

  inst_mpll_sdm: entity work.gthe4_sdm
  port map (
    clk_62m5_i => clk_62m5_i,
    rst_n_i => rst_n_i,
    dac_data_i(13 downto 0) => mpll_data_out(15 downto 2),
    dac_data_i(23 downto 14) => (others => '0'),
    dac_load_i => mpll_load,
    sdm_data_o => mpll_data,
    sdm_toggle_o => mpll_toggle
  );

  inst_gthe4_rxpi: entity work.xwrc_gthe4_rxpi
    port map (
      clk_62m5_i => clk_62m5_i,
      rst_n_i => rst_n_i,
      wb_aux_i => wb_wrpc_aux_i,
      wb_aux_o => wb_wrpc_aux_o,
      tx_out_clk_i => txoutclk,
      rx_out_clk_i => rxoutclk,
      dmonitorout_i => dmonitorout,
      gth_dmon_clk_i => gth_dmon_clk,
      rxpi_valid_o => rxpi_valid,
      rxpi_data_o => rxpi_data,
      phy_rdy_i => rdy_in,
      phy_rdy_o => rdy_out_62m5,
      gth_rst_o => gth_rst,
      gth_tx_rst_o => gth_tx_rst,
      gth_rx_rst_o => gth_rx_rst,
      bitslide_val_i => bitslide_val,
      rxbufreset_o => rxbufreset,
      rxpcsreset_o => rxpcsreset,
      rxpmareset_o => rxpmareset,
      txpcsreset_o => txpcsreset,
      txpmareset_o => txpmareset,
      gth_status_i => gth_status
    );

  --  As PMA slide mode is used, there is no extra latency.
  phy16_in.rx_bitslide <= (others => '0'); -- bitslide_val;

  inst_sync_rdy: entity work.gc_sync
    port map (
      clk_i => rxoutclk,
      rst_n_a_i => '1',
      d_i => rdy_out_62m5,
      q_o => phy16_in.rdy
    );

  inst_bufg_gt_tx: BUFG_GT
    port map (
      I => txoutclk_out,
      O => txoutclk,
      CE => '1',
      CEMASK => '1',
      CLR => '0',
      CLRMASK => '1',
      DIV => "000"
    );

  phy16_in.ref_clk <= txoutclk;

  inst_bufg_gt_rx: BUFG_GT
    port map (
      I => rxoutclk_out,
      O => rxoutclk,
      CE => '1',
      CEMASK => '1',
      CLR => '0',
      CLRMASK => '1',
      DIV => "000"
    );

  phy16_in.rx_clk <= rxoutclk;
  
  inst_gth_dmon_bufg: BUFG_GT
    port map (
      I => gth_dmon_clk_out,
      O => gth_dmon_clk,
      DIV => "000",
      CE => '1',
      CEMASK => '1',
      CLR => '0',
      CLRMASK => '1'
    );

  clk_ref_o <= phy16_in.ref_clk;
  
  eeprom_scl_b <= '0' when eeprom_scl_out = '0' else 'Z';
  eeprom_sda_b <= '0' when eeprom_sda_out = '0' else 'Z';

  inst_wr_subsystem : entity work.xwr_subsystem
    generic map (
      g_board_name => g_board_name, --"KR26",
      --         g_dpram_initf => "../../../../bin/wrpc/wrc_phy16.bram",
--      g_dpram_initf => g_dpram_initf,
      g_dpram_size => g_dpram_size,
      g_pcs_16bit => true,
      g_records_for_phy => true,
      g_softpll_enable_debugger => true,
      g_direct_tag => true,
      g_hwbld_date => g_hwbld_date
      )
    port map (
      clk_sys_i => clk_62m5_i,
      rst_n_i => rst_n_i,
      clk_dmtd_i => '0', -- open,
      clk_ref_i => phy16_in.ref_clk,
      clk_dmtd_over_i => open,
      clk_aux_i => open,
      clk_ext_i => open,
      clk_ext_mul_i => open,
      clk_ext_mul_locked_i => open,
      clk_ext_stopped_i => open,
      clk_ext_rst_o => open,
      pps_ext_i => open,

      direct_tag0_valid_i => rxpi_valid,
      direct_tag0_i => rxpi_data(31 downto 8),
      dac_hpll_load_p1_o => open,
      dac_hpll_data_o => open,
      dac_dpll_load_p1_o => mpll_load,
      dac_dpll_data_o => mpll_data_out,

      phy_ref_clk_i => open,
      phy_tx_data_o => open,
      phy_tx_k_o => open,
      phy_tx_disparity_i => open,
      phy_tx_enc_err_i => open,
      phy_rx_data_i => open,
      phy_rx_rbclk_i => open,
      phy_rx_rbclk_sampled_i => open,
      phy_rx_k_i => open,
      phy_rx_enc_err_i => open,
      phy_rx_bitslide_i => open,
      phy_mdio_master_o => open,
      phy_mdio_master_i => open,
      phy_rst_o => open,
      phy_rdy_i => open,
      phy_loopen_o => open,
      phy_loopen_vec_o => open,
      phy_tx_prbs_sel_o => open,
      phy_sfp_tx_fault_i => open,
      phy_sfp_los_i => open,
      phy_sfp_tx_disable_o => open,
      phy8_i => open,
      phy8_o => open,
      phy16_o => phy16_out,
      phy16_i => phy16_in,

      scl_o => eeprom_scl_out,
      scl_i => eeprom_scl_b,
      sda_o => eeprom_sda_out,
      sda_i => eeprom_sda_b,
      sfp_det_i => sfp_mod_abs_i,
      sfp_scl_o => sfp_scl_out,
      sfp_scl_i => sfp_scl_b,
      sfp_sda_o => sfp_sda_out,
      sfp_sda_i => sfp_sda_b,
      spi_sclk_o => spi_sclk_o,
      spi_ncs_o => spi_ncs_o,
      spi_mosi_o => spi_mosi_o,
      spi_miso_i => spi_miso_i,
      owr_pwren_o => open,
      owr_en_o => open,
      owr_i => open,
      uart_rxd_i => uart_rxd_i,
      uart_txd_o => uart_txd_o,
      wb_host_i => wb_wrpc_host_i,
      wb_host_o => wb_wrpc_host_o,
      wb_cpu_i => wb_wrpc_dev_i,
      wb_cpu_o => wb_wrpc_dev_o,
      wb_aux_master_i => open,
      wb_aux_master_o => open,
      wb_cpu_csr_i => cc_dummy_master_in,
      wb_cpu_csr_o => open,
      softpll_irq_o => irq_o,
      wrf_src_o => wrf_src_o,
      wrf_src_i => wrf_src_i,
      wrf_snk_o => wrf_snk_o,
      wrf_snk_i => wrf_snk_i,
      timestamps_o => open,
      timestamps_ack_i => open,
      abscal_txts_o => abscal_txts_o,
      abscal_rxts_o => abscal_rxts_o,
      fc_tx_pause_req_i => open,
      fc_tx_pause_delay_i => open,
      fc_tx_pause_ready_o => open,
      tm_link_up_o => tm_link_up_o,
      tm_time_valid_o => tm_time_valid_o,
      tm_tai_o => tm_tai_o,
      tm_cycles_o => tm_cycles_o,
      tm_clk_aux_lock_en_i => open,
      tm_clk_aux_locked_o => open,
      tm_dac_value_o => open,
      tm_dac_wr_o => open,
      pps_csync_o => open,
      pps_valid_o => open,
      pps_p_o => open,
      pps_led_o => open,
      rst_aux_n_o => open,
      led_act_o => led_act_o,
      led_link_o => led_link_o,
      link_ok_o => open,
      aux_diag_i => open,
      aux_diag_o => open,
      aux_timing_serdes_locked_i => '1',
      utc_o => open,
      aux_timing_o => open,
      btn1_i => open,
      btn2_i => open
      );
    
  inst_gthe4_adapter: entity work.wr_gthe4_adapter
    port map (
      tx_locked_o => open,
      tx_data_i => phy16_out.tx_data,
      tx_k_i => phy16_out.tx_k,
      tx_disparity_o => phy16_in.tx_disparity,
      tx_enc_err_o => phy16_in.tx_enc_err,
      rx_data_o => phy16_in.rx_data,
      rx_k_o => phy16_in.rx_k,
      rx_enc_err_o => phy16_in.rx_enc_err,
      rx_bitslide_o => bitslide_val,
      rst_i => phy_rst,
      rdy_o => rdy_in,
      gtwiz_userclk_tx_reset_o => open,
      gtwiz_userclk_tx_active_i => '1',
      gtwiz_userclk_rx_reset_o => open,
      gtwiz_userclk_rx_active_i => '1',
      gtwiz_buffbypass_tx_reset_o => open,
      gtwiz_buffbypass_tx_done_i => '1',
      gtwiz_buffbypass_rx_reset_o => open,
      gtwiz_buffbypass_rx_start_user_o => open,
      gtwiz_buffbypass_rx_done_i => '1',
      gtwiz_reset_all_o => open,  --  same as phy_rst
      gtwiz_reset_tx_done_i => tx_reset_done,
      gtwiz_reset_rx_done_i => rx_reset_done,
      gth_rx_data_i => gth_rx_data_in,
      gth_tx_data_o => gth_tx_data_out,
      gth_rx_slide_o => gth_rx_slide,
      gth_rx_k_i => gth_rx_k_in(1 downto 0),
      gth_tx_k_o => gth_tx_k_out(1 downto 0),
      gth_rx_dec_err_i => gth_rx_dec_err_in(1 downto 0),
      gth_rx_disp_err_i => gth_rx_disp_err_in(1 downto 0),
      gth_rx_byte_aligned_i => gth_rx_byte_aligned_in,
      gth_rx_comma_det_i => gth_rx_comma_det_in,
      gth_rx_pma_reset_done_i => gth_rx_pma_reset_done_in,
      gth_tx_pma_reset_done_i => gth_tx_pma_reset_done_in,
      gth_rx_clk_i => phy16_in.rx_clk,
      gth_tx_clk_i => phy16_in.ref_clk
      );

  b_rst: block
    signal powergood_dly : std_logic;
    constant pg_dly_len : natural := 250_000 / 16; --  250us / clk_cyc
    signal pg_dly_cnt : natural range 0 to pg_dly_len := 0;
    constant pd_dly_len : natural := 10;
    signal pd_dly_cnt : natural range 0 to pd_dly_len;
    signal pd_dly : std_logic;
  begin
    process (clk_62m5_i, gth_powergood)
    begin
      if gth_powergood = '0' then
        powergood_dly <= '0';
        pg_dly_cnt <= 0;
      elsif rising_edge(clk_62m5_i) then
        if pg_dly_cnt = pg_dly_len then
          powergood_dly <= '1';
        else
          pg_dly_cnt <= pg_dly_cnt + 1;
        end if;
      end if;
    end process;

    process (clk_62m5_i)
    begin
      if rising_edge(clk_62m5_i) then
        if phy_rst = '1' then
          pd_dly <= '1';
          pd_dly_cnt <= 0;
        elsif pd_dly_cnt < pd_dly_len then
          pd_dly_cnt <= pd_dly_cnt + 1;
        else
          pd_dly <= '0';
        end if;
      end if;
    end process;

    phy_rst <= gth_rst or phy16_out.rst;

    qpll1_reset <= not powergood_dly;
    qpll0_reset <= not powergood_dly;

    rxusrrdy <= powergood_dly;
    txusrrdy <= powergood_dly;

    gth_rx_pd <= phy_rst;
    gth_tx_pd <= phy_rst;

    gttxreset <= not powergood_dly or not qpll0_lock or pd_dly or gth_rx_rst;
    gtrxreset <= not powergood_dly or not qpll0_lock or pd_dly or gth_tx_rst;
  end block;

  gen_ila: if false generate
    component ila_0
      port (
        clk    : in STD_LOGIC;
        probe0 : in STD_LOGIC_VECTOR(63 downto 0)
      );
    end component  ;

  begin
    gth_status_a(0) <= gth_powergood;
    gth_status_a(1) <= rx_cdr_stable_out;
    gth_status_a(2) <= tx_reset_done;
    gth_status_a(3) <= rx_reset_done;

    gth_status_a(4) <= qpll0_reset;
    gth_status_a(5) <= qpll0_lock;
    gth_status_a(6) <= qpll1_reset;
    gth_status_a(7) <= qpll1_lock;

    gth_status_a(8) <= gth_rx_pma_reset_done_in;
    gth_status_a(9) <= gth_rx_pma_reset_done_in;
    gth_status_a(10) <= gth_rx_byte_aligned_in;
    gth_status_a(11) <= gth_rx_comma_det_in;

    gth_status_a(12) <= gth_tx_prg_div_reset_done;
    gth_status_a(13) <= rdy_in;
    gth_status_a(14) <= gth_rx_slide;
    gth_status_a(15) <= phy_rst;

    gen_sync: for i in gth_status'range generate
      inst_sync: entity work.gc_sync
        port map (
          clk_i => clk_62m5_i,
          rst_n_a_i => rst_n_i,
          d_i => gth_status_a(i),
          q_o => gth_status(i)
          );
    end generate;

    inst_ila: ila_0
      port map (
        clk => phy16_in.rx_clk,
        probe0 (15 downto 0) => phy16_in.rx_data,
        probe0(16) => gth_rx_byte_aligned_in,
        probe0(17) => gth_rx_comma_det_in,
        probe0(18) => gth_rx_slide,
        probe0(19) => '0',
        probe0(20) => '0',
        probe0(21) => '0',
        probe0(22) => '0',
        probe0(23) => '0',
        probe0(28 downto 24) => phy16_in.rx_bitslide,
        probe0(30 downto 29) => gth_rx_k_in(1 downto 0),
        probe0(32 downto 31) => gth_rx_disp_err_in(1 downto 0),
        probe0(34 downto 33) => gth_rx_comma_in(1 downto 0),
        probe0(36 downto 35) => gth_rx_dec_err_in(1 downto 0),
        probe0(63 downto 37) => (others => '0')
        --probe0 (31 downto 16) => gth_status(15 downto 0)
        );
  end generate;
end top;
