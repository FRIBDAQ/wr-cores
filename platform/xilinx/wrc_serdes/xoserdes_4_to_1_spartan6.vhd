-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2012 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : Spartan6 oserdes wrapper
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : xoserdes_4_to_1_spartan6.vhd
-- Author     : Harvey Leicester
-- Company    : CERN BE-CEM-EDL
-- Created    : 2025-05-23
-- Last update: 2025-05-23
-- Platform   : Spartan6
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- Wrapper for PLL+OSERDES Spartan6
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity xoserdes_4_to_1_spartan6 is
generic
(
  g_clkin_period : real := 8.000                --clk_i period (ns)
);
port
(
  clk_i     : in std_logic;                     --input to pll for generating serdes clk
  rst_i     : in std_logic;                     --async reset
  serdes_i  : in std_logic_vector(3 downto 0);  --serdes data in
  serdes_o  : out std_logic;                    --serdes data out
  pll_serdes_locked_o : out std_logic           --serdes clk pll locked indicator
);
end entity xoserdes_4_to_1_spartan6;

architecture rtl of xoserdes_4_to_1_spartan6 is

  signal pll_serdes_fb      : std_logic;
  signal pll_serdes_out     : std_logic;
  signal pll_serdes_locked  : std_logic;
  signal rst_serdes         : std_logic;

begin

  --125MHz - 500MHz (default)
  cmp_serdes_pll : PLL_BASE
  generic map(
    BANDWIDTH            => "OPTIMIZED",
    CLK_FEEDBACK         => "CLKFBOUT",
    COMPENSATION         => "INTERNAL",
    DIVCLK_DIVIDE        => 1,
    CLKFBOUT_MULT        => 4,
    CLKFBOUT_PHASE       => 0.000,
    CLKOUT0_DIVIDE       => 1,
    CLKOUT0_PHASE        => 0.000,
    CLKOUT0_DUTY_CYCLE   => 0.500,
    CLKIN_PERIOD         => g_clkin_period,
    REF_JITTER           => 0.010)
  port map
    -- Output clocks
   (CLKFBOUT            => pll_serdes_fb,
    CLKOUT0             => pll_serdes_out,
    CLKOUT1             => open,
    CLKOUT2             => open,
    CLKOUT3             => open,
    CLKOUT4             => open,
    CLKOUT5             => open,
    -- Status and control signals
    LOCKED              => pll_serdes_locked,
    RST                 => rst_i,
    -- Input clock control
    CLKFBIN             => pll_serdes_fb,
    CLKIN               => clk_i);

  rst_serdes  <= not pll_serdes_locked;

  U_serdes: entity work.oserdes_4_to_1_spartan6
  generic map(
    SYS_W => 1,
    DEV_W => 4
  )
  port map(
    DATA_OUT_FROM_DEVICE => serdes_i,
    DATA_OUT_TO_PINS(0)  => serdes_o,
    CLK_IN               => pll_serdes_out,
    PLL_LOCKED_IN        => pll_serdes_locked,
    CLK_DIV_IN           => clk_i,
    IO_RESET             => rst_serdes
  );

  pll_serdes_locked_o <= pll_serdes_locked;

end architecture;
