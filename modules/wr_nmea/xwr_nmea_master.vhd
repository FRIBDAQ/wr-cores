-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2012 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : NMEA master interface
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : xwr_nmea_master.vhd
-- Author     : Harvey Leicester
-- Company    : CERN BE-CEM-EDL
-- Created    : 2024-11-11
-- Last update: 2024-11-11
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- NMEA master wrapper
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.gencores_pkg.all;
use work.nmea_master_regs_pkg.all;

entity xwr_nmea_master is
  generic (
    g_ref_clock_rate      : integer := 62500000
  );
  port
  (
    clk_sys_i   : in std_logic;   --sys clk for wb regs
    clk_ref_i   : in std_logic;
    rst_sys_n_i : in std_logic;
    rst_ref_n_i : in std_logic;

    --inputs, ref clock domain
    sec_i   : in std_logic_vector(7 downto 0);  --second, bcd format
    min_i   : in std_logic_vector(7 downto 0);  --minute, bcd format
    hour_i  : in std_logic_vector(7 downto 0);  --hour, bcd format
    day_i   : in std_logic_vector(7 downto 0);  --day, bcd format
    month_i : in std_logic_vector(7 downto 0);  --month, bcd format
    year_i  : in std_logic_vector(15 downto 0); --year, bcd format
    valid_i : in std_logic;
    tx_en_i : in std_logic;

    --output, ref clock domain
    nmea_o  : out std_logic;

    wb_i    : in  t_wishbone_slave_in;
    wb_o    : out t_wishbone_slave_out
  );
end entity xwr_nmea_master;

architecture wrapper of xwr_nmea_master is
  signal nmea_regs_in  : t_nmea_regs_master_in;
  signal nmea_regs_out : t_nmea_regs_master_out;

  signal baud_div : std_logic_vector(16 downto 0);
  signal busy_out : std_logic;
  signal nmea_out : std_logic;

begin
  U_nmea_master_regs: entity work.nmea_master_regs
    port map (
      rst_n_i     => rst_sys_n_i,
      clk_i       => clk_sys_i,
      wb_i        => wb_i,
      wb_o        => wb_o,
      nmea_regs_i => nmea_regs_in,
      nmea_regs_o => nmea_regs_out
      );

  U_sync_baud_div: gc_sync_register
    generic map (
      g_width => 17
    )
    port map (
      clk_i     => clk_ref_i,
      rst_n_a_i => rst_ref_n_i,
      d_i       => nmea_regs_out.CR_baud_div,
      q_o       => baud_div
    );

  U_nmea: entity work.wr_nmea_master
    port map (
      clk_i      => clk_ref_i,
      rst_n_i    => rst_ref_n_i,
      sec_i      => sec_i,
      min_i      => min_i,
      hour_i     => hour_i,
      day_i      => day_i,
      month_i    => month_i,
      year_i     => year_i,
      valid_i    => valid_i,
      tx_en_i    => tx_en_i,
      uart_bcr_i => baud_div,
      busy_o     => busy_out,
      nmea_o     => nmea_out
      );

  nmea_o <= nmea_out when nmea_regs_out.CR_invert = '0' else not nmea_out;

  nmea_regs_in.SR_clk_freq <= std_logic_vector(to_unsigned(g_ref_clock_rate, nmea_regs_in.SR_clk_freq'length));

  --synchronisers for read regs
  U_sync_sec: gc_sync_register
    generic map (
      g_width => 8
    )
    port map (
      clk_i     => clk_sys_i,
      rst_n_a_i => rst_sys_n_i,
      d_i       => sec_i,
      q_o       => nmea_regs_in.TOD_second
    );

  U_sync_min: gc_sync_register
    generic map (
      g_width =>8
    )
    port map (
      clk_i     => clk_sys_i,
      rst_n_a_i => rst_sys_n_i,
      d_i       => min_i,
      q_o       => nmea_regs_in.TOD_minute
    );

  U_sync_hour: gc_sync_register
    generic map (
      g_width => 8
    )
    port map (
      clk_i     => clk_sys_i,
      rst_n_a_i => rst_sys_n_i,
      d_i       => hour_i,
      q_o       => nmea_regs_in.TOD_hour
    );

  U_sync_day: gc_sync_register
    generic map (
      g_width => 8
    )
    port map (
      clk_i     => clk_sys_i,
      rst_n_a_i => rst_sys_n_i,
      d_i       => day_i,
      q_o       => nmea_regs_in.DATE_day
    );

  U_sync_month: gc_sync_register
    generic map (
      g_width => 8
    )
    port map (
      clk_i     => clk_sys_i,
      rst_n_a_i => rst_sys_n_i,
      d_i       => month_i,
      q_o       => nmea_regs_in.DATE_month
    );

  U_sync_year: gc_sync_register
    generic map (
      g_width => 16
    )
    port map (
      clk_i     => clk_sys_i,
      rst_n_a_i => rst_sys_n_i,
      d_i       => year_i,
      q_o       => nmea_regs_in.DATE_year
    );

  U_sync_tip: gc_sync
    port map (
      clk_i     => clk_sys_i,
      rst_n_a_i => rst_sys_n_i,
      d_i       => busy_out,
      q_o       => nmea_regs_in.SR_tip
    );

  U_sync_valid: gc_sync
    port map (
      clk_i     => clk_sys_i,
      rst_n_a_i => rst_sys_n_i,
      d_i       => valid_i,
      q_o       => nmea_regs_in.SR_valid
    );

end wrapper;
