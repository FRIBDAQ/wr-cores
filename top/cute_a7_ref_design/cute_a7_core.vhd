-------------------------------------------------------------------------------
-- Title      : WRPC Core for CUTE-WR-A7
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : cute_a7_core.vhd
-- Author(s)  : Hongming Li <lihm.thu@foxmail.com>
--              Grzegorz Daniluk <grzegorz.daniluk@cern.ch>
-- Company    : Tsinghua Univ. (DEP),CERN
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: WRPC Core for project on the CUTE-WR-A7.
--
-- This is a reference top HDL that instanciates the WR PTP Core together with
-- its peripherals to be run on a CUTE-WR-A7 board.
--
-- There are two main usecases for this HDL file:
-- * let new users easily synthesize a WR PTP Core bitstream that can be run on
--   reference hardware
-- * provide a reference top HDL file showing how the WRPC can be instantiated
--   in HDL projects.
--
-- CUTE:  https://www.ohwr.org/project/cute-wr-a7
--
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
use work.wr_xilinx_pkg.all;
use work.wr_board_pkg.all;
use work.wishbone_pkg.all;
use work.wr_cute_a7_pkg.all;
use work.etherbone_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity cute_a7_core is
generic(
  -- project name, NORMAL
    g_project_name : string := "NORMAL";
    g_dpram_initf  : string := "../../../bin/wrpc/wrc_phy16.bram";
    g_board_name : string := "NM01";
  -- g_gtrefclk_src is 4bits integer
  -- each bit represents GTP ref clock source of each channel(phy)
  -- bit '0' selects PLL0(REF0)
  -- bit '1' selects PLL1(REF1)
    g_gtrefclk_src  : std_logic_vector(3 downto 0):=(others=>'1');
  -- g_ref_clk_sel is 4bits integer
  -- each bit represents the clk_ref_o source of each channel(phy)
  -- bit '0' selects TXOUT
  -- bit '1' selects (GTP ref clock/2)
    g_ref_clk_sel   : std_logic_vector(3 downto 0):=(others=>'1');
    g_num_output_clks  : integer := 2;
    g_with_10M_output : boolean := false;
    g_with_external_clock_input : boolean := true;
    -- true: use inner pll
    -- false: use ext ad9516
    g_fabric_iface : t_board_fabric_iface := ETHERBONE;
    g_etherbone_sdb : t_sdb_device := c_etherbone_sdb;
    g_aux1_sdb      : t_sdb_device := c_null_sdb;
    g_num_phys : integer := 2
);
port(
    SFP_RATE_SELECT_O     : out   std_logic_vector(g_num_phys-1 downto 0);
    SFP_TX_DISABLE_O      : out   std_logic_vector(g_num_phys-1 downto 0);
    SFP_TX_O_N            : out   std_logic_vector(g_num_phys-1 downto 0);
    SFP_TX_O_P            : out   std_logic_vector(g_num_phys-1 downto 0);
    SFP_RX_I_N            : in    std_logic_vector(g_num_phys-1 downto 0);
    SFP_RX_I_P            : in    std_logic_vector(g_num_phys-1 downto 0);
    SFP_FAULT_I           : in    std_logic_vector(g_num_phys-1 downto 0);
    SFP_LOS_I             : in    std_logic_vector(g_num_phys-1 downto 0);

    UART_RX_I             : in    std_logic;
    UART_TX_O             : out   std_logic;
    RESET_N               : in    std_logic;

    PPS_O_P               : out   std_logic;
    PPS_O_N               : out   std_logic;
    SYNC_CLK_10M_O_P      : out   std_logic;
    SYNC_CLK_10M_O_N      : out   std_logic;

--    HOLD                : in    std_logic;
    VER0                  : in    std_logic;
    VER1                  : in    std_logic;
    VER2                  : in    std_logic;
    CLK_62M5_DMTD         : in    std_logic;
    FPGA_GCLK_P           : in    std_logic;
    FPGA_GCLK_N           : in    std_logic;
    MGTREFCLK1_P          : in    std_logic;
    MGTREFCLK1_N          : in    std_logic;
    OE_125M               : out   std_logic;
    MGTREFCLK0_P          : in    std_logic;
    MGTREFCLK0_N          : in    std_logic;
    DAC_LDAC_N            : out   std_logic;
    DAC_SCLK              : out   std_logic;
    DAC_SYNC_N            : out   std_logic;
    DAC_SDI               : out   std_logic;
    DAC_SDO               : in    std_logic;
    DAC_DMTD_LDAC_N       : out   std_logic;
    DAC_DMTD_SCLK         : out   std_logic;
    DAC_DMTD_SYNC_N       : out   std_logic;
    DAC_DMTD_SDI          : out   std_logic;
    DAC_DMTD_SDO          : in    std_logic;
    DELAY_EN              : out   std_logic_vector(0 downto 0);
    DELAY_SCLK            : out   std_logic_vector(0 downto 0);
    DELAY_SLOAD           : out   std_logic_vector(0 downto 0);
    DELAY_SDIN            : out   std_logic_vector(0 downto 0);
    -- DLY0_SE_FB            : in    std_logic;
    -- DLY1_SE_FB            : in    std_logic;
    QSPI_CS               : out   std_logic;
    QSPI_DQ0              : out   std_logic;
    QSPI_DQ1              : in    std_logic;
    --QSPI_DQ2              : in    std_logic
    --QSPI_DQ3              : in    std_logic
    ------------------------------------------
    -- AD9516 SPI
    ------------------------------------------
    PLL_CS                : out   std_logic;
    PLL_REFSEL            : out   std_logic;
    PLL_RESET             : out   std_logic;
    PLL_SCLK              : out   std_logic;
    PLL_SDO               : out   std_logic;
    PLL_SYNC              : out   std_logic;
    PLL_LOCK              : in    std_logic;
    PLL_SDI               : in    std_logic;
    PLL_STAT              : in    std_logic;

    -- 3-state-signals
    onewire_i             : in  std_logic;
    onewire_oen_o         : out std_logic;
    sfp_scl_i             : in  std_logic_vector(g_num_phys-1 downto 0):=(others=>'1');
    sfp_scl_o             : out std_logic_vector(g_num_phys-1 downto 0);
    sfp_sda_i             : in  std_logic_vector(g_num_phys-1 downto 0):=(others=>'1');
    sfp_sda_o             : out std_logic_vector(g_num_phys-1 downto 0);
    sfp_det_i             : in  std_logic_vector(g_num_phys-1 downto 0):=(others=>'1');
    -- timing
    pps_ext_i             : in     std_logic := '0';
    ext_tai_valid_p_i     : in     std_logic := '0';
    ext_tai_i             : in     std_logic_vector(39 downto 0) := (others => '0');
    ext_tai_ready_i       : in     std_logic := '0';
    clk_ext_i             : in     std_logic;
    clk_ext_mul_i         : in     std_logic;
    rst_62m5_n_o          : out    std_logic;
    clk_62m5_o            : out    std_logic;
    pps_csync_o           : out    std_logic;
    tm_time_valid_o       : out    std_logic;
    tm_tai_o              : out    std_logic_vector(39 downto 0);
    tm_cycles_o           : out    std_logic_vector(27 downto 0);
    -- data
    eb_cfg_master_o       : out    t_wishbone_master_out;
    eb_cfg_master_i       : in     t_wishbone_master_in := cc_dummy_master_in;
    eb_wrf_src_o          : out    t_wrf_source_out_array(g_num_phys-1 downto 0);
    eb_wrf_src_i          : in     t_wrf_source_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_src_in);
    eb_wrf_snk_o          : out    t_wrf_sink_out_array(g_num_phys-1 downto 0);
    eb_wrf_snk_i          : in     t_wrf_sink_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_snk_in);
    LED_GREEN_O           : out   std_logic_vector(1 downto 0);
    LED_RED_O             : out   std_logic_vector(1 downto 0)

);
end cute_a7_core;

