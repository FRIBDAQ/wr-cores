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
-- Description: Divides a 500 MHz clock by g_divide. The parent supplies a
--              shared reset with synchronous release and a one-cycle PPS
--              alignment pulse, both in the 500 MHz domain. No CDC occurs here.
--              For odd divisors the high phase is one cycle shorter than low.
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
    -- Asynchronous assertion, release synchronized to clk_500m_i by parent.
    rst_n_i     : in  std_logic;
    -- One-cycle alignment pulse already synchronized to clk_500m_i.
    pps_i       : in  std_logic;
    -- generated x MHz synced with PPS
    clk_x_mhz_o : out std_logic := '0');
end gen_x_mhz;

architecture rtl of gen_x_mhz is

begin  -- rtl

  pr_x_mhz_gen : process (clk_500m_i, rst_n_i)
    variable cntr: integer range 0 to g_divide - 1;
  begin  -- process pr_10mhz_gen
    if rst_n_i = '0' then
      cntr       := 0;
      clk_x_mhz_o <= '0';
    elsif rising_edge(clk_500m_i) then
      if cntr < g_divide / 2 then
        clk_x_mhz_o <= '1';
      else
        clk_x_mhz_o <= '0';
      end if;

      -- As before, count zero is emitted on the edge following alignment.
      if (pps_i = '1' or cntr = g_divide - 1) then
        cntr := 0;
      elsif cntr < g_divide - 1 then
        cntr := cntr + 1;
      end if;
    end if;
  end process pr_x_mhz_gen;

end rtl;
