-------------------------------------------------------------------------------
-- Title      : UTC timecode
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : utc_timecode.vhd
-- Author     : Harvey Leicester
-- Company    : CERN BE-CEM-EDL
-- Created    : 2024-11-11
-- Last update: 2024-11-11
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- double buffer for utc timecodes
-- take utc from sw (clk_sys domain), cross to clk_ref domain
-- and convert to BCD format for auxiliary timing outputs (NMEA, IRIG-B)
-------------------------------------------------------------------------------
--
-- Copyright (c) 2012 - 2025 CERN / BE-CEM-EDL
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

use work.wishbone_pkg.all;
use work.gencores_pkg.all;

entity utc_timecode is
  port (

    clk_sys_i : in std_logic;
    clk_ref_i : in std_logic;
    rst_sys_n_i : in std_logic;
    rst_ref_n_i : in std_logic;

    --ref clk domain
    pps_valid_i : in std_logic := '0';
    pps_pre_i   : in std_logic := '0';

    --sys clk domain
    utc_year_sys_i  : in std_logic_vector(11 downto 0);
    utc_diy_sys_i   : in std_logic_vector(8 downto 0);
    utc_month_sys_i : in std_logic_vector(3 downto 0);
    utc_day_sys_i   : in std_logic_vector(4 downto 0);
    utc_hour_sys_i  : in std_logic_vector(5 downto 0);
    utc_min_sys_i   : in std_logic_vector(5 downto 0);
    utc_sec_sys_i   : in std_logic_vector(5 downto 0);
    utc_sbs_sys_i   : in std_logic_vector(16 downto 0);
    ls_val_sys_i    : in std_logic_vector(7 downto 0);
    ls_flag_sys_i   : in std_logic_vector(1 downto 0);
    ls_valid_sys_i  : in std_logic;
    utc_valid_sys_i : in std_logic;

    utc_year_sys_o  : out std_logic_vector(11 downto 0);
    utc_diy_sys_o   : out std_logic_vector(8 downto 0);
    utc_month_sys_o : out std_logic_vector(3 downto 0);
    utc_day_sys_o   : out std_logic_vector(4 downto 0);
    utc_hour_sys_o  : out std_logic_vector(5 downto 0);
    utc_min_sys_o   : out std_logic_vector(5 downto 0);
    utc_sec_sys_o   : out std_logic_vector(5 downto 0);
    utc_sbs_sys_o   : out std_logic_vector(16 downto 0);
    ls_val_sys_o    : out std_logic_vector(7 downto 0);
    ls_flag_sys_o   : out std_logic_vector(1 downto 0);
    ls_valid_sys_o  : out std_logic;
    utc_valid_sys_o : out std_logic;

    --ref clk domain
    utc_valid_ref_o : out std_logic;
    utc_year_ref_o  : out std_logic_vector(11 downto 0);
    utc_diy_ref_o   : out std_logic_vector(8 downto 0);
    utc_month_ref_o : out std_logic_vector(3 downto 0);
    utc_day_ref_o   : out std_logic_vector(4 downto 0);
    utc_hour_ref_o  : out std_logic_vector(5 downto 0);
    utc_min_ref_o   : out std_logic_vector(5 downto 0);
    utc_sec_ref_o   : out std_logic_vector(5 downto 0);
    utc_sbs_ref_o   : out std_logic_vector(16 downto 0);

    --bcd outputs, ref clock domain
    utc_bcd_year_o  : out std_logic_vector(15 downto 0);
    utc_bcd_diy_o   : out std_logic_vector(11 downto 0);
    utc_bcd_month_o : out std_logic_vector(7 downto 0);
    utc_bcd_day_o   : out std_logic_vector(7 downto 0);
    utc_bcd_hour_o  : out std_logic_vector(7 downto 0);
    utc_bcd_min_o   : out std_logic_vector(7 downto 0);
    utc_bcd_sec_o   : out std_logic_vector(7 downto 0);
    utc_bcd_valid_o : out std_logic;

    --leap second outputs
    ls_val_ref_o      : out std_logic_vector(7 downto 0);
    ls_flag_ref_o     : out std_logic_vector(1 downto 0);
    ls_valid_ref_o    : out std_logic
  );
end entity utc_timecode;