architecture rtl of cute_a7_core is

    ------------------------------------------------------------------------------
    -- components declaration
    ------------------------------------------------------------------------------
    -- support AD5683
    component cute_a7_serial_dac_arb is
    generic(
        g_invert_sclk    : boolean;
        g_num_data_bits  : integer;
        g_num_extra_bits : integer);
    port(
        clk_i            : in  std_logic;
        rst_n_i          : in  std_logic;
        val_i            : in  std_logic_vector(g_num_data_bits-1 downto 0);
        load_i           : in  std_logic;
        dac_ldac_n_o     : out std_logic;
        dac_clr_n_o      : out std_logic;
        dac_sync_n_o     : out std_logic;
        dac_sclk_o       : out std_logic;
        dac_din_o        : out std_logic);
    end component cute_a7_serial_dac_arb;

    function f_pick_ref_clock_rate (
        g_project_name : string
        ) return integer is
    begin
        return 62500000;
    end f_pick_ref_clock_rate;

    function f_pick_sys_clock_rate (
        g_project_name : string
        ) return integer is
    begin
        return 62500000;
    end f_pick_sys_clock_rate;

    function f_pick_ref_clock_hz (
        g_project_name : string
        ) return integer is
    begin
        return 62500000;
    end f_pick_ref_clock_hz;

    function f_pick_sys_clock_hz (
        g_project_name : string
        ) return integer is
    begin
        return 62500000;
    end f_pick_sys_clock_hz;
    
    function f_pick_ext_clock_rate (
        g_project_name : string
        ) return integer is
    begin
        return 10000000;
    end f_pick_ext_clock_rate;

    component reset_gen
      port (
        clk_i            : in  std_logic;
        rst_button_n_a_i : in  std_logic;
        rst_pll_locked_i : in  std_logic;
        rst_n_o          : out std_logic);
    end component;

    signal VERSION           : std_logic_vector(2 downto 0);
    ------------------------------------------------------------------------------
    -- Constants declaration
    ------------------------------------------------------------------------------
    signal local_reset_n     : std_logic;
    signal pll_reset_n       : std_logic;
    signal rst_aux_n         : std_logic;

    signal clk_gtp_ref0_p_i  : std_logic;
    signal clk_gtp_ref0_n_i  : std_logic;
    signal clk_gtp_ref1_p_i  : std_logic;
    signal clk_gtp_ref1_n_i  : std_logic;

    signal clk_dmtd          : std_logic;
    signal clk_dmtd_i        : std_logic;
    signal clk_pll_dmtd_fb   : std_logic;
    signal clk_pll_dmtd_o    : std_logic;
    signal clk_sys           : std_logic;
    signal clk_ref           : std_logic_vector(g_num_phys-1 downto 0);
    signal clk_ref_locked    : std_logic_vector(g_num_phys-1 downto 0);
    signal clk_serdes        : std_logic;
    signal clk_serdes_i      : std_logic;

    signal flash_spi_sclk_o  : std_logic;
    signal flash_spi_ncs_o   : std_logic;
    signal flash_spi_mosi_o  : std_logic;
    signal flash_spi_miso_i  : std_logic;
    signal dac_dpll_load_p1  : std_logic;
    signal dac_hpll_load_p1  : std_logic;
    signal dac_dpll_data     : std_logic_vector(15 downto 0);
    signal dac_hpll_data     : std_logic_vector(15 downto 0);
    signal dac_dpll_ldac_n_o : std_logic;
    signal dac_dpll_clr_n_o  : std_logic;
    signal dac_dpll_sync_n_o : std_logic;
    signal dac_dpll_sclk_o   : std_logic;
    signal dac_dpll_din_o    : std_logic;
    signal dac_hpll_ldac_n_o : std_logic;
    signal dac_hpll_clr_n_o  : std_logic;
    signal dac_hpll_sync_n_o : std_logic;
    signal dac_hpll_sclk_o   : std_logic;
    signal dac_hpll_din_o    : std_logic;
    signal onewire_in        : std_logic_vector(1 downto 0);
    signal onewire_en        : std_logic_vector(1 downto 0);

    signal uart_txd_o        : std_logic;
    signal uart_rxd_i        : std_logic;
    signal led_act           : std_logic_vector(g_num_phys-1 downto 0);
    signal led_link          : std_logic_vector(g_num_phys-1 downto 0);
    signal pps_p             : std_logic;
    signal pps_led           : std_logic;
    signal pps_csync         : std_logic;
    signal pps_valid         : std_logic;
    signal pps_unmask        : std_logic;
    signal link_ok           : std_logic_vector(g_num_phys-1 downto 0);
    signal sync_clk_10m_p    : std_logic;
    signal sync_clk_10m_n    : std_logic;
    signal tm_link_up        : std_logic_vector(g_num_phys-1 downto 0);
    signal tm_time_valid     : std_logic;
    signal tm_tai            : std_logic_vector(39 downto 0);
    signal tm_cycles         : std_logic_vector(27 downto 0);

    signal phy8_to_wrc       : t_phy_8bits_to_wrc_array(g_num_phys-1 downto 0);
    signal phy8_from_wrc     : t_phy_8bits_from_wrc_array(g_num_phys-1 downto 0);
    signal phy16_to_wrc      : t_phy_16bits_to_wrc_array(g_num_phys-1 downto 0);
    signal phy16_from_wrc    : t_phy_16bits_from_wrc_array(g_num_phys-1 downto 0);
    
    signal delay_en_o        : std_logic;
    signal delay_sclk_o      : std_logic;
    signal delay_sdin_o      : std_logic;
    signal delay_sload_o     : std_logic;
    
    signal sync_data_o_p     : std_logic_vector(1 downto 0);
    signal sync_data_o_n     : std_logic_vector(1 downto 0);
    signal sma_slave_in      : t_wishbone_slave_in;
    signal sma_slave_out     : t_wishbone_slave_out;
    signal wb_slave_in       : t_wishbone_slave_in;
    signal wb_slave_out      : t_wishbone_slave_out;

    signal sfp_txp_o         : std_logic_vector(g_num_phys-1 downto 0);
    signal sfp_txn_o         : std_logic_vector(g_num_phys-1 downto 0);
    signal sfp_rxp_i         : std_logic_vector(g_num_phys-1 downto 0);
    signal sfp_rxn_i         : std_logic_vector(g_num_phys-1 downto 0);
    signal sfp_tx_fault      : std_logic_vector(g_num_phys-1 downto 0);
    signal sfp_los           : std_logic_vector(g_num_phys-1 downto 0);
    signal sfp_tx_disable    : std_logic_vector(g_num_phys-1 downto 0);

    signal aux_master_out    : t_wishbone_master_out;
    signal aux_master_in     : t_wishbone_master_in;
    signal aux1_master_out   : t_wishbone_master_out;
    signal aux1_master_in    : t_wishbone_master_in;
    signal wb_eth_master_out : t_wishbone_master_out;
    signal wb_eth_master_in  : t_wishbone_master_in;
    
    signal eb_cfg_master_out : t_wishbone_master_out;
    signal eb_cfg_master_in  : t_wishbone_master_in := cc_dummy_master_in;
    signal wrf_src_out       : t_wrf_source_out_array(g_num_phys-1 downto 0);
    signal wrf_src_in        : t_wrf_source_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_src_in);
    signal wrf_snk_out       : t_wrf_sink_out_array(g_num_phys-1 downto 0);
    signal wrf_snk_in        : t_wrf_sink_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_snk_in);
    signal eb_wrf_src_out    : t_wrf_source_out_array(g_num_phys-1 downto 0);
    signal eb_wrf_src_in     : t_wrf_source_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_src_in);
    signal eb_wrf_snk_out    : t_wrf_sink_out_array(g_num_phys-1 downto 0);
    signal eb_wrf_snk_in     : t_wrf_sink_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_snk_in);

    signal clk_ext              : std_logic:='0';
    signal clk_ext_mul          : std_logic:='0';
    signal clk_ext_mul_locked   : std_logic:='0';
    signal clk_ext_stopped      : std_logic:='0';
    signal clk_ext_locked_i     : std_logic:='0';
    signal clk_ext_stopped_i    : std_logic:='0';
    signal clk_ext_rst          : std_logic:='0';
    signal ext_pll_mosi         : std_logic:='0';
    signal ext_pll_miso         : std_logic:='0';
    signal ext_pll_sck          : std_logic:='0';
    signal ext_pll_cs_n         : std_logic:='0';
    signal ext_pll_sync_n       : std_logic:='0';
    signal ext_pll_reset_n      : std_logic:='0';

    signal ppsin_term           : std_logic;
    signal todin_term           : std_logic;

