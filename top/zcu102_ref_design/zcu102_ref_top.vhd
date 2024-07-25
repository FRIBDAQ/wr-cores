-------------------------------------------------------------------------------
-- Title      : WRPC reference design for ZCU102 board
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : zcu102_ref_top.vhd
-- Author(s)  : David Epping <david.epping@missinglinkelectronics.com> (based
--              on work by Greg Daniluk <grzegorz.daniluk@cern.ch>)
-- Company    : Missing Link Electronics
--              CERN (BE-CO-HT)
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top-level file for the WRPC reference design on the ZCU102
-- board.
-- An optional XM105 can be added on FMC HPC0 for SMA clock and PPS output.
--
-- This is a reference top HDL that instanciates the WR PTP Core together with
-- its peripherals to be run on a ZCU102 board.
--
-- There are two main usecases for this HDL file:
-- * let new users easily synthesize a WR PTP Core bitstream that can be run on
--   reference hardware
-- * provide a reference top HDL file showing how the WRPC can be instantiated
--   in HDL projects.
--
-- ZCU102: https://www.xilinx.com/products/boards-and-kits/ek-u1-zcu102-g.html
--
-------------------------------------------------------------------------------
-- Copyright (c) 2023 Missing Link Electronics
--
-- CERN Open Hardware Licence Version 2 - Weakly Reciprocal
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--library work;
--use work.gencores_pkg.all;
--use work.wishbone_pkg.all;
--use work.gn4124_core_pkg.all;
--use work.wr_board_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity zcu102_ref_top is
  generic (
    -- Simulation-mode enable parameter. Set by default (synthesis) to 0, and
    -- changed to non-zero in the instantiation of the top level DUT in the testbench.
    -- Its purpose is to reduce some internal counters/timeouts to speed up simulations.
    g_SIMULATION: integer := 0);
  port (
    ---------------------------------------------------------------------------
    -- Clocks/resets
    ---------------------------------------------------------------------------
    ps_por_i               : in std_logic;
    wr_clk_helper_125m_p_i : in  std_logic;
    wr_clk_helper_125m_n_i : in  std_logic;
    wr_clk_main_125m_p_i   : in  std_logic;
    wr_clk_main_125m_n_i   : in  std_logic;
    wr_clk_sfp_125m_p_i    : in  std_logic;
    wr_clk_sfp_125m_n_i    : in  std_logic;

    clk_sys_62m5_o : out std_logic_vector(0 downto 0);
    clk_ref_125m_o : out std_logic;
    clk_xm105_sma_o : out std_logic;

    ---------------------------------------------------------------------------
    -- Dummy GTH channel required for QPLL SDM
    ---------------------------------------------------------------------------
    dummy_gthtxp_o        : out std_logic_vector(3 downto 0);
    dummy_gthtxn_o        : out std_logic_vector(3 downto 0);
    dummy_gthrxp_i        : in  std_logic_vector(3 downto 0);
    dummy_gthrxn_i        : in  std_logic_vector(3 downto 0);

    ---------------------------------------------------------------------------
    -- SFP I/Os for transceiver
    ---------------------------------------------------------------------------
    sfp_txp_o         : out std_logic;
    sfp_txn_o         : out std_logic;
    sfp_rxp_i         : in  std_logic;
    sfp_rxn_i         : in  std_logic;
    sfp_sda_b         : inout std_logic;
    sfp_scl_b         : inout std_logic;
    sfp_tx_disable_o  : out std_logic;
    sfp_los_i         : in  std_logic;

    ---------------------------------------------------------------------------
    -- EEPROM I2C interface for storing configuration and accessing unique ID
    ---------------------------------------------------------------------------
    eeprom_sda_b  : inout std_logic;
    eeprom_scl_b  : inout std_logic;
    ---------------------------------------------------------------------------
    -- UART
    ---------------------------------------------------------------------------
    uart_rxd_i    : in  std_logic;
    uart_txd_o    : out std_logic;

    ---------------------------------------------------------------------------
    -- DIP Switch
    ---------------------------------------------------------------------------
    gpio_dip_sw_i : in std_logic_vector(0 downto 0);

    ---------------------------------------------------------------------------
    -- LEDs
    ---------------------------------------------------------------------------
    user_led_o    : out std_logic_vector(3 downto 0);
    pps_p_o    : out std_logic_vector(1 downto 0)
  );
end entity zcu102_ref_top;

architecture top of zcu102_ref_top is

  signal rst_n : std_logic;

  signal clkfbout_clk_wiz_0 : std_logic;
  signal clkfbout_buf_clk_wiz_0 : std_logic;
  signal clk_sys_62m5 : std_logic;
  signal clk_10m : std_logic;
  signal clk_xm105_sma : std_logic;
  signal pps_p : std_logic;

  signal sfp_scl_out, sfp_scl_in : std_logic;
  signal sfp_sda_out, sfp_sda_in : std_logic;
  signal eeprom_scl_out, eeprom_scl_in : std_logic;
  signal eeprom_sda_out, eeprom_sda_in : std_logic;

