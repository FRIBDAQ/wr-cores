-------------------------------------------------------------------------------
-- Title      : WRPC Wrapper for FASEC package
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : wr_cute_a7_pkg.vhd
-- Author(s)  : Grzegorz Daniluk <grzegorz.daniluk@cern.ch>
-- Company    : CERN (BE-CO-HT)
-- Created    : 2017-08-02
-- Last update: 2017-09-07
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
--
-- Copyright (c) 2017 CERN
--
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

library work;
use work.wishbone_pkg.all;
use work.wrcore_pkg.all;
use work.wr_fabric_pkg.all;
use work.endpoint_pkg.all;
use work.wr_board_pkg.all;
use work.streamers_pkg.all;
use work.etherbone_pkg.all;

package wr_cute_a7_pkg is

component xwrc_board_cute_a7 is
generic(
    g_simulation                : integer                        := 0;
    g_verbose                   : boolean                        := TRUE;
    g_with_external_clock_input : boolean                        := TRUE;
    g_board_name                : string                         := "cute";
    g_flash_secsz_kb            : integer                        := 64;        -- default for N25Q128
    g_flash_sdbfs_baddr         : integer                        := 16#760000#; -- default for N25Q128
    g_phys_uart                 : boolean                        := TRUE;
    g_virtual_uart              : boolean                        := TRUE;
    g_aux_clks                  : integer                        := 0;
    g_ep_rxbuf_size             : integer                        := 1024;
    g_tx_runt_padding           : boolean                        := TRUE;
    g_dpram_initf               : string                         := "wrc_phy16.bram";
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
    g_fabric_iface              : t_board_fabric_iface           := PLAIN;
    g_with_10M_output           : boolean                        := false;
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
    clk_ext_i            : in std_logic := '0';
    clk_ext_mul_i        : in  std_logic := '0';
    clk_ext_mul_locked_i : in  std_logic := '1';
    clk_ext_stopped_i    : in  std_logic := '0';
    clk_ext_rst_o        : out std_logic;
    -- External PPS input (cesium, GPSDO, etc.), used in Grandmaster mode
    pps_ext_i   : in std_logic := '0';
    ppsin_term_o : out std_logic;
    todin_term_o         : out   std_logic;
    ext_tai_valid_p_i    : in    std_logic := '0';
    ext_tai_i            : in    std_logic_vector(39 downto 0) := (others => '0');
    ext_tai_ready_i      : in    std_logic := '0';
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
    phy8_o  : out t_phy_8bits_from_wrc_array(g_num_phys-1 downto 0);
    phy8_i  : in  t_phy_8bits_to_wrc_array(g_num_phys-1 downto 0):=(others=>c_dummy_phy8_to_wrc);
    phy16_o : out t_phy_16bits_from_wrc_array(g_num_phys-1 downto 0);
    phy16_i : in  t_phy_16bits_to_wrc_array(g_num_phys-1 downto 0):=(others=>c_dummy_phy16_to_wrc);
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
    sfp_scl_o : out std_logic_vector(g_num_phys-1 downto 0);
    sfp_scl_i : in  std_logic_vector(g_num_phys-1 downto 0):= (others=>'1');
    sfp_sda_o : out std_logic_vector(g_num_phys-1 downto 0);
    sfp_sda_i : in  std_logic_vector(g_num_phys-1 downto 0):= (others=>'1');
    sfp_det_i : in  std_logic_vector(g_num_phys-1 downto 0):= (others=>'1');
    -- Flash
    flash_spi_sclk_o : out std_logic;
    flash_spi_ncs_o  : out std_logic;
    flash_spi_mosi_o : out std_logic;
    flash_spi_miso_i : in  std_logic := '0';
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
    led_act_o      : out std_logic_vector(g_num_phys-1 downto 0);
    led_link_o     : out std_logic_vector(g_num_phys-1 downto 0);
    btn1_i         : in  std_logic := '1';
    btn2_i         : in  std_logic := '1';
    -- 1PPS output
    pps_csync_o    : out std_logic;
    pps_valid_o    : out std_logic;
    pps_unmask_o   : out std_logic;
    pps_p_o        : out std_logic;
    pps_led_o      : out std_logic;
    sync_clk_10m_o_p : out std_logic;
    sync_clk_10m_o_n : out std_logic;
    -- Link ok indication
    link_ok_o : out std_logic_vector(g_num_phys-1 downto 0)
);
end component xwrc_board_cute_a7;

component wr_pll_ctrl is
generic (
    g_project_name : string := "normal";
    g_spi_clk_freq : std_logic_vector(31 downto 0) := x"00000004");
port (
    clk_i          : in  std_logic;
    rst_n_i        : in  std_logic;
    --- pll status/control
    pll_lock_i     : in  std_logic:='0';
    pll_reset_n_o  : out std_logic;
    pll_status_i   : in  std_logic:='0';
    pll_refsel_o   : out std_logic;
    pll_sync_n_o   : out std_logic;
    -- spi bus - pll control
    pll_cs_n_o     : out std_logic;
    pll_sck_o      : out std_logic;
    pll_mosi_o     : out std_logic;
    pll_miso_i     : in  std_logic;
    -- spi controller status
    done_o         : out std_logic);
end component wr_pll_ctrl;

component xwr_sma_config is
generic (
    g_interface_mode      : t_wishbone_interface_mode      := PIPELINED;
    g_address_granularity : t_wishbone_address_granularity := WORD
);
port (
    rst_n_i      : in std_logic;
    clk_sys_i    : in std_logic;
    clk_serdes_i : in std_logic;
    pps_csync_i     : in std_logic;
    pps_valid_i     : in std_logic;
    tm_tai_i        : in std_logic_vector(39 downto 0);
            
    sync_data_o_p  : out std_logic_vector(1 downto 0);
    sync_data_o_n  : out std_logic_vector(1 downto 0);

    fdly_en_o      : out std_logic;
    fdly_sload_o   : out std_logic;
    fdly_sdin_o    : out std_logic;
    fdly_sclk_o    : out std_logic;

    slave_i   : in  t_wishbone_slave_in := cc_dummy_slave_in;
    slave_o   : out t_wishbone_slave_out
);
end component; 

constant c_null_sdb : t_sdb_device := (
    abi_class     => x"0000",              -- undocumented device
    abi_ver_major => x"01",
    abi_ver_minor => x"01",
    wbd_endian    => c_sdb_endian_big,
    wbd_width     => x"7",                 -- 8/16/32-bit port granularity
    sdb_component => (
      addr_first  => x"0000000000000000",
      addr_last   => x"00000000000000ff",
      product     => (
        vendor_id => x"0000000000746875",  -- THU
        device_id => x"11111111",
        version   => x"00000001",
        date      => x"20201119",
        name      => "WR-NULL            ")));

constant c_sma_config_sdb : t_sdb_device := (
        abi_class     => x"0000",              -- undocumented device
        abi_ver_major => x"01",
        abi_ver_minor => x"01",
        wbd_endian    => c_sdb_endian_big,
        wbd_width     => x"7",                 -- 8/16/32-bit port granularity
        sdb_component => (
        addr_first  => x"0000000000000000",
        addr_last   => x"00000000000000ff",
        product     => (
            vendor_id => x"0000000000746875",  -- THU
            device_id => x"736d6101",
            version   => x"00000001",
            date      => x"20210606",
            name      => "WR-SMA-Config      ")));

end wr_cute_a7_pkg;
