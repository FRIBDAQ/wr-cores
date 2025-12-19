-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2011 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : White Rabbit Softcore PLL (new generation) - SoftPLL-ng
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : wr_softpll_ng.vhd
-- Author     : Tomasz Włostowski
-- Company    : CERN BE-CO-HT
-- Created    : 2011-01-29
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description:
--
-- Unstruct'ized version of xwr_softpll_ng.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;
use work.wishbone_pkg.all;
use work.softpll_pkg.all;
use work.spll_wbgen2_pkg.all;

entity wr_softpll_ng is
  generic(
-- Number of bits in phase tags produced by DDMTDs.
-- Must be large enough to cover at least a hundred of DDMTD periods to ensure
-- correct operation of the SoftPLL software servo algorithm - that
-- means, for a typical DMTD frequency offset N=16384, there number of tag bits
-- should be log2(N) + 7 == 21. Note: the value must match the TAG_BITS constant
-- in spll_defs.h file!
    g_tag_bits : integer;
    g_dac_bits : integer := 16;

-- These two are obvious:
    g_num_ref_inputs : integer := 1;
    g_num_outputs    : integer := 1;
-- Number of external channels (e.g. 2 for WR Switch for regular and low-jitter
-- ext channel)
    g_num_exts       : integer := 1;

-- When true, an additional FIFO is instantiated, providing a realtime record
-- of user-selectable SoftPLL parameters (e.g. tag values, phase error, DAC drive).
-- These values can be read by "spll_dbg_proxy" daemon for further analysis.
    g_with_debug_fifo : boolean := false;

-- When true, DDMTD inputs are reversed (so that the DDMTD offset clocks is
-- being sampled by the measured clock). This is functionally equivalent to
-- "direct" operation, but may improve FPGA timing/routability.
    g_reverse_dmtds : boolean := true;

-- Divides the DDMTD clock inputs by 2, removing the "CLOCK_DEDICATED_ROUTE"
-- errors under ISE tools, at the cost of bandwidth reduction. Advanced option
-- use with care.
    g_divide_input_by_2 : boolean := false;

    g_with_jitter_stats_regs : boolean := false;

    g_ref_clock_rate : integer := 125_000_000;
    g_ext_clock_rate : integer :=  10_000_000;
    g_sys_clock_rate: integer :=   62_500_000;

    g_use_sampled_ref_clocks : boolean := false;
    g_direct_tag             : boolean := false;

    g_aux_config : t_softpll_channels_config_array := c_softpll_default_channels_config;

    g_interface_mode      : t_wishbone_interface_mode      := PIPELINED;
    g_address_granularity : t_wishbone_address_granularity := WORD
    );

  port(
    clk_sys_i    : in std_logic;
    rst_sys_n_i  : in std_logic;
    rst_ref_n_i  : in std_logic;
    rst_ext_n_i  : in std_logic;
    rst_dmtd_n_i : in std_logic;

-- Reference inputs (i.e. the RX clocks recovered by the PHYs)
    clk_ref_i : in std_logic_vector(g_num_ref_inputs-1 downto 0);

-- Reference inputs (i.e. the RX clocks recovered by the PHYs), externally sampled
    clk_ref_sampled_i : in std_logic_vector(g_num_ref_inputs-1 downto 0);

-- Output clocks (i.e. main or auxillary oscillator)
-- Note: clk_out_i(0) must be always connected to the primary board's oscillator
-- (i.e. the one driving the PTP and Ethernet PHY) to ensure correct operation
-- of the PTP core.
    clk_out_i : in std_logic_vector(g_num_outputs-1 downto 0);

-- DMTD Offset clock
    clk_dmtd_i : in std_logic;
    clk_dmtd_over_i : in std_logic := '0';

-- External reference clock (e.g. 10 MHz from Cesium/GPSDO). Used only if
-- g_num_exts > 0
    clk_ext_i : in std_logic := '0';

-- External clock, multiplied to 125 MHz using the FPGA's PLL
    clk_ext_mul_i        : in std_logic_vector(f_nonzero_vector(g_num_exts)-1 downto 0) := (others => '0');
    clk_ext_mul_locked_i : in std_logic := '1';
    clk_ext_stopped_i : in std_logic := '0';
    clk_ext_rst_o : out std_logic;

-- External clock sync/alignment signal. SoftPLL will align clk_ext_i/clk_fb_i(0)
-- to match the edges immediately following the rising edge in sync_p_i.
    pps_csync_p1_i : in std_logic;
    pps_ext_a_i    : in std_logic;

    --  Direct tag input (Phase interpolator (PI) value from transceiver).
    --  Used only if g_direct_tag is true.
    direct_tag0_i       : in std_logic_vector(23 downto 0);
    direct_tag0_valid_i : in std_logic;

-- DMTD oscillator drive
    dac_dmtd_data_o : out std_logic_vector(g_dac_bits-1 downto 0);
-- When HI, load the data from dac_dmtd_data_o to the DAC.
    dac_dmtd_load_o : out std_logic;

-- Output channel DAC value
    dac_out_data_o : out std_logic_vector(g_dac_bits-1 downto 0);
-- Output channel select (0 = Output channel 0, 1 == OC 1, etc...)
    dac_out_sel_o  : out std_logic_vector(3 downto 0);
    dac_out_load_o : out std_logic;

-- Output enable input: when HI, enables locking the output(s)
-- to the reference clock(s)
    out_enable_i : in  std_logic_vector(g_num_outputs-1 downto 0);
-- When HI, the respective clock output is locked.
    out_locked_o : out std_logic_vector(g_num_outputs-1 downto 0);

    wb_adr_i   : in  std_logic_vector(c_wishbone_address_width-1 downto 0);
    wb_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0);
    wb_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);
    wb_cyc_i   : in  std_logic;
    wb_sel_i   : in  std_logic_vector(c_wishbone_data_width/8-1 downto 0);
    wb_stb_i   : in  std_logic;
    wb_we_i    : in  std_logic;
    wb_ack_o   : out std_logic;
    wb_stall_o : out std_logic;
    irq_o      : out std_logic;

    host_wb_i : in  t_wishbone_slave_in;
    host_wb_o : out t_wishbone_slave_out;

