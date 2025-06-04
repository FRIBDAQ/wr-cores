-------------------------------------------------------------------------------
-- Title      : UTC to BCD converter
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : utc2bcd.vhd
-- Author     : Harvey Leicester
-- Company    : CERN BE-CEM-EDL
-- Created    : 2024-11-11
-- Last update: 2024-11-11
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- convert binary UTC to binary coded decimal
-- Based on cute-wr by Guanghua Gong
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

library work;

entity utc2bcd is
  port (
    rst_n_i    : in std_logic;
    clk_i      : in std_logic;

    utc_hex_valid_i : in std_logic;
    year_hex_i      : in std_logic_vector(11 downto 0);   --1970 - 2099
    diy_hex_i       : in std_logic_vector(8 downto 0);    --1-366
    month_hex_i     : in std_logic_vector(3 downto 0);    --1-12
    day_hex_i       : in std_logic_vector(4 downto 0);    --1-31
    hour_hex_i      : in std_logic_vector(5 downto 0);    --0-23
    min_hex_i       : in std_logic_vector(5 downto 0);    --0-59
    sec_hex_i       : in std_logic_vector(5 downto 0);    --0-60

    utc_bcd_valid_o : out std_logic;
    year_bcd_o      : out std_logic_vector(15 downto 0);  --1970 - 2099  , 4 digits
    diy_bcd_o       : out std_logic_vector(11 downto 0);  --1-366        , 3 digits
    month_bcd_o     : out std_logic_vector(7 downto 0);   --1-12         , 2 digits
    day_bcd_o       : out std_logic_vector(7 downto 0);   --1-31         , 2 digits
    hour_bcd_o      : out std_logic_vector(7 downto 0);   --0-23         , 2 digits
    min_bcd_o       : out std_logic_vector(7 downto 0);   --0-59         , 2 digits
    sec_bcd_o       : out std_logic_vector(7 downto 0)    --0-60         , 2 digits
  );
end entity utc2bcd;

architecture rtl of utc2bcd is

    signal year_bcd_valid   : std_logic;
    signal diy_bcd_valid    : std_logic;
    signal month_bcd_valid  : std_logic;
    signal day_bcd_valid    : std_logic;
    signal hour_bcd_valid   : std_logic;
    signal min_bcd_valid : std_logic;
    signal sec_bcd_valid : std_logic;

begin

    --latency ~25 cycles, longest path is years (most digits)
    utc_bcd_valid_o <= (year_bcd_valid and diy_bcd_valid and month_bcd_valid and day_bcd_valid and hour_bcd_valid and min_bcd_valid and sec_bcd_valid);

    U_year: entity work.hex2bcd
    generic map (
      g_hex_width  => 12,
      g_bcd_digits => 4
    )
    port map (
      clk_i       => clk_i,
      rst_n_i     => rst_n_i,
      hex_i       => year_hex_i,
      hex_valid_i => utc_hex_valid_i,
      bcd_o       => year_bcd_o,
      bcd_valid_o => year_bcd_valid
    );

    U_diy: entity work.hex2bcd
    generic map (
      g_hex_width  => 9,
      g_bcd_digits => 3
    )
    port map (
      clk_i       => clk_i,
      rst_n_i     => rst_n_i,
      hex_i       => diy_hex_i,
      hex_valid_i => utc_hex_valid_i,
      bcd_o       => diy_bcd_o,
      bcd_valid_o => diy_bcd_valid
    );

    U_month: entity work.hex2bcd
    generic map (
      g_hex_width  => 4,
      g_bcd_digits => 2
    )
    port map (
      clk_i       => clk_i,
      rst_n_i     => rst_n_i,
      hex_i       => month_hex_i,
      hex_valid_i => utc_hex_valid_i,
      bcd_o       => month_bcd_o,
      bcd_valid_o => month_bcd_valid
    );

    U_day: entity work.hex2bcd
    generic map (
      g_hex_width  => 5,
      g_bcd_digits => 2
    )
    port map (
      clk_i       => clk_i,
      rst_n_i     => rst_n_i,
      hex_i       => day_hex_i,
      hex_valid_i => utc_hex_valid_i,
      bcd_o       => day_bcd_o,
      bcd_valid_o => day_bcd_valid
    );

    U_hour: entity work.hex2bcd
    generic map (
      g_hex_width  => 6,
      g_bcd_digits => 2
    )
    port map (
      clk_i       => clk_i,
      rst_n_i     => rst_n_i,
      hex_i       => hour_hex_i,
      hex_valid_i => utc_hex_valid_i,
      bcd_o       => hour_bcd_o,
      bcd_valid_o => hour_bcd_valid
    );

    U_min: entity work.hex2bcd
    generic map (
      g_hex_width  => 6,
      g_bcd_digits => 2
    )
    port map (
      clk_i       => clk_i,
      rst_n_i     => rst_n_i,
      hex_i       => min_hex_i,
      hex_valid_i => utc_hex_valid_i,
      bcd_o       => min_bcd_o,
      bcd_valid_o => min_bcd_valid
    );

    U_sec: entity work.hex2bcd
    generic map (
      g_hex_width  => 6,
      g_bcd_digits => 2
    )
    port map (
      clk_i       => clk_i,
      rst_n_i     => rst_n_i,
      hex_i       => sec_hex_i,
      hex_valid_i => utc_hex_valid_i,
      bcd_o       => sec_bcd_o,
      bcd_valid_o => sec_bcd_valid
    );

end architecture rtl;

