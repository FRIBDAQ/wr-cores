-------------------------------------------------------------------------------
-- Title      : Xilinx 10MHz output generator
-- Project    : WR PTP Core and EMPIR 17IND14 WRITE 
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
--            : http://empir.npl.co.uk/write/
-------------------------------------------------------------------------------
-- File       : gen_10mhz.vhd
-- Author(s)  : Peter Jansweijer <peterj@nikhef.nl>
-- Company    : Nikhef
-- Created    : 2018-12-10
-- Last update: 2018-12-10
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Creates a 10 MHz output clock that is locked to the reference
--              clock and is PPS phase aligned.
--              To achieve this, a 500 MHz reference clock is necessary.
--              Note: 10 MHz = 50 ns '1', 50 ns '0'
--                    50 ns is divisible by 2 ns (not by 8 or 4 ns!) hence 500 MHz.
-------------------------------------------------------------------------------
-- Copyright (c) 2018 Nikhef
-------------------------------------------------------------------------------
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
use ieee.NUMERIC_STD.all;

--library work;
--use work.gencores_pkg.all;
--use work.genram_pkg.all;

entity gen_x_mhz is
  generic (
    g_divide    : integer := 50
  );
  port (
    clk_500m_i  : in  std_logic;
    rst_n_i     : in  std_logic;
    pps_i       : in  std_logic;
    -- generated x MHz synced with PPS
    clk_x_mhz_o : out std_logic := '0');
end gen_x_mhz;

architecture rtl of gen_x_mhz is

  signal rst_n_synced  : std_logic := '0';
  signal pps_synced    : std_logic := '0';
  signal pps_delayed   : std_logic := '0';
  
begin  -- rtl
  process (clk_500m_i)
  begin
    if rising_edge(clk_500m_i) then
      -- clk_500m is locked to the reference clock domain
      -- although clocks are phase locked, first synchronize pps_i
      -- and rst_n_i to 500 MHz to ease timing closure.
      rst_n_synced  <= rst_n_i;
      pps_synced    <= pps_i;
      pps_delayed   <= pps_synced;
    end if;
  end process;
  
  pr_x_mhz_gen : process (clk_500m_i, rst_n_synced)
    variable cntr: integer range 0 to g_divide - 1;
  begin  -- process pr_10mhz_gen
    if rst_n_synced = '0' then
      cntr       := 0;
    elsif rising_edge(clk_500m_i) then
      if cntr < g_divide / 2 then
        clk_x_mhz_o <= '1';
      else
        clk_x_mhz_o <= '0';
      end if;

      if ((pps_synced = '1' and pps_delayed = '0') or cntr = g_divide - 1) then
        cntr := 0;
      elsif cntr < g_divide - 1 then
        cntr := cntr + 1;
      end if;
    end if;
  end process pr_x_mhz_gen;

end rtl;

