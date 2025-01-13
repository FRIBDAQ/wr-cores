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

package wr_timecode_pkg is

  type t_utc_out is record

    utc_year          : std_logic_vector(11 downto 0);
    utc_diy           : std_logic_vector(8 downto 0);
    utc_month         : std_logic_vector(3 downto 0);
    utc_day           : std_logic_vector(4 downto 0);
    utc_hour          : std_logic_vector(5 downto 0);
    utc_min           : std_logic_vector(5 downto 0);
    utc_sec           : std_logic_vector(5 downto 0);
    utc_sbs           : std_logic_vector(16 downto 0);
    utc_valid         : std_logic;

    ls_val            : std_logic_vector(7 downto 0);
    ls_flag           : std_logic_vector(1 downto 0);
    ls_valid          : std_logic;

  end record t_utc_out;


  type t_aux_timing_out is record

    irig              : std_logic;
    irig_valid        : std_logic;
    nmea              : std_logic;
    nmea_valid        : std_logic;
    serdes_in         : std_logic_vector(7 downto 0);
    serdes_out        : std_logic;

  end record t_aux_timing_out;

  function f_aux_timing_assign_serdes_out(src : t_aux_timing_out;
                                   serdes_out : std_logic )
  return t_aux_timing_out;

  type t_wr_timecode_config is array (0 to 2) of boolean; --(auxclk, irig, nmea)
  constant c_WR_TIMECODE_DEFCONFIG : t_wr_timecode_config := (others => FALSE);
  constant c_WITH_AUXCLK_IDX : natural := 0;
  constant c_WITH_IRIG_IDX   : natural := 1;
  constant c_WITH_NMEA_IDX   : natural := 2;

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

end package body wr_timecode_pkg;