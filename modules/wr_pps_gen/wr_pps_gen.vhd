-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2010 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : PPS Generator & UTC Realtime clock
-- Project    : WhiteRabbit Switch
-------------------------------------------------------------------------------
-- File       : wr_pps_gen.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN (BE-CO-HT)
-- Created    : 2010-09-02
-- Platform   : FPGA-generics
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2010-09-02  1.0      twlostow        Created
-- 2011-05-09  1.1      twlostow        Added external PPS input
-- 2011-10-26  1.2      greg.d          Added wb slave adapter
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;

entity wr_pps_gen is
  generic(
    g_interface_mode       : t_wishbone_interface_mode      := CLASSIC;
    g_address_granularity  : t_wishbone_address_granularity := WORD;
    g_ref_clock_rate       : integer                        := 125000000;
    g_ext_clock_rate       : integer                        := 10000000;
    g_with_ext_clock_input : boolean                        := false
    );
  port (
    clk_ref_i   : in std_logic;
    clk_sys_i   : in std_logic;
    rst_ref_n_i : in std_logic;
    rst_sys_n_i : in std_logic;

    wb_adr_i   : in  std_logic_vector(4 downto 0);
    wb_dat_i   : in  std_logic_vector(31 downto 0);
    wb_dat_o   : out std_logic_vector(31 downto 0);
    wb_cyc_i   : in  std_logic;
    wb_sel_i   : in  std_logic_vector(3 downto 0);
    wb_stb_i   : in  std_logic;
    wb_we_i    : in  std_logic;
    wb_ack_o   : out std_logic;
    wb_stall_o : out std_logic;

    -- Link status indicator (used for fast masking of PPS output when link
    -- goes down
    link_ok_i : in std_logic;

    -- External PPS input. Warning! This signal is treated as synchronous to
    -- the clk_ref_i (or the external 10 MHz reference) to prevent sync chain
    -- delay uncertainities. Setup/hold times must be respected!
    pps_in_i     : in std_logic;
    ppsin_term_o : out std_logic;

    -- Single-pulse PPS output for synchronizing endpoints to
    pps_csync_o : out std_logic;
    pps_out_o   : out std_logic;
    pps_led_o   : out std_logic;
    pps_pre_o   : out std_logic;
    pps_valid_o : out std_logic;

    tm_utc_o        : out std_logic_vector(39 downto 0);
    tm_cycles_o     : out std_logic_vector(27 downto 0);
    tm_time_valid_o : out std_logic
    );
end wr_pps_gen;

architecture behavioral of wr_pps_gen is
  signal wb_out       : t_wishbone_slave_out;
  signal wb_in        : t_wishbone_slave_in;

  signal resized_addr : std_logic_vector(c_wishbone_address_width-1 downto 0);
begin  -- behavioral

  resized_addr(4 downto 0)                          <= wb_adr_i;
  resized_addr(c_wishbone_address_width-1 downto 5) <= (others => '0');

  U_Adapter : wb_slave_adapter
    generic map (
      g_master_use_struct  => true,
      g_master_mode        => CLASSIC,
      g_master_granularity => BYTE,
      g_slave_use_struct   => false,
      g_slave_mode         => g_interface_mode,
      g_slave_granularity  => g_address_granularity)
    port map (
      clk_sys_i  => clk_sys_i,
      rst_n_i    => rst_sys_n_i,
      master_i   => wb_out,
      master_o   => wb_in,
      sl_adr_i   => resized_addr,
      sl_dat_i   => wb_dat_i,
      sl_sel_i   => wb_sel_i,
      sl_cyc_i   => wb_cyc_i,
      sl_stb_i   => wb_stb_i,
      sl_we_i    => wb_we_i,
      sl_dat_o   => wb_dat_o,
      sl_ack_o   => wb_ack_o,
      sl_stall_o => wb_stall_o);

  WRAPPED_PPSGEN : entity work.xwr_pps_gen
    generic map(
      g_ref_clock_rate       => g_ref_clock_rate,
      g_ext_clock_rate       => g_ext_clock_rate,
      g_with_ext_clock_input => g_with_ext_clock_input
      )
    port map(
      clk_ref_i       => clk_ref_i,
      clk_sys_i       => clk_sys_i,
      rst_ref_n_i     => rst_ref_n_i,
      rst_sys_n_i     => rst_sys_n_i,
      slave_i         => wb_in,
      slave_o         => wb_out,
      link_ok_i       => link_ok_i,
      pps_in_i        => pps_in_i,
      ppsin_term_o    => ppsin_term_o,
      pps_csync_o     => pps_csync_o,
      pps_out_o       => pps_out_o,
      pps_led_o       => pps_led_o,
      pps_pre_o       => pps_pre_o,
      pps_valid_o     => pps_valid_o,
      tm_utc_o        => tm_utc_o,
      tm_cycles_o     => tm_cycles_o,
      tm_time_valid_o => tm_time_valid_o
      );
end behavioral;