begin

    u_reset_gen: reset_gen
    port map (
        clk_i            => clk_dmtd,
        rst_button_n_a_i => RESET_N,
        rst_pll_locked_i => '1',
        rst_n_o          => pll_reset_n
    );

    local_reset_n      <= pll_reset_n;

-----------------------------------------------------------------------------
-- The WR PTP core with optional fabric interface attached
-----------------------------------------------------------------------------
    cmp_board_cute_a7 : xwrc_board_cute_a7
    generic map (
        g_num_phys                  => g_num_phys,
        g_aux_sdb                   => c_sma_config_sdb,
        g_aux1_sdb                  => g_aux1_sdb,
        g_etherbone_sdb             => g_etherbone_sdb,
        g_fabric_iface              => g_fabric_iface,
        g_dpram_initf               => g_dpram_initf,
        g_with_10M_output           => g_with_10M_output,
        g_with_external_clock_input => g_with_external_clock_input,
        g_board_name                => g_board_name,
        g_flash_secsz_kb            => 64,        -- default for N25Q128
        g_flash_sdbfs_baddr         => 16#760000#, -- default for N25Q128
        g_phys_uart                 => TRUE,
        g_virtual_uart              => FALSE,
        g_ep_rxbuf_size             => 1024,
        g_tx_runt_padding           => TRUE,
        g_dpram_size                => 131072/4,
        g_softpll_enable_debugger   => FALSE,
        g_pcs_16bit                 => TRUE,
        g_interface_mode            => PIPELINED,
        g_address_granularity       => BYTE,
        g_ref_clock_rate            => f_pick_ref_clock_rate(g_project_name),
        g_sys_clock_rate            => f_pick_sys_clock_rate(g_project_name),
        g_ref_clock_hz              => f_pick_ref_clock_hz(g_project_name),
        g_sys_clock_hz              => f_pick_sys_clock_hz(g_project_name),
        g_ext_clock_rate            => f_pick_ext_clock_rate(g_project_name)
    )
    port map (
        clk_sys_i            => clk_sys,
        clk_dmtd_i           => clk_dmtd,
        clk_ref_i            => clk_ref(0),
        clk_ext_i            => clk_ext,
        clk_ext_mul_i        => clk_ext_mul,
        clk_ext_mul_locked_i => clk_ext_mul_locked,
        clk_ext_stopped_i    => clk_ext_stopped,
        clk_ext_rst_o        => clk_ext_rst,
        pps_ext_i            => pps_ext_i,
        ppsin_term_o         => ppsin_term,
        todin_term_o         => todin_term,
        ext_tai_valid_p_i    => ext_tai_valid_p_i,
        ext_tai_i            => ext_tai_i,
        ext_tai_ready_i      => ext_tai_ready_i,
        rst_n_i              => local_reset_n,
        dac_hpll_load_p1_o   => dac_hpll_load_p1,
        dac_hpll_data_o      => dac_hpll_data,
        dac_dpll_load_p1_o   => dac_dpll_load_p1,
        dac_dpll_data_o      => dac_dpll_data,
        phy16_o              => phy16_from_wrc,
        phy16_i              => phy16_to_wrc,
        scl_o                => open,
        scl_i                => '0',
        sda_o                => open,
        sda_i                => '0',
        sfp_scl_o            => sfp_scl_o,
        sfp_scl_i            => sfp_scl_i,
        sfp_sda_o            => sfp_sda_o,
        sfp_sda_i            => sfp_sda_i,
        sfp_det_i            => sfp_det_i,
        flash_spi_sclk_o     => flash_spi_sclk_o,
        flash_spi_ncs_o      => flash_spi_ncs_o,
        flash_spi_mosi_o     => flash_spi_mosi_o,
        flash_spi_miso_i     => flash_spi_miso_i,
        uart_rxd_i           => uart_rxd_i,
        uart_txd_o           => uart_txd_o,
        owr_pwren_o          => open,
        owr_en_o             => onewire_en,
        owr_i                => onewire_in,
        pll_mosi_o           => open,
        pll_miso_i           => '0',
        pll_sck_o            => open,
        pll_cs_n_o           => open,
        pll_sync_n_o         => open,
        pll_reset_n_o        => open,
        ext_pll_mosi_o       => ext_pll_mosi,
        ext_pll_miso_i       => ext_pll_miso,
        ext_pll_sck_o        => ext_pll_sck,
        ext_pll_cs_n_o       => ext_pll_cs_n,
        ext_pll_sync_n_o     => ext_pll_sync_n,
        ext_pll_reset_n_o    => ext_pll_reset_n,
        wb_slave_i           => wb_slave_in,
        wb_slave_o           => wb_slave_out,
        aux_master_o         => aux_master_out,
        aux_master_i         => aux_master_in,
        aux1_master_o        => aux1_master_out,
        aux1_master_i        => aux1_master_in,
        eb_cfg_master_i      => eb_cfg_master_in,
        eb_cfg_master_o      => eb_cfg_master_out,
        wrf_src_o            => wrf_src_out,
        wrf_src_i            => wrf_src_in,
        wrf_snk_o            => wrf_snk_out,
        wrf_snk_i            => wrf_snk_in,
        eb_wrf_src_o         => eb_wrf_src_out,
        eb_wrf_src_i         => eb_wrf_src_in,
        eb_wrf_snk_o         => eb_wrf_snk_out,
        eb_wrf_snk_i         => eb_wrf_snk_in,
        wb_eth_master_o      => wb_eth_master_out,
        wb_eth_master_i      => wb_eth_master_in,
        rst_aux_n_o          => rst_aux_n,
        aux_diag_i           => (others => (others => '0')),
        aux_diag_o           => open,
        tm_dac_value_o       => open,
        tm_dac_wr_o          => open,
        tm_clk_aux_lock_en_i => (others => '0'),
        tm_clk_aux_locked_o  => open,
        timestamps_o         => open,
        timestamps_ack_i     => (others=>'1'),
        abscal_txts_o        => open,
        abscal_rxts_o        => open,
        fc_tx_pause_req_i    => (others => '0'),
        fc_tx_pause_delay_i  => (others => '0'),
        fc_tx_pause_ready_o  => open,
        tm_link_up_o         => tm_link_up,
        tm_time_valid_o      => tm_time_valid,
        tm_tai_o             => tm_tai,
        tm_cycles_o          => tm_cycles,
        led_act_o            => led_act(g_num_phys-1 downto 0),
        led_link_o           => led_link(g_num_phys-1 downto 0),
        btn1_i               => '1',
        btn2_i               => '1',
        pps_csync_o          => pps_csync,
        pps_p_o              => pps_p,
        pps_led_o            => pps_led,
        pps_valid_o          => pps_valid,
        pps_unmask_o         => pps_unmask,
        sync_clk_10m_o_p     => sync_clk_10m_p,
        sync_clk_10m_o_n     => sync_clk_10m_n,
        link_ok_o            => link_ok
    );

    -- port 0 <-> port 1
    wrf_src_in(0) <= wrf_snk_out(1);
    wrf_snk_in(0) <= wrf_src_out(1);
    wrf_src_in(1) <= wrf_snk_out(0);
    wrf_snk_in(1) <= wrf_src_out(0);

    cmp_xwrc_platform : xwrc_platform_xilinx
    generic map (
        g_fpga_family               => "artix7",
        g_use_default_plls          => FALSE,
        g_gtrefclk_src              => g_gtrefclk_src,
        g_ref_clk_sel               => g_ref_clk_sel,
        g_with_external_clock_input => g_with_external_clock_input,
        g_num_phys                  => g_num_phys,
        g_simulation                => 0)
    port map (
        areset_n_i            => local_reset_n,
        clk_ext_i             => clk_ext_i,
        clk_gtp_ref0_p_i      => clk_gtp_ref0_p_i,
        clk_gtp_ref0_n_i      => clk_gtp_ref0_n_i,
        clk_gtp_ref1_p_i      => clk_gtp_ref1_p_i,
        clk_gtp_ref1_n_i      => clk_gtp_ref1_n_i,
        clk_gtp_ref0_locked_i => '1',
        clk_gtp_ref1_locked_i => '1',
        clk_125m_pllref_i     => '0',
        sfp_txp_o             => sfp_txp_o,
        sfp_txn_o             => sfp_txn_o,
        sfp_rxp_i             => sfp_rxp_i,
        sfp_rxn_i             => sfp_rxn_i,
        sfp_tx_fault_i        => sfp_tx_fault,
        sfp_los_i             => sfp_los,
        sfp_tx_disable_o      => sfp_tx_disable,
        clk_sys_i             => clk_ref(0),
        clk_sys_o             => clk_sys,
        clk_ref_o             => clk_ref,
        clk_ref_locked_o      => clk_ref_locked,
        clk_dmtd_i            => clk_dmtd_i,
        clk_dmtd_o            => clk_dmtd,
        clk_ext_o             => clk_ext,
        clk_ext_mul_i         => clk_ext_mul_i,
        clk_ext_mul_o         => clk_ext_mul,
        clk_ext_locked_i      => clk_ext_locked_i,
        clk_ext_mul_locked_o  => clk_ext_mul_locked,
        clk_ext_stopped_i     => clk_ext_stopped_i,
        clk_ext_mul_stopped_o => clk_ext_stopped,
        clk_ext_rst_i         => clk_ext_rst,
        phy16_o               => phy16_to_wrc,
        phy16_i               => phy16_from_wrc
    );

    U_Main_DAC : cute_a7_serial_dac_arb
    generic map (
        g_invert_sclk    => FALSE,
        g_num_data_bits  => 16,
        g_num_extra_bits => 8)
    port map (
        clk_i         => clk_sys,
        rst_n_i       => local_reset_n,
        val_i         => dac_dpll_data,
        load_i        => dac_dpll_load_p1,
        dac_sync_n_o  => dac_dpll_sync_n_o,
        dac_ldac_n_o  => dac_dpll_ldac_n_o,
        dac_clr_n_o   => dac_dpll_clr_n_o,
        dac_sclk_o    => dac_dpll_sclk_o,
        dac_din_o     => dac_dpll_din_o
    );

    U_DMTD_DAC : cute_a7_serial_dac_arb
    generic map (
        g_invert_sclk    => FALSE,
        g_num_data_bits  => 16,
        g_num_extra_bits => 8)
    port map (
        clk_i         => clk_sys,
        rst_n_i       => local_reset_n,
        val_i         => dac_hpll_data,
        load_i        => dac_hpll_load_p1,
        dac_sync_n_o  => dac_hpll_sync_n_o,
        dac_ldac_n_o  => dac_hpll_ldac_n_o,
        dac_clr_n_o   => dac_hpll_clr_n_o,
        dac_sclk_o    => dac_hpll_sclk_o,
        dac_din_o     => dac_hpll_din_o
    );

    U_SMA_CTRL: xwr_sma_config
    generic map(
        g_interface_mode      => PIPELINED,
        g_address_granularity => BYTE
    )
    port map(
        rst_n_i         => local_reset_n,
        clk_sys_i       => clk_sys,

        clk_serdes_i    => clk_serdes_i,
        pps_csync_i     => pps_csync,
        pps_valid_i     => pps_unmask,
        tm_tai_i        => tm_tai,
        
        sync_data_o_p   => sync_data_o_p,
        sync_data_o_n   => sync_data_o_n,

        fdly_en_o       => delay_en_o,
        fdly_sload_o    => delay_sload_o,
        fdly_sdin_o     => delay_sdin_o,
        fdly_sclk_o     => delay_sclk_o,

        slave_i         => sma_slave_in,
        slave_o         => sma_slave_out
    );
    sma_slave_in   <= aux_master_out;
    aux_master_in  <= sma_slave_out;
    SYNC_CLK_10M_O_P <= sync_data_o_p(0);
    SYNC_CLK_10M_O_N <= sync_data_o_n(0);
    PPS_O_P <= sync_data_o_p(1);
    PPS_O_N <= sync_data_o_n(1);

    DELAY_EN(0)    <= delay_en_o;
    DELAY_SCLK(0)  <= delay_sclk_o;
    DELAY_SDIN(0)  <= delay_sdin_o;
    DELAY_SLOAD(0) <= delay_sload_o;

    VERSION    <= VER2 & VER1 & VER0;
    OE_125M    <= '0';

    LED_GREEN_O(0) <= pps_valid when led_link(0) = '1' else '0';
    LED_GREEN_O(1) <= tm_time_valid when led_link(1) = '1' else '0';
    LED_RED_O(0)   <= led_act(0);
    LED_RED_O(1)   <= led_act(1);

    clk_gtp_ref0_p_i     <= MGTREFCLK0_P;
    clk_gtp_ref0_n_i     <= MGTREFCLK0_N;
    clk_gtp_ref1_p_i     <= MGTREFCLK1_P;
    clk_gtp_ref1_n_i     <= MGTREFCLK1_N;

    SFP_RATE_SELECT_O    <= (others=>'1');
    SFP_TX_O_P           <= sfp_txp_o;
    SFP_TX_O_N           <= sfp_txn_o;
    SFP_TX_DISABLE_O     <= sfp_tx_disable;
    sfp_rxp_i            <= SFP_RX_I_P;
    sfp_rxn_i            <= SFP_RX_I_N;
    sfp_tx_fault         <= SFP_FAULT_I;
    sfp_los              <= SFP_LOS_I;

    UART_TX_O            <= uart_txd_o;
    uart_rxd_i           <= UART_RX_I;

    DAC_SYNC_N           <= dac_dpll_sync_n_o;
    DAC_LDAC_N           <= dac_dpll_ldac_n_o;
    DAC_SCLK             <= dac_dpll_sclk_o;
    DAC_SDI              <= dac_dpll_din_o;
    DAC_DMTD_SYNC_N      <= dac_hpll_sync_n_o;
    DAC_DMTD_LDAC_N      <= dac_hpll_ldac_n_o;
    DAC_DMTD_SCLK        <= dac_hpll_sclk_o;
    DAC_DMTD_SDI         <= dac_hpll_din_o;

    QSPI_CS              <= flash_spi_ncs_o;
    QSPI_DQ0             <= flash_spi_mosi_o;
    flash_spi_miso_i     <= QSPI_DQ1;

    cmp_clk_dmtd_i : IBUFG
    port map (
        O => clk_dmtd_i,
        I => CLK_62M5_DMTD);

    cmp_clk_serdes : IBUFGDS
    generic map (
        DIFF_TERM    => true,     -- Differential Termination
        IBUF_LOW_PWR => false,    -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
        IOSTANDARD   => "DEFAULT"
    )
    port map (
        O  => clk_serdes,
        I  => FPGA_GCLK_P,
        IB => FPGA_GCLK_N
    );

    cmp_clk_serdes_buf_i : BUFG
    port map (
      O => clk_serdes_i,
      I => clk_serdes
    );

    PLL_RESET            <= pll_reset_n;
    PLL_REFSEL           <= '0'; -- ref1 (signal low) , ref2 (signal high)
    PLL_SYNC             <= '1';
    cmp_pll_ctrl: wr_pll_ctrl
    generic map (
        g_project_name => g_project_name,
        g_spi_clk_freq => x"00000004" -- 1 for 25M, 4 for 62.5M
    )
    port map (
        clk_i        => clk_dmtd,
        rst_n_i      => pll_reset_n,
        pll_lock_i   => PLL_LOCK,
        pll_status_i => PLL_STAT,
        pll_cs_n_o   => PLL_CS,
        pll_sck_o    => PLL_SCLK,
        pll_mosi_o   => PLL_SDO,
        pll_miso_i   => PLL_SDI,
        -- spi controller status
        done_o       => open
    );

    rst_62m5_n_o         <= rst_aux_n;
    clk_62m5_o           <= clk_sys;

    pps_csync_o          <= pps_csync;
    tm_time_valid_o      <= pps_unmask;
    tm_tai_o             <= tm_tai;
    tm_cycles_o          <= tm_cycles;

    eb_cfg_master_in     <= eb_cfg_master_i;
    eb_wrf_src_in        <= eb_wrf_src_i;
    eb_wrf_snk_in        <= eb_wrf_snk_i;
    eb_cfg_master_o      <= eb_cfg_master_out;
    eb_wrf_src_o         <= eb_wrf_src_out;
    eb_wrf_snk_o         <= eb_wrf_snk_out;

    onewire_oen_o        <= onewire_en(0);
    onewire_in(0)        <= onewire_i;
    onewire_in(1)        <= '1';

end rtl;
