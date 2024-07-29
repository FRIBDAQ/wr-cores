-------------------------------------------------------------------------------
-- Title      : WRPC reference design for KR260 board
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- Company    : CERN (BE-CO-HT)
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Copyright (c) 2024 CERN
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
use ieee.numeric_std.all;

--use work.gencores_pkg.all;
--use work.wishbone_pkg.all;
--use work.wr_board_pkg.all;
--use work.wr_pxie_fmc_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity kr260_ref_top is
  port (
    refclk1_n_i : in std_logic;
    refclk1_p_i : in std_logic;

    led1_o : out std_logic;
    led2_o : out std_logic
  );
end;

architecture top of kr260_ref_top is

  signal refclk_74m25, refclk_74m25_int : std_logic;
  signal rst_n : std_logic := '0';
  signal rst_cnt : natural range 0 to 15 := 0;

  signal count : natural range 0 to 74_250_000 - 1;
  signal clk : std_logic;
begin
  inst_ibufds_gt : IBUFDS_GTE4
      generic map (
        REFCLK_EN_TX_PATH  => '0',
        REFCLK_HROW_CK_SEL => "00",
        REFCLK_ICNTL_RX    => "00")
      port map (
        O     => refclk_74m25,
        ODIV2 => refclk_74m25_int,
        CEB   => '0',
        I     => refclk1_p_i,
        IB    => refclk1_n_i);

  inst_buf_gt : BUFG_GT
      port map (
        O => clk,
        CE => '1',
        CEMASK => '0',
        CLR => '0',
        CLRMASK => '0',
        DIV => "000",
        I => refclk_74m25_int);

  process(clk)
  begin
    if rising_edge(clk) then
      if rst_cnt = 15 then
        rst_n <= '1';
      else
        rst_n <= '0';
        rst_cnt <= rst_cnt + 1;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        led1_o <= '0';
        led2_o <= '1';
        count <= 0;
      else
        if count = 37_125_000 - 1 then
          led1_o <= '1';
          led2_o <= '0';
          count <= count + 1;
        elsif count = 74_250_000 - 1 then
          led1_o <= '0';
          led2_o <= '1';
          count <= 0;
        else
          count <= count + 1;
        end if;
      end if;
    end if;
  end process;
end top;