-- Debug FIFO readout interrupt
    dbg_fifo_irq_o : out std_logic
    );
end wr_softpll_ng;

architecture rtl of wr_softpll_ng is

  signal wb_err, wb_rty : std_logic;
begin  -- behavioral

  U_Wrapped_Softpll : entity work.xwr_softpll_ng
    generic map (
      g_tag_bits             => g_tag_bits,
      g_dac_bits             => g_dac_bits,
      g_interface_mode       => g_interface_mode,
      g_address_granularity  => g_address_granularity,
      g_num_ref_inputs       => g_num_ref_inputs,
      g_num_outputs          => g_num_outputs,
      g_num_exts             => g_num_exts,
      g_with_debug_fifo      => g_with_debug_fifo,
      g_reverse_dmtds        => g_reverse_dmtds,
      g_divide_input_by_2    => g_divide_input_by_2,
      g_use_sampled_ref_clocks => g_use_sampled_ref_clocks,
      g_direct_tag           => g_direct_tag,
      g_aux_config => g_aux_config,
      g_ref_clock_rate  => g_ref_clock_rate,
      g_ext_clock_rate  => g_ext_clock_rate
      )
    port map (
      clk_sys_i       => clk_sys_i,
      rst_sys_n_i     => rst_sys_n_i,
      rst_ref_n_i     => rst_ref_n_i,
      rst_ext_n_i     => rst_ext_n_i,
      rst_dmtd_n_i    => rst_dmtd_n_i,
      clk_ref_i       => clk_ref_i,
      clk_ref_sampled_i => clk_ref_sampled_i,
      clk_out_i       => clk_out_i,
      clk_dmtd_i      => clk_dmtd_i,
      clk_dmtd_over_i => clk_dmtd_over_i,
      clk_ext_i       => clk_ext_i,
      clk_ext_mul_i   => clk_ext_mul_i,
      clk_ext_mul_locked_i => clk_ext_mul_locked_i,
      clk_ext_stopped_i => clk_ext_stopped_i,
      clk_ext_rst_o     => clk_ext_rst_o,
      pps_csync_p1_i  => pps_csync_p1_i,
      pps_ext_a_i     => pps_ext_a_i,
      direct_tag0_valid_i => direct_tag0_valid_i,
      direct_tag0_i       => direct_tag0_i,
      dac_dmtd_data_o => dac_dmtd_data_o,
      dac_dmtd_load_o => dac_dmtd_load_o,
      dac_out_data_o  => dac_out_data_o,
      dac_out_sel_o   => dac_out_sel_o,
      dac_out_load_o  => dac_out_load_o,
      out_enable_i    => out_enable_i,
      out_locked_o    => out_locked_o,
      slave_i.adr => wb_adr_i,
      slave_i.dat => wb_dat_i,
      slave_i.cyc => wb_cyc_i,
      slave_i.sel => wb_sel_i,
      slave_i.stb => wb_stb_i,
      slave_i.we => wb_we_i,
      slave_o.dat => wb_dat_o,
      slave_o.ack => wb_ack_o,
      slave_o.err => wb_err,
      slave_o.rty => wb_rty,
      slave_o.stall => wb_stall_o,
      host_wb_i   => host_wb_i,
      host_wb_o   => host_wb_o,
      int_o           => irq_o,
      dbg_fifo_irq_o  => dbg_fifo_irq_o);
end rtl;
