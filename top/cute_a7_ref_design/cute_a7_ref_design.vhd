-------------------------------------------------------------------------------
-- Title      : WRPC reference design for CUTE-WR-A7
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : cute_a7_ref_design.vhd
-- Author(s)  : Hongming Li <lihm.thu@foxmail.com>
--              Grzegorz Daniluk <grzegorz.daniluk@cern.ch>
-- Company    : DEP, Tsinghua Univ.
--              CERN
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top-level file for the WRPC reference design on the CUTE-WR-A7.
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

entity cute_a7_ref_design is
generic(
  -- project name, NORMAL
    g_project_name : string := "NORMAL";
    g_num_phys : integer := 2
);
port(
--    SFP_RATE_SELECT_O     : out   std_logic_vector(g_num_phys-1 downto 0);
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
    LOCK                  : out   std_logic;

    PPS_O_P               : out   std_logic;
    PPS_O_N               : out   std_logic;
    SYNC_CLK_10M_O_P      : out   std_logic;
    SYNC_CLK_10M_O_N      : out   std_logic;

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
    ONE_WIRE              : inout std_logic;
    SFP_MOD_DEF0_I        : in    std_logic_vector(1 downto 0);
    SFP_MOD_DEF1_IO       : inout std_logic_vector(1 downto 0);
    SFP_MOD_DEF2_IO       : inout std_logic_vector(1 downto 0);

    -- RESV_I                : in     std_logic;
    -- RESV_O                : out    std_logic;
    LED_GREEN_O           : out   std_logic_vector(1 downto 0);
    LED_RED_O             : out   std_logic_vector(1 downto 0)

);
end cute_a7_ref_design;

architecture rtl of cute_a7_ref_design is

    signal eb_cfg_master_out    : t_wishbone_master_out;
    signal eb_wrf_src_out       : t_wrf_source_out_array(2-1 downto 0);
    signal eb_wrf_snk_out       : t_wrf_sink_out_array(2-1 downto 0);
    signal eb_cfg_master_in     : t_wishbone_master_in:=c_DUMMY_WB_MASTER_IN;
    signal eb_wrf_src_in        : t_wrf_source_in_array(2-1 downto 0):=(others=>c_dummy_src_in);
    signal eb_wrf_snk_in        : t_wrf_sink_in_array(2-1 downto 0):=(others=>c_dummy_snk_in);

    signal rst_sys_n            : STD_LOGIC;
    signal clk_sys              : STD_LOGIC;
    signal pps_csync            : STD_LOGIC;
    signal tm_time_valid        : STD_LOGIC;
    signal tm_tai               : STD_LOGIC_VECTOR ( 39 downto 0 );
    signal tm_cycles            : STD_LOGIC_VECTOR ( 27 downto 0 );
    signal onewire_i            : std_logic;
    signal onewire_oen_o        : std_logic;
    signal clk_ext_i            : std_logic:='0';
    signal pps_ext_i            : std_logic:='0';
    signal clk_ext_mul_i        : std_logic:='0';
    signal sfp_scl_i            : std_logic_vector(2-1 downto 0);
    signal sfp_scl_o            : std_logic_vector(2-1 downto 0);
    signal sfp_sda_i            : std_logic_vector(2-1 downto 0);
    signal sfp_sda_o            : std_logic_vector(2-1 downto 0);
    signal sfp_det_i            : std_logic_vector(2-1 downto 0);

    signal clkfb                : std_logic;
    signal clk_125M             : std_logic;
    signal clk_125M_bufg        : std_logic;
    signal dcm_locked           : std_logic;

