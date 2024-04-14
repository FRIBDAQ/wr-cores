-------------------------------------------------------------------------------
-- Title      : Common WRPC Wrapper
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : xwrc_board_common.vhd
-- Company    : CERN (BE-CO-HT)
-- Created    : 2019-06-02
-- Last update: 2019-06-02
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Wrapper for WR PTP core with common features shared between
-- the various supported boards. These include the core itself, as well as
-- a selection of fabric interfaces between the core and the application.
-------------------------------------------------------------------------------
-- Copyright (c) 2018 CERN
-------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
--
-- This source file is free software; you can redistribute it   
-- and/or modify it under the terms of the GNU Lesser General   
-- Public License as published by the Free Software Foundation; 
-- either version 2.1 of the License,or (at your option) any   
-- later version.                                               
--
-- This source is distributed in the hope that it will be       
-- useful,but WITHOUT ANY WARRANTY; without even the implied   
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
-- PURPOSE.  See the GNU Lesser General Public License for more 
-- details.                                                     
--
-- You should have received a copy of the GNU Lesser General    
-- Public License along with this source; if not,download it   
-- from http://www.gnu.org/licenses/lgpl-2.1.html
-- 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gencores_pkg.all;
use work.wrcore_pkg.all;
use work.wishbone_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;
use work.streamers_pkg.all;
use work.wr_board_pkg.all;
use work.etherbone_pkg.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity xwrc_board_common is
  generic(
    g_simulation                : integer                        := 0;
    g_verbose                   : boolean                        := TRUE;
    g_with_external_clock_input : boolean                        := TRUE;
    g_board_name                : string                         := "NA  ";
    g_flash_secsz_kb            : integer                        := 256;        -- default for M25P128
    g_flash_sdbfs_baddr         : integer                        := 16#600000#; -- default for M25P128
    g_phys_uart                 : boolean                        := TRUE;
    g_virtual_uart              : boolean                        := TRUE;
    g_aux_clks                  : integer                        := 0;
    g_ep_rxbuf_size             : integer                        := 1024;
    g_tx_runt_padding           : boolean                        := TRUE;
    g_dpram_initf               : string                         := "";
    g_dpram_size                : integer                        := 131072/4;
    g_interface_mode            : t_wishbone_interface_mode      := PIPELINED;
    g_address_granularity       : t_wishbone_address_granularity := BYTE;
    g_aux_sdb                   : t_sdb_device                   := c_wrc_periph3_sdb;
    g_aux1_sdb                  : t_sdb_device                   := c_wrc_periph3_sdb;
    g_etherbone_sdb             : t_sdb_device                   := c_etherbone_sdb;
    g_softpll_enable_debugger   : boolean                        := FALSE;
    g_vuart_fifo_size           : integer                        := 1024;
    g_pcs_16bit                 : boolean                        := TRUE;
    g_ref_clock_rate            : integer                        := 62500000;
    g_sys_clock_rate            : integer                        := 62500000;
    g_ref_clock_hz              : integer                        := 62500000;
    g_sys_clock_hz              : integer                        := 62500000;
    g_ext_clock_rate            : integer                        := 1000000;    
    g_diag_id                   : integer                        := 0;
    g_diag_ver                  : integer                        := 0;
    g_diag_ro_size              : integer                        := 0;
    g_diag_rw_size              : integer                        := 0;
    g_streamers_op_mode         : t_streamers_op_mode            := TX_AND_RX;
    g_tx_streamer_params        : t_tx_streamer_params           := c_tx_streamer_params_defaut;
    g_rx_streamer_params        : t_rx_streamer_params           := c_rx_streamer_params_defaut;
    g_fabric_iface              : t_board_fabric_iface           := ETHERBONE;
    g_with_10M_output           : boolean                        := true;
    g_num_phys                  : integer                        := 2);
  port(
    ---------------------------------------------------------------------------
    -- Clocks/resets
    ---------------------------------------------------------------------------
    -- system reference clock (any frequency <= f(clk_ref_i))
    clk_sys_i : in std_logic;

    -- DDMTD offset clock (62.5- MHz)
    clk_dmtd_i : in std_logic;

    -- Timing reference (125 MHz/62.5MHz)
    clk_ref_i : in std_logic;

    -- Aux clock (i.e. the FMC clock), which can be disciplined by the WR Core
    clk_aux_i : in std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');

    -- External 10 MHz reference (cesium, GPSDO, etc.), used in Grandmaster mode
    clk_10m_ext_i : in std_logic := '0';

    clk_ext_mul_i        : in  std_logic := '0';
    clk_ext_mul_locked_i : in  std_logic := '1';
    clk_ext_stopped_i    : in  std_logic := '0';
    clk_ext_rst_o        : out std_logic;

    -- External PPS input (cesium, GPSDO, etc.), used in Grandmaster mode
    pps_ext_i : in std_logic := '0';
    ppsin_term_o : out std_logic;
    rst_n_i : in std_logic;

    ---------------------------------------------------------------------------
    --Timing system
    ---------------------------------------------------------------------------
    dac_hpll_load_p1_o : out std_logic;
    dac_hpll_data_o    : out std_logic_vector(15 downto 0);
    dac_dpll_load_p1_o : out std_logic;
    dac_dpll_data_o    : out std_logic_vector(15 downto 0);

    ---------------------------------------------------------------------------
    -- PHY I/f
    ---------------------------------------------------------------------------
    phy8_o    : out t_phy_8bits_from_wrc_array(g_num_phys-1 downto 0);
    phy8_i    : in  t_phy_8bits_to_wrc_array(g_num_phys-1 downto 0):=(others=>c_dummy_phy8_to_wrc);
    phy16_o   : out t_phy_16bits_from_wrc_array(g_num_phys-1 downto 0);
    phy16_i   : in  t_phy_16bits_to_wrc_array(g_num_phys-1 downto 0):=(others=>c_dummy_phy16_to_wrc);

    ---------------------------------------------------------------------------
    -- I2C EEPROM
    ---------------------------------------------------------------------------
    scl_o : out std_logic;
    scl_i : in  std_logic := '1';
    sda_o : out std_logic;
    sda_i : in  std_logic := '1';

    ---------------------------------------------------------------------------
    -- SFP management info
    ---------------------------------------------------------------------------
    sfp_scl_o  : out std_logic_vector(g_num_phys-1 downto 0);
    sfp_scl_i  : in  std_logic_vector(g_num_phys-1 downto 0):= (others=>'1');
    sfp_sda_o  : out std_logic_vector(g_num_phys-1 downto 0);
    sfp_sda_i  : in  std_logic_vector(g_num_phys-1 downto 0):= (others=>'1');
    sfp_det_i  : in  std_logic_vector(g_num_phys-1 downto 0):= (others=>'1');

    ---------------------------------------------------------------------------
    -- Flash memory SPI interface
    ---------------------------------------------------------------------------
    spi_sclk_o : out std_logic;
    spi_ncs_o  : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic := '0';

    ---------------------------------------------------------------------------
    --UART
    ---------------------------------------------------------------------------
    uart_rxd_i : in  std_logic := '0';
    uart_txd_o : out std_logic;

    ---------------------------------------------------------------------------
    -- 1-wire
    ---------------------------------------------------------------------------
    owr_pwren_o : out std_logic_vector(1 downto 0);
    owr_en_o    : out std_logic_vector(1 downto 0);
    owr_i       : in  std_logic_vector(1 downto 0) := (others => '1');
    -----------------------------------------
    -- PLL chip configuration
    -----------------------------------------
    pll_mosi_o    : out std_logic;
    pll_miso_i    : in  std_logic:='0';
    pll_sck_o     : out std_logic;
    pll_cs_n_o    : out std_logic;
    pll_sync_n_o  : out std_logic;
    pll_reset_n_o : out std_logic;
    -----------------------------------------
    -- EXT IN PLL chip configuration
    -----------------------------------------
    ext_pll_mosi_o    : out std_logic;
    ext_pll_miso_i    : in  std_logic:='0';
    ext_pll_sck_o     : out std_logic;
    ext_pll_cs_n_o    : out std_logic;
    ext_pll_sync_n_o  : out std_logic;
    ext_pll_reset_n_o : out std_logic;
    ---------------------------------------------------------------------------
    --External WB interface
    ---------------------------------------------------------------------------
    wb_slave_i : in  t_wishbone_slave_in := cc_dummy_slave_in;
    wb_slave_o : out t_wishbone_slave_out;

    aux_master_o : out t_wishbone_master_out;
    aux_master_i : in  t_wishbone_master_in := cc_dummy_master_in;
    aux1_master_o : out t_wishbone_master_out;
    aux1_master_i : in  t_wishbone_master_in := cc_dummy_master_in;
    eb_cfg_master_o : out t_wishbone_master_out;
    eb_cfg_master_i : in  t_wishbone_master_in := cc_dummy_master_in;

    ---------------------------------------------------------------------------
    -- External Fabric I/F (when g_fabric_iface = PLAIN)
    ---------------------------------------------------------------------------
    wrf_src_o : out t_wrf_source_out_array(g_num_phys-1 downto 0);
    wrf_src_i : in  t_wrf_source_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_src_in);
    wrf_snk_o : out t_wrf_sink_out_array(g_num_phys-1 downto 0);
    wrf_snk_i : in  t_wrf_sink_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_snk_in);

    eb_wrf_src_o : out t_wrf_source_out_array(g_num_phys-1 downto 0);
    eb_wrf_src_i : in  t_wrf_source_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_src_in);
    eb_wrf_snk_o : out t_wrf_sink_out_array(g_num_phys-1 downto 0);
    eb_wrf_snk_i : in  t_wrf_sink_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_snk_in);

    ---------------------------------------------------------------------------
    -- WR streamers (when g_fabric_iface = STREAMERS)
    ---------------------------------------------------------------------------
    wrs_tx_data_i  : in  std_logic_vector(g_tx_streamer_params.data_width-1 downto 0) := (others => '0');
    wrs_tx_valid_i : in  std_logic                                        := '0';
    wrs_tx_dreq_o  : out std_logic;
    wrs_tx_last_i  : in  std_logic                                        := '1';
    wrs_tx_flush_i : in  std_logic                                        := '0';
    wrs_rx_first_o : out std_logic;
    wrs_rx_last_o  : out std_logic;
    wrs_rx_data_o  : out std_logic_vector(g_rx_streamer_params.data_width-1 downto 0);
    wrs_rx_valid_o : out std_logic;
    wrs_rx_dreq_i  : in  std_logic                                        := '0';
    wrs_tx_cfg_i   : in t_tx_streamer_cfg := c_tx_streamer_cfg_default;
    wrs_rx_cfg_i   : in t_rx_streamer_cfg := c_rx_streamer_cfg_default;
    ---------------------------------------------------------------------------
    -- Etherbone WB master interface (when g_fabric_iface = ETHERBONE)
    ---------------------------------------------------------------------------
    wb_eth_master_o : out t_wishbone_master_out;
    wb_eth_master_i : in  t_wishbone_master_in := cc_dummy_master_in;
    rst_aux_n_o     : out std_logic;
    ---------------------------------------------------------------------------
    -- Generic diagnostics interface (access from WRPC via SNMP or uart console
    ---------------------------------------------------------------------------
    aux_diag_i : in  t_generic_word_array(g_diag_ro_size-1 downto 0) := (others => (others => '0'));
    aux_diag_o : out t_generic_word_array(g_diag_rw_size-1 downto 0);

    ---------------------------------------------------------------------------
    -- Aux clocks control
    ---------------------------------------------------------------------------
    tm_dac_value_o       : out std_logic_vector(23 downto 0);
    tm_dac_wr_o          : out std_logic_vector(g_aux_clks-1 downto 0);
    tm_clk_aux_lock_en_i : in  std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');
    tm_clk_aux_locked_o  : out std_logic_vector(g_aux_clks-1 downto 0);

    ---------------------------------------------------------------------------
    -- External Tx Timestamping I/F
    ---------------------------------------------------------------------------
    timestamps_o     : out t_txtsu_timestamp_array(g_num_phys-1 downto 0);
    timestamps_ack_i : in  std_logic_vector(g_num_phys-1 downto 0):=(others=>'1');

    -----------------------------------------
    -- Timestamp helper signals, used for Absolute Calibration
    -----------------------------------------
    abscal_txts_o        : out std_logic_vector(g_num_phys-1 downto 0);
    abscal_rxts_o        : out std_logic_vector(g_num_phys-1 downto 0);

    ---------------------------------------------------------------------------
    -- Pause Frame Control
    ---------------------------------------------------------------------------
    fc_tx_pause_req_i   : in  std_logic_vector(g_num_phys-1 downto 0):=(others=>'0');
    fc_tx_pause_delay_i : in  std_logic_vector(16*g_num_phys-1 downto 0):=(others=>'0');
    fc_tx_pause_ready_o : out std_logic_vector(g_num_phys-1 downto 0);

    ---------------------------------------------------------------------------
    -- Timecode I/F
    ---------------------------------------------------------------------------
    tm_link_up_o    : out std_logic_vector(g_num_phys-1 downto 0);
    tm_time_valid_o : out std_logic;
    tm_tai_o        : out std_logic_vector(39 downto 0);
    tm_cycles_o     : out std_logic_vector(27 downto 0);

    ---------------------------------------------------------------------------
    -- Buttons, LEDs and PPS output
    ---------------------------------------------------------------------------
    led_act_o       : out std_logic_vector(g_num_phys-1 downto 0);
    led_link_o      : out std_logic_vector(g_num_phys-1 downto 0);
    btn1_i          : in  std_logic := '1';
    btn2_i          : in  std_logic := '1';
    -- 1PPS output
    pps_csync_o     : out std_logic;
    pps_valid_o     : out std_logic;
    pps_p_o         : out std_logic;
    pps_led_o       : out std_logic;
    sync_clk_10m_o_p   : out std_logic;
    sync_clk_10m_o_n   : out std_logic;    
    -- Link ok indication
    link_ok_o       : out std_logic_vector(g_num_phys-1 downto 0)
    );