architecture rtl of utc_timecode is

  signal utc_valid_sys : std_logic;
  signal pps_valid_sys : std_logic;
  signal pps_pre_sys   : std_logic;

  signal utc_valid_ref : std_logic;
  signal utc_year_ref  : std_logic_vector(11 downto 0);
  signal utc_diy_ref   : std_logic_vector(8 downto 0);
  signal utc_month_ref : std_logic_vector(3 downto 0);
  signal utc_day_ref   : std_logic_vector(4 downto 0);
  signal utc_hour_ref  : std_logic_vector(5 downto 0);
  signal utc_min_ref   : std_logic_vector(5 downto 0);
  signal utc_sec_ref   : std_logic_vector(5 downto 0);
  signal utc_sbs_ref   : std_logic_vector(16 downto 0);

  signal ls_val_ref   : std_logic_vector(7 downto 0);
  signal ls_flag_ref  : std_logic_vector(1 downto 0);
  signal ls_valid_ref : std_logic;

  signal utc_bcd_valid : std_logic;
  signal utc_bcd_year  : std_logic_vector(15 downto 0);
  signal utc_bcd_diy   : std_logic_vector(11 downto 0);
  signal utc_bcd_month : std_logic_vector(7 downto 0);
  signal utc_bcd_day   : std_logic_vector(7 downto 0);
  signal utc_bcd_hour  : std_logic_vector(7 downto 0);
  signal utc_bcd_min   : std_logic_vector(7 downto 0);
  signal utc_bcd_sec   : std_logic_vector(7 downto 0);