begin

    u_cute_a7_core: entity work.cute_a7_core
    generic map (
        g_project_name                 =>  "NORMAL",
        g_dpram_initf                  =>  "../../../../bin/wrpc/wrc_phy16.bram",
        g_board_name                   =>  "NM01",
        g_gtrefclk_src                 =>  (others=>'1'),
        g_ref_clk_sel                  =>  (others=>'1'),
        g_num_output_clks              =>  2,
        g_with_10M_output              =>  false,
        g_with_external_clock_input    =>  false,
        g_fabric_iface                 =>  ETHERBONE,
        g_etherbone_sdb                =>  c_etherbone_sdb,
        g_aux1_sdb                     =>  c_null_sdb,
        g_num_phys                     =>  2        
    )
    port map(
        VER0                     => VER0,
        VER1                     => VER1,
        VER2                     => VER2,
        CLK_62M5_DMTD            => CLK_62M5_DMTD,
        FPGA_GCLK_P              => FPGA_GCLK_P,
        FPGA_GCLK_N              => FPGA_GCLK_N,
        MGTREFCLK1_P             => MGTREFCLK1_P,
        MGTREFCLK1_N             => MGTREFCLK1_N,
        OE_125M                  => OE_125M,
        MGTREFCLK0_P             => MGTREFCLK0_P,
        MGTREFCLK0_N             => MGTREFCLK0_N,
        DAC_LDAC_N               => DAC_LDAC_N,
        DAC_SCLK                 => DAC_SCLK,
        DAC_SYNC_N               => DAC_SYNC_N,
        DAC_SDI                  => DAC_SDI,
        DAC_SDO                  => DAC_SDO,
        DAC_DMTD_LDAC_N          => DAC_DMTD_LDAC_N,
        DAC_DMTD_SCLK            => DAC_DMTD_SCLK,
        DAC_DMTD_SYNC_N          => DAC_DMTD_SYNC_N,
        DAC_DMTD_SDI             => DAC_DMTD_SDI,
        DAC_DMTD_SDO             => DAC_DMTD_SDO,
        SFP_TX_DISABLE_O         => SFP_TX_DISABLE_O,
        SFP_TX_O_N               => SFP_TX_O_N,
        SFP_TX_O_P               => SFP_TX_O_P,
        SFP_RX_I_N               => SFP_RX_I_N,
        SFP_RX_I_P               => SFP_RX_I_P,
        SFP_FAULT_I              => SFP_FAULT_I,
        SFP_LOS_I                => SFP_LOS_I,
        LED_GREEN_O              => LED_GREEN_O,
        LED_RED_O                => LED_RED_O,
        UART_RX_I                => UART_RX_I,
        UART_TX_O                => UART_TX_O,
        RESET_N                  => RESET_N,
        SYNC_CLK_10M_O_N         => SYNC_CLK_10M_O_N,
        SYNC_CLK_10M_O_P         => SYNC_CLK_10M_O_P,
        PPS_O_N                  => PPS_O_N,
        PPS_O_P                  => PPS_O_P,
        DELAY_EN                 => DELAY_EN,
        DELAY_SCLK               => DELAY_SCLK,
        DELAY_SLOAD              => DELAY_SLOAD,
        DELAY_SDIN               => DELAY_SDIN,
        QSPI_CS                  => QSPI_CS,
        QSPI_DQ0                 => QSPI_DQ0,
        QSPI_DQ1                 => QSPI_DQ1,
        PLL_CS                   => PLL_CS,
        PLL_REFSEL               => PLL_REFSEL,
        PLL_RESET                => PLL_RESET,
        PLL_SCLK                 => PLL_SCLK,
        PLL_SDO                  => PLL_SDO,
        PLL_SYNC                 => PLL_SYNC,
        PLL_LOCK                 => PLL_LOCK,
        PLL_SDI                  => PLL_SDI,
        PLL_STAT                 => PLL_STAT,
        clk_ext_i                => clk_ext_i,
        pps_ext_i                => pps_ext_i,
        clk_ext_mul_i            => clk_ext_mul_i,
        onewire_i                => onewire_i,
        onewire_oen_o            => onewire_oen_o,
        sfp_scl_i                => sfp_scl_i,
        sfp_scl_o                => sfp_scl_o,
        sfp_sda_i                => sfp_sda_i,
        sfp_sda_o                => sfp_sda_o,
        sfp_det_i                => sfp_det_i,
        rst_62m5_n_o             => rst_sys_n,
        clk_62m5_o               => clk_sys,
        pps_csync_o              => pps_csync,
        tm_time_valid_o          => tm_time_valid,
        tm_tai_o                 => tm_tai,
        tm_cycles_o              => tm_cycles,
        ext_tai_valid_p_i        => '0',
        ext_tai_i                => (others=>'0'),
        ext_tai_ready_i          => '0',
        eb_cfg_master_o          => eb_cfg_master_out,
        eb_cfg_master_i          => eb_cfg_master_in,
        eb_wrf_src_o             => eb_wrf_src_out,
        eb_wrf_src_i             => eb_wrf_src_in,
        eb_wrf_snk_o             => eb_wrf_snk_out,
        eb_wrf_snk_i             => eb_wrf_snk_in
    );

    mmcm: MMCME2_BASE
    generic map(
        clkin1_period   => 16.0,
        clkfbout_mult_f => 16.0,
        clkout1_divide  => integer(1000.0 / 125.00)
    )
    port map(
        clkin1   => clk_sys,
        clkfbin  => clkfb,
        clkfbout => clkfb,
        clkout1  => clk_125M,
        clkout2  => open,
        clkout3  => open,
        locked   => dcm_locked,
        rst      => '0',
        pwrdwn   => '0'
    );
    
    bufgclk_125m: BUFG port map(
        i => clk_125M,
        o => clk_125M_bufg
    );

    gen_SFP_I2C: for i in 0 to g_num_phys-1 generate

        SFP_MOD_DEF1_IO(i) <= '0' when sfp_scl_o(i) = '0' else 'Z';
        SFP_MOD_DEF2_IO(i) <= '0' when sfp_sda_o(i) = '0' else 'Z';
        sfp_scl_i(i) <= SFP_MOD_DEF1_IO(i);
        sfp_sda_i(i) <= SFP_MOD_DEF2_IO(i);
        sfp_det_i(i) <= SFP_MOD_DEF0_I(i);

    end generate gen_SFP_I2C;

    ONE_WIRE <= '0' when onewire_oen_o = '1' else 'Z';
    onewire_i <= ONE_WIRE;

    LOCK <= tm_time_valid;
    
end rtl;