end entity xwrc_board_common;


architecture struct of xwrc_board_common is

    component eb_ethernet_slave is
    generic(
      g_sdb_address    : std_logic_vector(63 downto 0);
      g_timeout_cycles : natural := g_sys_clock_rate/10; -- 100 ms at 62.5MHz
      g_mtu            : natural := 1500);
    port(
      clk_i       : in  std_logic;
      nrst_i      : in  std_logic;
      snk_i       : in  t_wrf_sink_in;
      snk_o       : out t_wrf_sink_out;
      src_o       : out t_wrf_source_out;
      src_i       : in  t_wrf_source_in;
      cfg_slave_o : out t_wishbone_slave_out;
      cfg_slave_i : in  t_wishbone_slave_in;
      master_o    : out t_wishbone_master_out;
      master_i    : in  t_wishbone_master_in);
  end component;

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  -- Timecode interface
  signal tm_time_valid : std_logic;
  signal tm_tai        : std_logic_vector(39 downto 0);
  signal tm_cycles     : std_logic_vector(27 downto 0);

  -- Etherbone WR fabric interface
  signal eb_wrf_src_out : t_wrf_source_out_array(g_num_phys-1 downto 0);
  signal eb_wrf_src_in  : t_wrf_source_in_array(g_num_phys-1 downto 0);
  signal eb_wrf_snk_out : t_wrf_sink_out_array(g_num_phys-1 downto 0);
  signal eb_wrf_snk_in  : t_wrf_sink_in_array(g_num_phys-1 downto 0);


  -- WR fabric interface
  signal wrf_src_out : t_wrf_source_out_array(g_num_phys-1 downto 0);
  signal wrf_src_in  : t_wrf_source_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_src_in);
  signal wrf_snk_out : t_wrf_sink_out_array(g_num_phys-1 downto 0);
  signal wrf_snk_in  : t_wrf_sink_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_snk_in);

  -- Aux WB interface
  signal aux_master_out : t_wishbone_master_out;
  signal aux_master_in  : t_wishbone_master_in;
  signal aux_rst_n      : std_logic;

  -- Etherbone WB config interface 
  signal eb_cfg_master_out : t_wishbone_master_out;
  signal eb_cfg_master_in  : t_wishbone_master_in;

  -- Aux diagnostics:
  -- 1) streamers have their own ID not to be used by the users
  -- 2) regardless whether streamers are enabled nor not, application can use diagnostics
  -- 3) if application uses diagnostics, it must specify diag_id > 1, diag_ver should start
  --    with 1.
  -- Application diagnostic words are added after streamer's diagnostics in the array that
  -- goes to/from WRPC

  constant c_streamers_diag_id  : integer := 1;  -- id reserved for streamers
  constant c_streamers_diag_ver : integer := 2;  -- version that will be probably increased
  -- when more diagnostics is added to streamers

  -- final values that go to WRPC generics (depend on configuration)
  constant c_diag_id  : integer := f_pick_diag_val(g_fabric_iface, c_streamers_diag_id, g_diag_id);
  constant c_diag_ver : integer := f_pick_diag_val(g_fabric_iface, c_streamers_diag_ver, g_diag_id);

  constant c_diag_ro_size : integer := f_pick_diag_size(g_fabric_iface, c_WR_STREAMERS_ARR_SIZE_OUT, g_diag_ro_size);
  constant c_diag_rw_size : integer := f_pick_diag_size(g_fabric_iface, c_WR_STREAMERS_ARR_SIZE_IN, g_diag_rw_size);

  -- WR SNMP
  signal aux_diag_in  : t_generic_word_array(c_diag_ro_size-1 downto 0);
  signal aux_diag_out : t_generic_word_array(c_diag_rw_size-1 downto 0);

  -- link state
  signal link_ok      : std_logic_vector(g_num_phys-1 downto 0);

  signal pps_valid     : std_logic;
  signal pps_csync     : std_logic;

  signal ext_ref_pps   : std_logic;