begin

  -- do not use PS_POR for now
  rst_n <= '1'; --not ps_por_i;

  cmp_xwrc_board_zcu102 : entity work.xwrc_board_zcu102
    generic map (
      g_simulation   => g_SIMULATION,
      g_dpram_initf  => "../../bin/wrpc/wrc_amd_devboard.bram")
    port map (
      areset_n_i             => rst_n,
      wr_clk_helper_125m_p_i => wr_clk_helper_125m_p_i,
      wr_clk_helper_125m_n_i => wr_clk_helper_125m_n_i, 
      wr_clk_main_125m_p_i   => wr_clk_main_125m_p_i, 
      wr_clk_main_125m_n_i   => wr_clk_main_125m_n_i, 
      wr_clk_sfp_125m_p_i    => wr_clk_sfp_125m_p_i, 
      wr_clk_sfp_125m_n_i    => wr_clk_sfp_125m_n_i, 
      clk_sys_62m5_o         => clk_sys_62m5,
      clk_ref_125m_o         => clk_ref_125m_o,
  
      dummy_gthtxp_o        => dummy_gthtxp_o,
      dummy_gthtxn_o        => dummy_gthtxn_o,
      dummy_gthrxp_i        => dummy_gthrxp_i,
      dummy_gthrxn_i        => dummy_gthrxn_i,

      sfp_txp_o       => sfp_txp_o,
      sfp_txn_o       => sfp_txn_o,
      sfp_rxp_i       => sfp_rxp_i,
      sfp_rxn_i       => sfp_rxn_i,
      sfp_det_i       => '0', --  Force presence
      sfp_sda_i       => sfp_sda_in,
      sfp_sda_o       => sfp_sda_out,
      sfp_scl_i       => sfp_scl_in,
      sfp_scl_o       => sfp_scl_out,
      sfp_tx_disable_o => sfp_tx_disable_o,
      sfp_los_i        => sfp_los_i,
  
      eeprom_sda_i => eeprom_sda_in, 
      eeprom_sda_o => eeprom_sda_out, 
      eeprom_scl_i => eeprom_scl_in, 
      eeprom_scl_o => eeprom_scl_out, 
      uart_rxd_i   => uart_rxd_i, 
      uart_txd_o   => uart_txd_o, 
  
      led_act_o  => user_led_o(1),
      led_link_o => user_led_o(0),
      pps_valid_o => user_led_o(2),
      pps_led_o => user_led_o(3),
      pps_p_o    => pps_p);

  mmcme4_adv_inst : MMCME4_ADV
    generic map (
      BANDWIDTH            => "OPTIMIZED",
      CLKOUT4_CASCADE      => "FALSE",
      COMPENSATION         => "AUTO",
      STARTUP_WAIT         => "FALSE",
      DIVCLK_DIVIDE        => 1,
      CLKFBOUT_MULT_F      => 16.000,
      CLKFBOUT_PHASE       => 0.000,
      CLKFBOUT_USE_FINE_PS => "FALSE",
      CLKOUT0_DIVIDE_F     => 100.000,
      CLKOUT0_PHASE        => 0.000,
      CLKOUT0_DUTY_CYCLE   => 0.500,
      CLKOUT0_USE_FINE_PS  => "FALSE",
      CLKIN1_PERIOD        => 16.000)
    port map (
      CLKFBOUT             => clkfbout_clk_wiz_0,
      CLKFBOUTB            => open,
      CLKOUT0              => clk_10m,
      CLKOUT0B             => open,
      CLKOUT1              => open,
      CLKOUT1B             => open,
      CLKOUT2              => open,
      CLKOUT2B             => open,
      CLKOUT3              => open,
      CLKOUT3B             => open,
      CLKOUT4              => open,
      CLKOUT5              => open,
      CLKOUT6              => open,
      CLKFBIN              => clkfbout_buf_clk_wiz_0,
      CLKIN1               => clk_sys_62m5,
      CLKIN2               => '0',
      CLKINSEL             => '1',
      DADDR                => "0000000",
      DCLK                 => '0',
      DEN                  => '0',
      DI                   => x"0000",
      DO                   => open,
      DRDY                 => open,
      DWE                  => '0',
      CDDCDONE             => open,
      CDDCREQ              => '0',
      PSCLK                => '0',
      PSEN                 => '0',
      PSINCDEC             => '0',
      PSDONE               => open,
      LOCKED               => open, --locked_int,
      CLKINSTOPPED         => open,
      CLKFBSTOPPED         => open,
      PWRDWN               => '0',
      RST                  => '0');

  clkf_buf : BUFG
    port map (
      O => clkfbout_buf_clk_wiz_0,
      I => clkfbout_clk_wiz_0);

  clk_mux : BUFGMUX
    port map (
      O => clk_xm105_sma,
      I0 => clk_10m,
      I1 => clk_sys_62m5,
      S => gpio_dip_sw_i(0));

 oddr_clk_xm105_sma : ODDRE1
    port map  (
      Q => clk_xm105_sma_o,
      C => clk_xm105_sma,
      D1 => '1',
      D2 => '0',
      SR => '0');

  clk_sys_62m5_o <= (clk_sys_62m5_o'range => clk_sys_62m5);
  pps_p_o <= (pps_p_o'range => pps_p);

  sfp_scl_b <= '0' when sfp_scl_out = '0' else 'Z';
  sfp_sda_b <= '0' when sfp_sda_out = '0' else 'Z';
  sfp_scl_in <= sfp_scl_b;
  sfp_sda_in <= sfp_sda_b;

  eeprom_scl_b <= '0' when eeprom_scl_out = '0' else 'Z';
  eeprom_sda_b <= '0' when eeprom_sda_out = '0' else 'Z';
  eeprom_scl_in <= eeprom_scl_b;
  eeprom_sda_in <= eeprom_sda_b;

end top;
