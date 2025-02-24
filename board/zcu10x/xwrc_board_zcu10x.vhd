-------------------------------------------------------------------------------
-- Title      : WRPC Wrapper for ZCU102 and ZCU106 board
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : xwrc_board_zcu10x.vhd
-- Author(s)  : David Epping <david.epping@missinglinkelectronics.com> (based
--              on work by Greg Daniluk <grzegorz.daniluk@cern.ch>)
-- Company    : Missing Link Electronics
--              CERN (BE-CO-HT)
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top-level wrapper for WR PTP core including all the modules
-- needed to operate the core on the Xilinx ZCU102 and ZCU106 board.
-- ZCU102: https://www.xilinx.com/products/boards-and-kits/ek-u1-zcu102-g.html
-- ZCU106: https://www.xilinx.com/products/boards-and-kits/zcu106.html
-------------------------------------------------------------------------------
-- Copyright (c) 2023 Missing Link Electronics
--
-- CERN Open Hardware Licence Version 2 - Weakly Reciprocal
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.gencores_pkg.all;
use work.wrcore_pkg.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;
use work.streamers_pkg.all;
use work.wr_xilinx_pkg.all;
use work.wr_board_pkg.all;
use work.si570_wbgen2_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity xwrc_board_zcu10x is
  generic(
    -- set to 1 to speed up some initialization processes during simulation
    g_simulation                : integer              := 0;
    -- Select whether to include external ref clock input
    g_with_external_clock_input : boolean              := TRUE;
    -- Number of aux clocks syntonized by WRPC to WR timebase
    g_aux_clks                  : integer              := 0;
    -- memory initialisation file for embedded CPU
    g_dpram_initf               : string               := "default_xilinx";
    -- identification (id and ver) of the layout of words in the generic diag interface
    g_diag_id                   : integer              := 0;
    g_diag_ver                  : integer              := 0;
    -- size the generic diag interface
    g_diag_ro_size              : integer              := 0;
    g_diag_rw_size              : integer              := 0;
    g_dac_bits                  : integer              := 16;
    -- Both ZCU102 and ZCU106 are currently supported
    g_board_name                : string               := "X10x";
    g_num_fmc_enable            : integer              := 2
    );
  port (
    ---------------------------------------------------------------------------
    -- Clocks/resets
    ---------------------------------------------------------------------------
    -- Reset input (active low, can be async)
    areset_n_i          : in  std_logic;
    -- Optional reset input active low with rising edge detection. Does not
    -- reset PLLs.
    areset_edge_n_i        : in  std_logic := '1';
    -- Clock inputs from the board
    wr_clk_helper_125m_p_i : in  std_logic;
    wr_clk_helper_125m_n_i : in  std_logic;
    wr_clk_main_125m_p_i   : in  std_logic;
    wr_clk_main_125m_n_i   : in  std_logic;
    wr_clk_sfp_125m_p_i    : in  std_logic;
    wr_clk_sfp_125m_n_i    : in  std_logic;
    -- Aux clocks, which can be disciplined by the WR Core
    clk_aux_i              : in  std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');
    -- 10MHz ext ref clock input (g_with_external_clock_input = TRUE)
    clk_10m_ext_i       : in  std_logic                               := '0';
    -- External PPS input (g_with_external_clock_input = TRUE)
    pps_ext_i           : in  std_logic                               := '0';
    -- 62.5MHz sys clock output
    clk_sys_62m5_o      : out std_logic;
    -- 125MHz ref clock output
    clk_ref_125m_o      : out std_logic;
    -- active low reset outputs, synchronous to 62m5 and 125m clocks
    rst_sys_62m5_n_o    : out std_logic;
    rst_ref_125m_n_o    : out std_logic;

    ---------------------------------------------------------------------------
    -- Dummy GTH channel required for QPLL SDM
    ---------------------------------------------------------------------------
    dummy_gthtxp_o        : out std_logic_vector(1 downto 0);
    dummy_gthtxn_o        : out std_logic_vector(1 downto 0);
    dummy_gthrxp_i        : in  std_logic_vector(1 downto 0);
    dummy_gthrxn_i        : in  std_logic_vector(1 downto 0);

    ---------------------------------------------------------------------------
    -- Shared SPI interface to DACs
    ---------------------------------------------------------------------------
    plldac_sclk_o   : out std_logic;
    plldac_din_o    : out std_logic;
    pll25dac_cs_n_o : out std_logic;
    pll20dac_cs_n_o : out std_logic;

    ---------------------------------------------------------------------------
    -- SFP I/O for transceiver and SFP management info
    ---------------------------------------------------------------------------
    sfp_txp_o         : out std_logic;
    sfp_txn_o         : out std_logic;
    sfp_rxp_i         : in  std_logic;
    sfp_rxn_i         : in  std_logic;
    sfp_det_i         : in  std_logic := '1';
    sfp_sda_i         : in  std_logic;
    sfp_sda_o         : out std_logic;
    sfp_scl_i         : in  std_logic;
    sfp_scl_o         : out std_logic;
    sfp_rate_select_o : out std_logic;
    sfp_tx_fault_i    : in  std_logic := '0';
    sfp_tx_disable_o  : out std_logic;
    sfp_los_i         : in  std_logic := '0';

    ---------------------------------------------------------------------------
    -- I2C EEPROM
    ---------------------------------------------------------------------------
    eeprom_sda_i : in  std_logic;
    eeprom_sda_o : out std_logic;
    eeprom_scl_i : in  std_logic;
    eeprom_scl_o : out std_logic;

    -----------------------------------------
    -- Si570 I2C interface
    -----------------------------------------
    si570_scl_oen_o  : out std_logic;
    si570_scl_i      : in  std_logic := '1';
    si570_sda_oen_o  : out std_logic;
    si570_sda_i      : in  std_logic := '1';

    -----------------------------------------
    -- FMC SW enable interface
    -----------------------------------------
    fmc_enable_o : out std_logic_vector(g_num_fmc_enable-1 downto 0);

    ---------------------------------------------------------------------------
    -- UART
    ---------------------------------------------------------------------------
    uart0_rxd_i : in  std_logic;
    uart0_txd_o : out std_logic;
    uart1_rxd_i : in  std_logic := '0';
    uart1_txd_o : out std_logic;

    ---------------------------------------------------------------------------
    -- External WB interface
    ---------------------------------------------------------------------------
    wb_slave_o : out t_wishbone_slave_out;
    wb_slave_i : in  t_wishbone_slave_in := cc_dummy_slave_in;

    ---------------------------------------------------------------------------
    -- WR fabric interface (when g_fabric_iface = "plainfbrc")
    ---------------------------------------------------------------------------
    wrf_src_o : out t_wrf_source_out;
    wrf_src_i : in  t_wrf_source_in := c_dummy_src_in;
    wrf_snk_o : out t_wrf_sink_out;
    wrf_snk_i : in  t_wrf_sink_in   := c_dummy_snk_in;

    ---------------------------------------------------------------------------
    -- Generic diagnostics interface (access from WRPC via SNMP or uart console
    ---------------------------------------------------------------------------
    aux_diag_i : in  t_generic_word_array(g_diag_ro_size-1 downto 0) := (others => (others => '0'));
    aux_diag_o : out t_generic_word_array(g_diag_rw_size-1 downto 0);

    ---------------------------------------------------------------------------
    -- Aux clocks control
    ---------------------------------------------------------------------------
    tm_dac_value_o       : out std_logic_vector(31 downto 0);
    tm_dac_wr_o          : out std_logic_vector(g_aux_clks-1 downto 0);
    tm_clk_aux_lock_en_i : in  std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');
    tm_clk_aux_locked_o  : out std_logic_vector(g_aux_clks-1 downto 0);

    ---------------------------------------------------------------------------
    -- External Tx Timestamping I/F
    ---------------------------------------------------------------------------
    timestamps_o     : out t_txtsu_timestamp;
    timestamps_ack_i : in  std_logic := '1';

    -----------------------------------------
    -- Timestamp helper signals, used for Absolute Calibration
    -----------------------------------------
    abscal_txts_o    : out std_logic;
    abscal_rxts_o    : out std_logic;

    ---------------------------------------------------------------------------
    -- Timecode I/F
    ---------------------------------------------------------------------------
    tm_link_up_o     : out std_logic;
    tm_time_valid_o  : out std_logic;
    tm_tai_o         : out std_logic_vector(39 downto 0);
    tm_cycles_o      : out std_logic_vector(27 downto 0);

    ---------------------------------------------------------------------------
    -- Buttons, LEDs and PPS output
    ---------------------------------------------------------------------------
    led_act_o  : out std_logic;
    led_link_o : out std_logic;
    -- 1PPS output
    pps_p_o     : out std_logic;
    pps_valid_o : out std_logic;
    pps_led_o   : out std_logic;
    -- Link ok indication
    link_ok_o   : out std_logic
    );

end entity xwrc_board_zcu10x;


architecture struct of xwrc_board_zcu10x is

  -- PLLs, clocks
  signal wr_clk_main_125m_buf : std_logic;
  signal clk_125m_pllref_buf : std_logic;
  signal clk_125m_dmtdref_buf   : std_logic;
  signal clk_pll_62m5        : std_logic;
  signal clk_pll_125m        : std_logic;
  signal clk_pll_dmtd        : std_logic;
  signal pll_locked          : std_logic;
  signal clk_10m_ext         : std_logic;


  -- Reset logic
  signal areset_edge_ppulse : std_logic;
  signal rst_62m5_n         : std_logic;
  signal rstlogic_arst      : std_logic;
  signal rstlogic_clk_in    : std_logic_vector(1 downto 0);
  signal rstlogic_rst_out   : std_logic_vector(1 downto 0);

  -- PLL DAC ARB
  signal dac_hpll_load_p1 : std_logic;
  signal dac_hpll_data    : std_logic_vector(g_dac_bits-1 downto 0);
  signal dac_dpll_load_p1 : std_logic;
  signal dac_dpll_data    : std_logic_vector(g_dac_bits-1 downto 0);

  -- PHY
  signal phy16_to_wrc   : t_phy_16bits_to_wrc;
  signal phy16_from_wrc : t_phy_16bits_from_wrc;

  signal sfp_tx_disable_n : std_logic;

  -- External reference
  signal ext_ref_mul         : std_logic;
  signal ext_ref_mul_locked  : std_logic;
  signal ext_ref_mul_stopped : std_logic;
  signal ext_ref_rst         : std_logic;

  -- Si570
  signal si570_wb_in  : t_wishbone_slave_in;
  signal si570_wb_out : t_wishbone_slave_out;

  -- GPIO for FMC enable
  signal enfmc_wb_in  : t_wishbone_slave_in;
  signal enfmc_wb_out : t_wishbone_slave_out;

  -- GPS Uart
  signal gps_uart_wb_in  : t_wishbone_slave_in;
  signal gps_uart_wb_out : t_wishbone_slave_out;

  constant c_xwb_si5xx_sdb : t_sdb_device := (
    abi_class     => x"0000",              -- undocumented device
    abi_ver_major => x"01",
    abi_ver_minor => x"01",
    wbd_endian    => c_sdb_endian_big,
    wbd_width     => x"7",
    sdb_component => (
    addr_first  => x"0000000000000000",
    addr_last   => x"00000000000000ff",
    product     => (
    vendor_id => x"000000000000CE42",  -- CERN TODO
    device_id => x"deadbee0",          -- TODO
    version   => x"00000001",
    date      => x"20240604",
    name      => "Si5xx              ")));

  -- Tertiary crossbar for board peripherals
  signal aux_master_out : t_wishbone_master_out;
  signal aux_master_in : t_wishbone_master_in := cc_dummy_master_in;

  signal tertbar_master_i : t_wishbone_master_in_array(2 downto 0);
  signal tertbar_master_o : t_wishbone_master_out_array(2 downto 0);

  constant c_tertbar_layout : t_sdb_record_array(2 downto 0) :=
    (0  => f_sdb_embed_device(c_xwb_gpio_port_sdb, x"00000000"),
     1  => f_sdb_embed_device(c_wrc_periph1_sdb,   x"00000100"),
     2  => f_sdb_embed_device(c_xwb_si5xx_sdb,     x"00000200")
     --                     tertbar sdb            x"00000300"
   );

  constant c_tertbar_sdb_address : t_wishbone_address := x"00000300";
  constant c_tertbar_bridge_sdb  : t_sdb_bridge       :=
    f_xwb_bridge_layout_sdb(true, c_tertbar_layout, c_tertbar_sdb_address);
begin  -- architecture struct

  -----------------------------------------------------------------------------
  -- Platform-dependent part (PHY, PLLs, buffers, etc)
  -----------------------------------------------------------------------------

  cmp_ibufgds_pllmain : IBUFDS
    generic map (
      DQS_BIAS     => "FALSE")
    port map (
      O  => wr_clk_main_125m_buf,
      I  => wr_clk_main_125m_p_i,
      IB => wr_clk_main_125m_n_i);

  -- explicit BUFG is required because wr_clk_main_125m_p_i is in a HDIO bank,
  -- preventing Vivado from automatically adding it.
  cmp_bufg_pllmain: BUFG
    port map (
      I => wr_clk_main_125m_buf,
      O => clk_125m_pllref_buf);

  cmp_ibufds_gte4_dmtd : IBUFDS_GTE4
    generic map (
      -- drive ODIV2 with constant zero
      REFCLK_HROW_CK_SEL => "10")
    port map (
      CEB  => '0',
      I  => wr_clk_helper_125m_p_i,
      IB => wr_clk_helper_125m_n_i,
      O  => clk_125m_dmtdref_buf,
      ODIV2  => open);

  cmp_xwrc_platform : xwrc_platform_xilinx
    generic map (
      g_fpga_family               => "zynqus_qpll_sdm",
      g_with_external_clock_input => g_with_external_clock_input,
      g_use_default_plls          => TRUE,
      g_simulation                => g_simulation,
      g_dac_bits                  => g_dac_bits)
    port map (
      areset_n_i            => areset_n_i,
      clk_10m_ext_i         => clk_10m_ext_i,
      clk_125m_pllref_i     => clk_125m_pllref_buf,
      clk_125m_gtp_p_i      => wr_clk_sfp_125m_p_i,
      clk_125m_gtp_n_i      => wr_clk_sfp_125m_n_i,
      clk_125m_dmtd_i       => clk_125m_dmtdref_buf,
      dac_hpll_data_i       => dac_hpll_data,
      dac_hpll_load_p1_i    => dac_hpll_load_p1,
      dac_dpll_data_i       => dac_dpll_data,
      dac_dpll_load_p1_i    => dac_dpll_load_p1,
      dummy_gthtxp_o        => dummy_gthtxp_o,
      dummy_gthtxn_o        => dummy_gthtxn_o,
      dummy_gthrxp_i        => dummy_gthrxp_i,
      dummy_gthrxn_i        => dummy_gthrxn_i,
      sfp_txn_o             => sfp_txn_o,
      sfp_txp_o             => sfp_txp_o,
      sfp_rxn_i             => sfp_rxn_i,
      sfp_rxp_i             => sfp_rxp_i,
      sfp_tx_fault_i        => sfp_tx_fault_i,
      sfp_los_i             => sfp_los_i,
      sfp_tx_disable_o      => sfp_tx_disable_n,
      clk_62m5_sys_o        => clk_pll_62m5,
      clk_125m_ref_o        => clk_pll_125m,
      clk_62m5_dmtd_o       => clk_pll_dmtd,
      pll_locked_o          => pll_locked,
      clk_10m_ext_o         => clk_10m_ext,
      phy16_o               => phy16_to_wrc,
      phy16_i               => phy16_from_wrc,
      ext_ref_mul_o         => ext_ref_mul,
      ext_ref_mul_locked_o  => ext_ref_mul_locked,
      ext_ref_mul_stopped_o => ext_ref_mul_stopped,
      ext_ref_rst_i         => ext_ref_rst);

  --  the board invert the tx_disable signal.
  sfp_tx_disable_o <= not sfp_tx_disable_n;

  clk_ref_125m_o <= clk_pll_125m;
  clk_sys_62m5_o <= clk_pll_62m5;

  -----------------------------------------------------------------------------
  -- Reset logic
  -----------------------------------------------------------------------------
  -- Detect when areset_edge_n_i goes high (end of reset) and use this edge to
  -- generate rstlogic_arst. This is needed to connect optional reset like PCIe
  -- reset. When baord runs standalone, we need to ignore PCIe reset being
  -- constantly low.
  cmp_arst_edge: gc_sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_pll_62m5,
      rst_n_i  => '1',
      data_i   => areset_edge_n_i,
      ppulse_o => areset_edge_ppulse);

  -- logic OR of all async reset sources (active high)
  rstlogic_arst <= (not pll_locked) or (not areset_n_i) or areset_edge_ppulse;

  -- concatenation of all clocks required to have synced resets
  rstlogic_clk_in(0)          <= clk_pll_62m5;
  rstlogic_clk_in(1)          <= clk_pll_125m;

  cmp_rstlogic_reset : gc_reset_multi_aasd
    generic map (
      g_CLOCKS  => 2,   -- 62.5MHz, 125MHz
      g_RST_LEN => 16)  -- 16 clock cycles
    port map (
      arst_i  => rstlogic_arst,
      clks_i  => rstlogic_clk_in,
      rst_n_o => rstlogic_rst_out);

  -- distribution of resets (already synchronized to their clock domains)
  rst_62m5_n <= rstlogic_rst_out(0);

  rst_sys_62m5_n_o <= rst_62m5_n;
  rst_ref_125m_n_o <= rstlogic_rst_out(1);

  -----------------------------------------------------------------------------
  -- The WR PTP Core
  -----------------------------------------------------------------------------

  cmp_board_common : xwrc_board_common
    generic map (
      g_simulation                => g_simulation,
      g_verbose                   => TRUE,
      g_with_external_clock_input => g_with_external_clock_input,
      g_board_name                => g_board_name,
      g_phys_uart                 => TRUE,
      g_virtual_uart              => TRUE,
      g_aux_clks                  => g_aux_clks,
      g_ep_rxbuf_size             => 1024,
      g_tx_runt_padding           => TRUE,
      g_dpram_initf               => g_dpram_initf,
      g_dpram_size                => 262144/4,
      g_interface_mode            => PIPELINED,
      g_address_granularity       => BYTE,
      g_aux_sdb                   => c_wrc_periph3_sdb,
      g_softpll_enable_debugger   => FALSE,
      g_vuart_fifo_size           => 1024,
      g_pcs_16bit                 => TRUE,
      g_diag_id                   => g_diag_id,
      g_diag_ver                  => g_diag_ver,
      g_diag_ro_size              => g_diag_ro_size,
      g_diag_rw_size              => g_diag_rw_size,
      g_fabric_iface              => plain,
      g_dac_bits                  => g_dac_bits)
    port map (
      clk_sys_i            => clk_pll_62m5,
      clk_dmtd_i           => clk_pll_dmtd,
      clk_ref_i            => clk_pll_125m,
      clk_10m_ext_i        => clk_10m_ext,
      clk_ext_mul_i        => ext_ref_mul,
      clk_ext_mul_locked_i => ext_ref_mul_locked,
      clk_ext_stopped_i    => ext_ref_mul_stopped,
      clk_ext_rst_o        => ext_ref_rst,
      pps_ext_i            => pps_ext_i,
      rst_n_i              => rst_62m5_n,
      dac_hpll_load_p1_o   => dac_hpll_load_p1,
      dac_hpll_data_o      => dac_hpll_data,
      dac_dpll_load_p1_o   => dac_dpll_load_p1,
      dac_dpll_data_o      => dac_dpll_data,
      phy16_o              => phy16_from_wrc,
      phy16_i              => phy16_to_wrc,
      scl_o                => eeprom_scl_o,
      scl_i                => eeprom_scl_i,
      sda_o                => eeprom_sda_o,
      sda_i                => eeprom_sda_i,
      sfp_scl_o            => sfp_scl_o,
      sfp_scl_i            => sfp_scl_i,
      sfp_sda_o            => sfp_sda_o,
      sfp_sda_i            => sfp_sda_i,
      sfp_det_i            => sfp_det_i,
      uart_rxd_i           => uart0_rxd_i,
      uart_txd_o           => uart0_txd_o,
      wb_slave_i           => wb_slave_i,
      wb_slave_o           => wb_slave_o,
      aux_master_o         => aux_master_out,
      aux_master_i         => aux_master_in,
      wrf_src_o            => wrf_src_o,
      wrf_src_i            => wrf_src_i,
      wrf_snk_o            => wrf_snk_o,
      wrf_snk_i            => wrf_snk_i,
      -- Generic diagnostics i/f
      aux_diag_i           => aux_diag_i,
      aux_diag_o           => aux_diag_o,
      -- Aux clocks control
      tm_dac_value_o       => tm_dac_value_o,
      tm_dac_wr_o          => tm_dac_wr_o,
      tm_clk_aux_lock_en_i => tm_clk_aux_lock_en_i,
      tm_clk_aux_locked_o  => tm_clk_aux_locked_o,
      -- External Tx Timestamping i/f
      timestamps_o         => timestamps_o,
      timestamps_ack_i     => timestamps_ack_i,
      -- Abscal signals
      abscal_txts_o        => abscal_txts_o,
      abscal_rxts_o        => abscal_rxts_o,
      tm_link_up_o         => tm_link_up_o,
      tm_time_valid_o      => tm_time_valid_o,
      tm_tai_o             => tm_tai_o,
      tm_cycles_o          => tm_cycles_o,
      led_act_o            => led_act_o,
      led_link_o           => led_link_o,
      pps_p_o              => pps_p_o,
      pps_valid_o          => pps_valid_o,
      pps_led_o            => pps_led_o,
      link_ok_o            => link_ok_o);

  cmp_board_crossbar : xwb_sdb_crossbar
    generic map(
      g_verbose     => TRUE,
      g_num_masters => 1,
      g_num_slaves  => 3,
      g_registered  => true,
      g_wraparound  => true,
      g_layout      => c_tertbar_layout,
      g_sdb_addr    => c_tertbar_sdb_address
      )
    port map(
      clk_sys_i  => clk_pll_62m5,
      rst_n_i    => rst_62m5_n,
      -- Master connections (INTERCON is a slave)
      slave_i(0) => aux_master_out,
      slave_o(0) => aux_master_in,
      -- Slave connections (INTERCON is a master)
      master_i   => tertbar_master_i,
      master_o   => tertbar_master_o
      );

  tertbar_master_i(0) <= enfmc_wb_out;
  enfmc_wb_in         <= tertbar_master_o(0);

  tertbar_master_i(1) <= gps_uart_wb_out;
  gps_uart_wb_in      <= tertbar_master_o(1);

  tertbar_master_i(2) <= si570_wb_out;
  si570_wb_in         <= tertbar_master_o(2);

  -----------------------------------------------------------------------------
  -- Enable FMC pins
  -----------------------------------------------------------------------------
  cmp_board_enfmc: entity work.xwb_gpio_port
    generic map(
      g_interface_mode         => PIPELINED,
      g_address_granularity    => BYTE,
      g_num_pins               => g_num_fmc_enable,
      g_with_builtin_tristates => false)
    port map(
      clk_sys_i         => clk_pll_62m5,
      rst_n_i           => rst_62m5_n,

      gpio_out_o        => fmc_enable_o,
      gpio_in_i         => (others => '0'),
      gpio_b            => open,

      slave_i           => enfmc_wb_in,
      slave_o           => enfmc_wb_out
    );

  -----------------------------------------------------------------------------
  -- Si570
  -----------------------------------------------------------------------------
  cmp_board_si570: entity work.xwr_si57x_interface
    generic map(
      g_simulation      => g_simulation)
    port map(
      clk_sys_i         => clk_pll_62m5,
      rst_n_i           => rst_62m5_n,

      scl_pad_oen_o     => si570_scl_oen_o,
      sda_pad_oen_o     => si570_sda_oen_o,
      scl_pad_i         => si570_scl_i,
      sda_pad_i         => si570_sda_i,

      slave_i           => si570_wb_in,
      slave_o           => si570_wb_out
    );

  -----------------------------------------------------------------------------
  -- GPS Uart device
  -----------------------------------------------------------------------------
  cmp_gps_uart : xwb_simple_uart
    generic map(
      g_with_virtual_uart   => FALSE,
      g_with_physical_uart  => TRUE,
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE,
      g_vuart_fifo_size     => 1024,
      g_WITH_PHYSICAL_UART_FIFO => TRUE,
      g_TX_FIFO_SIZE => 1024,
      g_RX_FIFO_SIZE => 1024
    )
    port map(
      clk_sys_i => clk_pll_62m5,
      rst_n_i   => rst_62m5_n,

      -- Wishbone
      slave_i => gps_uart_wb_in,
      slave_o => gps_uart_wb_out,
      desc_o  => open,

      uart_rxd_i => uart1_rxd_i,
      uart_txd_o => uart1_txd_o
    );

  sfp_rate_select_o <= '1';

end architecture struct;
