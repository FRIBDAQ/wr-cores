-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2012 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : Spartan6 oserdes wrapper
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : xoserdes_8_to_1_7series.vhd
-- Author     : Harvey Leicester
-- Company    : CERN BE-CEM-EDL
-- Created    : 2025-05-23
-- Last update: 2025-05-23
-- Platform   : 7Series
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- Wrapper for PLL+OSERDES 7 Series
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity xoserdes_8_to_1_7series is
generic
(
  g_clkin_period : real := 16.000               --clk_i period (ns)
);
port
(
  clk_i     : in std_logic;                     --input to pll for generating serdes clk
  rst_i     : in std_logic;                     --async reset
  serdes_i  : in std_logic_vector(7 downto 0);  --serdes data in
  serdes_o  : out std_logic;                    --serdes data out
  pll_serdes_locked_o : out std_logic           --serdes clk pll locked indicator
);
end entity xoserdes_8_to_1_7series;

architecture rtl of xoserdes_8_to_1_7series is

  signal pll_serdes_fb      : std_logic;
  signal pll_serdes_out     : std_logic;
  signal pll_serdes_locked  : std_logic;
  signal rst_serdes         : std_logic;

begin

  --62.5MHz to 500MHz
  cmp_serdes_pll: MMCME2_ADV
  generic map(
    BANDWIDTH            => "OPTIMIZED",
    CLKOUT4_CASCADE      => FALSE,
    COMPENSATION         => "INTERNAL",
    STARTUP_WAIT         => FALSE,
    DIVCLK_DIVIDE        => 1,
    CLKFBOUT_MULT_F      => 16.000,
    CLKFBOUT_PHASE       => 0.000,
    CLKFBOUT_USE_FINE_PS => FALSE,
    CLKOUT0_DIVIDE_F     => 2.000,
    CLKOUT0_PHASE        => 0.000,
    CLKOUT0_DUTY_CYCLE   => 0.500,
    CLKOUT0_USE_FINE_PS  => FALSE,
    CLKIN1_PERIOD        => g_clkin_period,
    REF_JITTER1          => 0.010
  )
  port map(
    CLKFBOUT            => pll_serdes_fb,
    CLKFBOUTB           => open,
    CLKOUT0             => pll_serdes_out,
    CLKOUT0B            => open,
    CLKOUT1             => open,
    CLKOUT1B            => open,
    CLKOUT2             => open,
    CLKOUT2B            => open,
    CLKOUT3             => open,
    CLKOUT3B            => open,
    CLKOUT4             => open,
    CLKOUT5             => open,
    CLKOUT6             => open,
    -- Input clock control
    CLKFBIN             => pll_serdes_fb,
    CLKIN1              => clk_i,
    CLKIN2              => '0',
    -- Tied to always select the primary input clock
    CLKINSEL            => '1',
    -- Ports for dynamic reconfiguration
    DADDR               => (others => '0'),
    DCLK                => '0',
    DEN                 => '0',
    DI                  => (others => '0'),
    DO                  => open,
    DRDY                => open,
    DWE                 => '0',
    -- Ports for dynamic phase shift
    PSCLK               => '0',
    PSEN                => '0',
    PSINCDEC            => '0',
    PSDONE              => open,
    -- Other control and status signals
    LOCKED              => pll_serdes_locked,
    CLKINSTOPPED        => open,
    CLKFBSTOPPED        => open,
    PWRDWN              => '0',
    RST                 => rst_i
    );

  rst_serdes  <= not pll_serdes_locked;

  U_serdes: entity work.oserdes_8_to_1_7series
  generic map(
    SYS_W => 1,
    DEV_W => 8
  )
  port map(
    DATA_OUT_FROM_DEVICE => serdes_i,
    DATA_OUT_TO_PINS(0)  => serdes_o,
    CLK_IN               => pll_serdes_out,
    CLK_DIV_IN           => clk_i,
    IO_RESET             => rst_serdes
  );

  pll_serdes_locked_o <= pll_serdes_locked;

end architecture;