begin

  utc_valid_sys <= pps_valid_sys and utc_valid_sys_i;

  --synchronisers
  U_sync_utc_year: gc_sync_register
    generic map (
      g_width => utc_year_sys_i'length
    )
    port map (
      clk_i     => clk_ref_i,
      rst_n_a_i => rst_ref_n_i,
      d_i       => utc_year_sys_i,
      q_o       => utc_year_ref
    );

  U_sync_utc_diy: gc_sync_register
    generic map (
      g_width => utc_diy_sys_i'length
    )
    port map (
      clk_i     => clk_ref_i,
      rst_n_a_i => rst_ref_n_i,
      d_i       => utc_diy_sys_i,
      q_o       => utc_diy_ref
    );

  U_sync_utc_month: gc_sync_register
    generic map (
      g_width => utc_month_sys_i'length
    )
    port map (
      clk_i     => clk_ref_i,
      rst_n_a_i => rst_ref_n_i,
      d_i       => utc_month_sys_i,
      q_o       => utc_month_ref
    );

  U_sync_utc_day: gc_sync_register
    generic map (
      g_width => utc_day_sys_i'length
    )
    port map (
      clk_i     => clk_ref_i,
      rst_n_a_i => rst_ref_n_i,
      d_i       => utc_day_sys_i,
      q_o       => utc_day_ref
    );

  U_sync_utc_hour: gc_sync_register
    generic map (
      g_width => utc_hour_sys_i'length
    )
    port map (
      clk_i     => clk_ref_i,
      rst_n_a_i => rst_ref_n_i,
      d_i       => utc_hour_sys_i,
      q_o       => utc_hour_ref
    );

  U_sync_utc_min: gc_sync_register
    generic map (
      g_width => utc_min_sys_i'length
    )
    port map (
      clk_i     => clk_ref_i,
      rst_n_a_i => rst_ref_n_i,
      d_i       => utc_min_sys_i,
      q_o       => utc_min_ref
    );

  U_sync_utc_sec: gc_sync_register
    generic map (
      g_width => utc_sec_sys_i'length
    )
    port map (
      clk_i     => clk_ref_i,
      rst_n_a_i => rst_ref_n_i,
      d_i       => utc_sec_sys_i,
      q_o       => utc_sec_ref
    );

  U_sync_utc_sbs: gc_sync_register
    generic map (
      g_width => utc_sbs_sys_i'length
    )
    port map (
      clk_i     => clk_ref_i,
      rst_n_a_i => rst_ref_n_i,
      d_i       => utc_sbs_sys_i,
      q_o       => utc_sbs_ref
    );

  U_sync_ls_val: gc_sync_register
    generic map (
      g_width => ls_val_sys_i'length
    )
    port map (
      clk_i     => clk_ref_i,
      rst_n_a_i => rst_ref_n_i,
      d_i       => ls_val_sys_i,
      q_o       => ls_val_ref
    );

  U_sync_ls_flag: gc_sync_register
    generic map (
      g_width => ls_flag_sys_i'length
    )
    port map (
      clk_i     => clk_ref_i,
      rst_n_a_i => rst_ref_n_i,
      d_i       => ls_flag_sys_i,
      q_o       => ls_flag_ref
    );

  U_sync_ls_valid: gc_sync
    port map (
      clk_i     => clk_ref_i,
      rst_n_a_i => rst_ref_n_i,
      d_i       => ls_valid_sys_i,
      q_o       => ls_valid_ref
    );

  U_sync_pps_valid: gc_sync
    port map (
      clk_i     => clk_sys_i,
      rst_n_a_i => rst_sys_n_i,
      d_i       => pps_valid_i,
      q_o       => pps_valid_sys
    );

  U_sync_utc_valid: gc_sync
    port map (
      clk_i     => clk_ref_i,
      rst_n_a_i => rst_ref_n_i,
      d_i       => utc_valid_sys,
      q_o       => utc_valid_ref
    );

  --bcd formatting
  U_utc2bcd: entity work.utc2bcd
  port map
  (
    rst_n_i         => rst_ref_n_i,
    clk_i           => clk_ref_i,

    utc_hex_valid_i => utc_valid_ref,
    year_hex_i      => utc_year_ref,
    diy_hex_i       => utc_diy_ref,
    month_hex_i     => utc_month_ref,
    day_hex_i       => utc_day_ref,
    hour_hex_i      => utc_hour_ref,
    min_hex_i       => utc_min_ref,
    sec_hex_i       => utc_sec_ref,

    utc_bcd_valid_o => utc_bcd_valid_o,
    year_bcd_o      => utc_bcd_year_o,
    diy_bcd_o       => utc_bcd_diy_o,
    month_bcd_o     => utc_bcd_month_o,
    day_bcd_o       => utc_bcd_day_o,
    hour_bcd_o      => utc_bcd_hour_o,
    min_bcd_o       => utc_bcd_min_o,
    sec_bcd_o       => utc_bcd_sec_o
  );

  U_sync_pps_pre: gc_sync
    port map (
      clk_i     => clk_sys_i,
      rst_n_a_i => rst_sys_n_i,
      d_i       => pps_pre_i,
      q_o       => pps_pre_sys
    );

  --loopback for read regs
  p_read_regs: process(clk_sys_i) is
  begin
    if rising_edge(clk_sys_i) then
      utc_valid_sys_o     <= utc_valid_sys;
      ls_valid_sys_o      <= ls_valid_sys_i;
      if (pps_pre_sys = '1') then
          utc_sec_sys_o   <= utc_sec_sys_i;
          utc_min_sys_o   <= utc_min_sys_i;
          utc_hour_sys_o  <= utc_hour_sys_i;
          utc_day_sys_o   <= utc_day_sys_i;
          utc_month_sys_o <= utc_month_sys_i;
          utc_year_sys_o  <= utc_year_sys_i;
          utc_diy_sys_o   <= utc_diy_sys_i;
          utc_sbs_sys_o   <= utc_sbs_sys_i;
          ls_val_sys_o    <= ls_val_sys_i;
          ls_flag_sys_o   <= ls_flag_sys_i;
          ls_valid_sys_o  <= ls_valid_sys_i;
      end if;
    end if;
  end process;

  --clk_ref domain outputs
  utc_year_ref_o    <= utc_year_ref;
  utc_diy_ref_o     <= utc_diy_ref;
  utc_month_ref_o   <= utc_month_ref;
  utc_day_ref_o     <= utc_day_ref;
  utc_hour_ref_o    <= utc_hour_ref;
  utc_min_ref_o     <= utc_min_ref;
  utc_sec_ref_o     <= utc_sec_ref;
  utc_sbs_ref_o     <= utc_sbs_ref;
  utc_valid_ref_o   <= utc_valid_ref;
  ls_val_ref_o      <= ls_val_ref;
  ls_flag_ref_o     <= ls_flag_ref;
  ls_valid_ref_o    <= ls_valid_ref;

end rtl;
