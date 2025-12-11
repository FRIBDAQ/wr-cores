-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 1970 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : Timecode package
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : wr_timecodes_pkg.vhd
-- Author     : Harvey Leicester
-- Company    : CERN BE-CEM-EDL
-- Created    : 2024-11-11
-- Last update: 2024-11-11
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- defines for wr_timecodes module
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package wr_timecode_pkg is

  type t_utc_out is record
    --utc fields are written by software.  see wrpc-sw/dev/timecode.c for implementation
    utc_year          : std_logic_vector(11 downto 0);  --utc year (1970 to 2099)
    utc_diy           : std_logic_vector(8 downto 0);   --utc day in year (1 to 366)
    utc_month         : std_logic_vector(3 downto 0);   --utc month (1 to 12)
    utc_day           : std_logic_vector(4 downto 0);   --utc day (1 to 31)
    utc_hour          : std_logic_vector(5 downto 0);   --utc hour (0 to 23)
    utc_min           : std_logic_vector(5 downto 0);   --utc minute (0 to 59)
    utc_sec           : std_logic_vector(5 downto 0);   --utc second (0 to 60)
    utc_sbs           : std_logic_vector(16 downto 0);  --utc straight binary seconds (0 to 131071)
    utc_valid         : std_logic;                      --utc time is valid

    ls_val            : std_logic_vector(7 downto 0);   --leap seconds value
    ls_flag           : std_logic_vector(1 downto 0);   --leap second flags (1)=59, (0)=61
    ls_valid          : std_logic;                      --leap second fields are valid
  end record t_utc_out;

  type t_aux_timing_out is record
    irig              : std_logic;                      --irig output (pwm timecode format)
    irig_valid        : std_logic;                      --irig output is valid
    nmea              : std_logic;                      --nmea output (serial timecode format)
    nmea_valid        : std_logic;                      --nmea output is valid
    serdes_in         : std_logic_vector(7 downto 0);   --input to platform specific serdes, can be either auxclk, irig or nmea.  software configurable
    serdes_out        : std_logic;                      --output from platform specific serdes, route to pin of device
  end record t_aux_timing_out;

  --function to assign signal to t_aux_timing_out.serdes_out member
  function f_aux_timing_assign_serdes_out(src : t_aux_timing_out;
                                          serdes_out : std_logic )
  return t_aux_timing_out;

  type t_wr_timecode_config is array (0 to 2) of boolean; --(auxclk, irig, nmea)
  constant c_WR_TIMECODE_NONE : t_wr_timecode_config := (others => FALSE);
  --indexes for t_wr_timecode_config
  constant c_WITH_AUXCLK_IDX : natural := 0;
  constant c_WITH_IRIG_IDX   : natural := 1;
  constant c_WITH_NMEA_IDX   : natural := 2;

  function f_aux_timing_enabled(config : t_wr_timecode_config)
  return boolean;

  function f_auxclk_enabled(config : t_wr_timecode_config)
  return boolean;

end wr_timecode_pkg;

package body wr_timecode_pkg is

  function f_aux_timing_assign_serdes_out(src : t_aux_timing_out;
                                          serdes_out : std_logic )
  return t_aux_timing_out is
    variable dst : t_aux_timing_out;
  begin

    dst.irig              := src.irig;
    dst.irig_valid        := src.irig_valid;
    dst.nmea              := src.nmea;
    dst.nmea_valid        := src.nmea_valid;
    dst.serdes_in         := src.serdes_in;
    dst.serdes_out        := serdes_out;
    return dst;
  end function f_aux_timing_assign_serdes_out;

  function f_aux_timing_enabled(config : t_wr_timecode_config)
  return boolean is
  begin
    return config(0) or config(1) or config(2);
  end function f_aux_timing_enabled;

  function f_auxclk_enabled(config : t_wr_timecode_config)
  return boolean is
  begin
    return config(c_WITH_AUXCLK_IDX);
  end function f_auxclk_enabled;

end package body wr_timecode_pkg;