begin  -- architecture struct

  -- Check for unsupported fabric interface type
  f_check_fabric_iface_type(g_fabric_iface);

  -- check whether diag id and version are correct, i.e.:
  -- * diag_id =1 is reserved for wr_streamers and cannot be used
  -- * diag_ver values should start with 1
  f_check_diag_id(g_diag_id, g_diag_ver);

  -----------------------------------------------------------------------------
  -- The WR PTP core itself
  -----------------------------------------------------------------------------
  U_Sync_pps_refclk : gc_sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_ref_i,
      rst_n_i  => '1',
      data_i   => pps_ext_i,
      ppulse_o => ext_ref_pps);

  cmp_xwr_core : xwr_core
    generic map (
      g_simulation                => g_simulation,
      g_verbose                   => g_verbose,
      g_with_external_clock_input => g_with_external_clock_input,
      g_board_name                => g_board_name,
      g_flash_secsz_kb            => g_flash_secsz_kb,
      g_flash_sdbfs_baddr         => g_flash_sdbfs_baddr,
      g_phys_uart                 => g_phys_uart,
      g_virtual_uart              => g_virtual_uart,
      g_aux_clks                  => g_aux_clks,
      g_ep_rxbuf_size             => g_ep_rxbuf_size,
      g_tx_runt_padding           => g_tx_runt_padding,
      g_dpram_initf               => f_find_default_lm32_firmware(g_dpram_initf, g_simulation, g_pcs_16bit, FALSE),
      g_dpram_size                => g_dpram_size,
      g_interface_mode            => g_interface_mode,
      g_address_granularity       => g_address_granularity,
      g_aux_sdb                   => g_aux_sdb,
      g_aux1_sdb                  => g_aux1_sdb,
      g_etherbone_sdb             => g_etherbone_sdb,
      g_softpll_enable_debugger   => g_softpll_enable_debugger,
      g_vuart_fifo_size           => g_vuart_fifo_size,
      g_pcs_16bit                 => g_pcs_16bit,
      g_ref_clock_rate            => g_ref_clock_rate,
      g_sys_clock_rate            => g_sys_clock_rate,
      g_ref_clock_hz              => g_ref_clock_hz,
      g_sys_clock_hz              => g_sys_clock_hz,
      g_ext_clock_rate            => g_ext_clock_rate,
      g_records_for_phy           => TRUE,
      g_diag_id                   => c_diag_id,
      g_diag_ver                  => c_diag_ver,
      g_diag_ro_size              => c_diag_ro_size,
      g_diag_rw_size              => c_diag_rw_size,
      g_num_phys                  => g_num_phys,
      g_num_softpll_inputs        => 2*g_num_phys,
      g_with_10M_output           => g_with_10M_output)
    port map (
      clk_sys_i            => clk_sys_i,
      clk_dmtd_i           => clk_dmtd_i,
      clk_ref_i            => clk_ref_i,
      clk_aux_i            => clk_aux_i,
      clk_ext_i            => clk_10m_ext_i,
      clk_ext_mul_i        => clk_ext_mul_i,
      clk_ext_mul_locked_i => clk_ext_mul_locked_i,
      clk_ext_stopped_i    => clk_ext_stopped_i,
      clk_ext_rst_o        => clk_ext_rst_o,
      pps_ext_i            => pps_ext_i,
      ppsin_term_o         => ppsin_term_o,
      todin_term_o         => open,
      ext_tai_valid_p_i    => '0',
      ext_tai_i            => (others => '0'),
      ext_tai_ready_i      => '0',
      rst_n_i              => rst_n_i,
      dac_hpll_load_p1_o   => dac_hpll_load_p1_o,
      dac_hpll_data_o      => dac_hpll_data_o,
      dac_dpll_load_p1_o   => dac_dpll_load_p1_o,
      dac_dpll_data_o      => dac_dpll_data_o,
      phy8_o               => phy8_o,
      phy8_i               => phy8_i,
      phy16_o              => phy16_o,
      phy16_i              => phy16_i,
      led_act_o            => led_act_o,
      led_link_o           => led_link_o,
      scl_o                => scl_o,
      scl_i                => scl_i,
      sda_o                => sda_o,
      sda_i                => sda_i,
      sfp_scl_o            => sfp_scl_o,
      sfp_scl_i            => sfp_scl_i,
      sfp_sda_o            => sfp_sda_o,
      sfp_sda_i            => sfp_sda_i,
      sfp_det_i            => sfp_det_i,
      btn1_i               => btn1_i,
      btn2_i               => btn2_i,
      spi_sclk_o           => flash_spi_sclk,
      spi_ncs_o            => flash_spi_ncs_o,
      spi_mosi_o           => flash_spi_mosi_o,
      spi_miso_i           => flash_spi_miso_i,
      uart_rxd_i           => uart_rxd_i,
      uart_txd_o           => uart_txd_o,
      owr_pwren_o          => owr_pwren_o,
      owr_en_o             => owr_en_o,
      owr_i                => owr_i,
      ext_pll_mosi_o       => ext_pll_mosi_o,
      ext_pll_miso_i       => ext_pll_miso_i,
      ext_pll_sck_o        => ext_pll_sck_o,
      ext_pll_cs_n_o       => ext_pll_cs_n_o,
      ext_pll_sync_n_o     => ext_pll_sync_n_o,
      ext_pll_reset_n_o    => ext_pll_reset_n_o,     
      pll_mosi_o           => pll_mosi_o,
      pll_miso_i           => pll_miso_i,
      pll_sck_o            => pll_sck_o,
      pll_cs_n_o           => pll_cs_n_o,
      pll_sync_n_o         => pll_sync_n_o,
      pll_reset_n_o        => pll_reset_n_o,  
      slave_i              => wb_slave_i,
      slave_o              => wb_slave_o,
      aux_master_o         => aux_master_out,
      aux_master_i         => aux_master_in,
      aux1_master_o        => aux1_master_o,
      aux1_master_i        => aux1_master_i,
      eb_cfg_master_o      => eb_cfg_master_out,
      eb_cfg_master_i      => eb_cfg_master_in,
      wrf_src_o            => wrf_src_out,
      wrf_src_i            => wrf_src_in,
      wrf_snk_o            => wrf_snk_out,
      wrf_snk_i            => wrf_snk_in,
      eb_wrf_src_o         => eb_wrf_src_out,
      eb_wrf_src_i         => eb_wrf_src_in,
      eb_wrf_snk_o         => eb_wrf_snk_out,
      eb_wrf_snk_i         => eb_wrf_snk_in,
      timestamps_o         => timestamps_o,
      timestamps_ack_i     => timestamps_ack_i,
      abscal_txts_o        => abscal_txts_o,
      abscal_rxts_o        => abscal_rxts_o,
      fc_tx_pause_req_i    => fc_tx_pause_req_i,
      fc_tx_pause_delay_i  => fc_tx_pause_delay_i,
      fc_tx_pause_ready_o  => fc_tx_pause_ready_o,
      tm_link_up_o         => tm_link_up_o,
      tm_dac_value_o       => tm_dac_value_o,
      tm_dac_wr_o          => tm_dac_wr_o,
      tm_clk_aux_lock_en_i => tm_clk_aux_lock_en_i,
      tm_clk_aux_locked_o  => tm_clk_aux_locked_o,
      tm_time_valid_o      => tm_time_valid,
      tm_tai_o             => tm_tai,
      tm_cycles_o          => tm_cycles,
      pps_csync_o          => pps_csync,
      pps_valid_o          => pps_valid,
      pps_p_o              => pps_p_o,
      pps_led_o            => pps_led_o,
      sync_clk_10m_o_p     => sync_clk_10m_o_n,
      sync_clk_10m_o_n     => sync_clk_10m_o_n,
      rst_aux_n_o          => aux_rst_n,
      aux_diag_i           => aux_diag_in,
      aux_diag_o           => aux_diag_out,
      link_ok_o            => link_ok);

  pps_csync_o     <= pps_csync;
  pps_valid_o     <= pps_valid;
  rst_aux_n_o     <= aux_rst_n;
  link_ok_o       <= link_ok;
  tm_time_valid_o <= tm_time_valid;
  tm_tai_o        <= tm_tai;
  tm_cycles_o     <= tm_cycles;

  gen_wr_streamers : if (g_fabric_iface = STREAMERS) generate

    cmp_xwr_streamers : xwr_streamers
      generic map (
        g_streamers_op_mode  => g_streamers_op_mode,
        g_tx_streamer_params => g_tx_streamer_params,
        g_rx_streamer_params => g_rx_streamer_params,
        g_simulation         => g_simulation,
        g_clk_ref_rate       => f_pick_clk_ref_rate(g_pcs_16bit))
      port map (
        clk_sys_i       => clk_sys_i,
        rst_n_i         => rst_n_i,
        src_i           => wrf_snk_out(0),
        src_o           => wrf_snk_in(0),
        snk_i           => wrf_src_out(0),
        snk_o           => wrf_src_in(0),
        tx_data_i       => wrs_tx_data_i,
        tx_valid_i      => wrs_tx_valid_i,
        tx_dreq_o       => wrs_tx_dreq_o,
        tx_last_p1_i    => wrs_tx_last_i,
        tx_flush_p1_i   => wrs_tx_flush_i,
        rx_first_p1_o   => wrs_rx_first_o,
        rx_last_p1_o    => wrs_rx_last_o,
        rx_data_o       => wrs_rx_data_o,
        rx_valid_o      => wrs_rx_valid_o,
        rx_dreq_i       => wrs_rx_dreq_i,
        clk_ref_i       => clk_ref_i,
        tm_time_valid_i => tm_time_valid,
        tm_tai_i        => tm_tai,
        tm_cycles_i     => tm_cycles,
        link_ok_i       => link_ok(0),
        wb_slave_i      => aux_master_out,
        wb_slave_o      => aux_master_in,
        snmp_array_o    => aux_diag_in(c_WR_STREAMERS_ARR_SIZE_OUT-1 downto 0),
        snmp_array_i    => aux_diag_out(c_WR_STREAMERS_ARR_SIZE_IN-1 downto 0),
        tx_streamer_cfg_i=> wrs_tx_cfg_i,
        rx_streamer_cfg_i=> wrs_rx_cfg_i);

    -- unused output ports
    wrf_src_o <= (others=>c_dummy_snk_in);
    wrf_snk_o <= (others=>c_dummy_src_in);

    aux_master_o    <= cc_dummy_master_out;
    wb_eth_master_o <= cc_dummy_master_out;

    aux_diag_in(c_diag_ro_size-1 downto c_WR_STREAMERS_ARR_SIZE_OUT) <= aux_diag_i;
    aux_diag_o                                                   <= aux_diag_out(c_diag_rw_size-1 downto c_WR_STREAMERS_ARR_SIZE_IN);

  end generate gen_wr_streamers;

  gen_etherbone : if (g_fabric_iface = ETHERBONE) generate

    cmp_eb_ethernet_slave : eb_ethernet_slave
      generic map (
        g_sdb_address => x"0000000000030000")
      port map (
        clk_i       => clk_sys_i,
        nrst_i      => aux_rst_n,
        src_o       => eb_wrf_snk_in(0),
        src_i       => eb_wrf_snk_out(0),
        snk_o       => eb_wrf_src_in(0),
        snk_i       => eb_wrf_src_out(0),
        cfg_slave_o => eb_cfg_master_in,
        cfg_slave_i => eb_cfg_master_out,
        master_o    => wb_eth_master_o,
        master_i    => wb_eth_master_i);

    wrf_src_o <= wrf_src_out;
    wrf_snk_o <= wrf_snk_out;

    wrf_src_in <= wrf_src_i;
    wrf_snk_in <= wrf_snk_i;
    
    aux_master_in <= aux_master_i;
    aux_master_o  <= aux_master_out;
    wrs_tx_dreq_o  <= '0';
    wrs_rx_first_o <= '0';
    wrs_rx_last_o  <= '0';
    wrs_rx_valid_o <= '0';
    wrs_rx_data_o  <= (others => '0');

    aux_master_o <= cc_dummy_master_out;

    -- unused inputs to WR PTP core
    aux_diag_in <= aux_diag_i;
    aux_diag_o  <= aux_diag_out;

  end generate gen_etherbone;

  gen_loopback : if (g_fabric_iface = LOOPBACK) generate

    cmp_wrf_loopback : xwrf_loopback
      generic map(
        g_interface_mode        => PIPELINED,
        g_address_granularity   => WORD)
      port map(
        clk_sys_i => clk_sys_i,
        rst_n_i   => rst_n_i,
        wrf_snk_i => wrf_src_out(0),
        wrf_snk_o => wrf_src_in(0),
        wrf_src_o => wrf_snk_in(0),
        wrf_src_i => wrf_snk_out(0),
        wb_i      => aux_master_out,
        wb_o      => aux_master_in);

    wrf_src_o <= (others=>c_dummy_snk_in);
    wrf_snk_o <= (others=>c_dummy_src_in);
    
  end generate gen_loopback;

  gen_wr_fabric : if (g_fabric_iface = PLAIN) generate

    wrf_src_o <= wrf_src_out;
    wrf_snk_o <= wrf_snk_out;

    wrf_src_in <= wrf_src_i;
    wrf_snk_in <= wrf_snk_i;

    -- unused output ports
    wrs_tx_dreq_o  <= '0';
    wrs_rx_first_o <= '0';
    wrs_rx_last_o  <= '0';
    wrs_rx_valid_o <= '0';
    wrs_rx_data_o  <= (others => '0');

    eb_wrf_src_o <= eb_wrf_src_out;
    eb_wrf_snk_o <= eb_wrf_snk_out;

    eb_wrf_src_in <= eb_wrf_src_i;
    eb_wrf_snk_in <= eb_wrf_snk_i;

    aux_master_in <= aux_master_i;
    aux_master_o  <= aux_master_out;

    eb_cfg_master_in <= eb_cfg_master_i;
    eb_cfg_master_o  <= eb_cfg_master_out;

    -- unused inputs to WR PTP core
    aux_diag_in <= aux_diag_i;
    aux_diag_o  <= aux_diag_out;

    wb_eth_master_o <= cc_dummy_master_out;

  end generate gen_wr_fabric;

end architecture struct;
