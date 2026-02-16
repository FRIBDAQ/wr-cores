-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 Nikhef (www.nikhef.nl/en/)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : WhiteRabbit PTP Core
-- Project    : WhiteRabbit
-------------------------------------------------------------------------------
-- File       : refclk_phase_sampler_100m.vhd
-- Author(s)  : Peter Jansweijer <peterj@nikhef.nl>
-- Company    : Nikhef
-- Created    : 2023-07-07
-- Last update: 2024-05-04
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Phase sampler to determine the phase between a 100 MHz
-- reference clock and the 62.5 MHz White Rabbit Reference clock
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gencores_pkg.all;

entity refclk_phase_sampler_100m is
  port (
    ---------------------------------------------------------------------------
    -- Clocks
    ---------------------------------------------------------------------------
    clk_100m_i         : in  std_logic;  -- 100 MHz Reference Clock
    clk_62m5_i         : in  std_logic;  -- 62.5 MHz White Rabbit Reference clock

    ---------------------------------------------------------------------------
    -- Phase sample input (synchronous to clk_62m5_i)
    ---------------------------------------------------------------------------
    -- Rising edge at time t=0 (usually PPS or pps_csync_o) will sample the
    -- phase between the clocks.
    pps_csync_i        : in  std_logic;

    ---------------------------------------------------------------------------
    -- Measured Phase outputs (synchronous to clk_62m5_i)
    ---------------------------------------------------------------------------
    lock_sweep_o       : out std_logic;
    lock_sweep_phase_o : out std_logic_vector(2 downto 0)
    );

end entity refclk_phase_sampler_100m;

architecture struct of refclk_phase_sampler_100m is

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- 5 lock patterns "a" (100 MHz lagging 62.5 MHz)
  constant lock_pattern_1a    : std_logic_vector(4 downto 0) := "00101"; -- 0x05
  constant lock_pattern_2a    : std_logic_vector(4 downto 0) := "10010"; -- 0x12
  constant lock_pattern_3a    : std_logic_vector(4 downto 0) := "01001"; -- 0x09
  constant lock_pattern_4a    : std_logic_vector(4 downto 0) := "10100"; -- 0x14
  constant lock_pattern_5a    : std_logic_vector(4 downto 0) := "01010"; -- 0x0a

  -- 5 lock patterns "b" (100 MHz leading 62.5 MHz)
  constant lock_pattern_1b    : std_logic_vector(4 downto 0) := "01101"; -- 0x0d
  constant lock_pattern_2b    : std_logic_vector(4 downto 0) := "10110"; -- 0x16
  constant lock_pattern_3b    : std_logic_vector(4 downto 0) := "01011"; -- 0x0b
  constant lock_pattern_4b    : std_logic_vector(4 downto 0) := "10101"; -- 0x15
  constant lock_pattern_5b    : std_logic_vector(4 downto 0) := "11010"; -- 0x1a

  signal sampled_100m         : std_logic;
  signal shift_reg            : std_logic_vector(4 downto 0) := (others => '0');
  signal captured_pattern     : std_logic_vector(4 downto 0) := (others => '0');
  signal lock_sweep_phase     : std_logic_vector(2 downto 0) := (others => '0');

--  COMPONENT ila_0
--  
--  PORT (
--    clk : IN STD_LOGIC;
--
--    probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--    probe1 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
--    probe2 : IN STD_LOGIC_VECTOR(2 DOWNTO 0)
--  );
--  END COMPONENT  ;

begin  -- architecture struct

  -- The WR reference clock = 62.5 MHz (16 ns) and the external frequency 100 MHz (10 ns).
  -- The Least Common Multiplier (LCM): LCM(16, 10) = 80 ns which means that after
  -- 80 / 16 = 5 clock ticks of the WR reference clock, both clocks are in phase again.
  -- In other words, there are 5 possible phase lock positions.
  -- The clk_100m_i is sampled with clk_62m5_i and the samples are stored in a shift register.
  -- this shift register needs to be (at least) 5 bits since the pattern repeats after 5 WR
  -- reference clock ticks. The 5 repeating patterns are:
  -- x05, x09, x0a, x12, x14 when clk_100m_i slightly lags the rising edges of clk_62m5_i
  -- x0d, x0b, x1a, x16, x15 when clk_100m_i slightly leads the rising edges of clk_62m5_i
  -- so due to a possibly small phase difference between the clocks (leading or lagging
  -- eachother) there are in fact 10 possible repeating patterns that reflect the 5 phase
  -- lock positions in sets of two patterns:
  -- 1: "00101" = x05 or "01101" = x0d (i.e., lock_pattern_1a or lock_pattern_1b)
  -- 2: "10010" = x12 or "10110" = x16
  -- 3: "01001" = x09 or "01011" = x0b
  -- 4: "10100" = x14 or "10101" = x15
  -- 5: "01010" = x0a or "11010" = x1a
  -- NOTE-1: clk_100m_i must have 50% duty cycle!
  -- NOTE-2: although clk_100m_i and the 62.5 MHz WR reference clock are phase locked, they must
  --         have a clear phase offset in order to unambiguously sample clk_100m_i.

  -- The pattern is captured by pps_csync_i at the WR reference clock cycle that is destined
  -- to be the "start of a second". The captured value shows at what position the WR
  -- reference clock locked with respect to the 100 MHz oscillator frequency. Only one of
  -- the 5 phase lock positions (number 1) is allowed for the others lock_sweep_o = '1'.
  -- Output phase_o is an index to 1 of the 5 phase offsets.

  U_sample_62m5 : gc_sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_62m5_i,
      rst_n_i  => '1',
      data_i   => clk_100m_i,
      synced_o => sampled_100m);

  p_quantify_phase : process(clk_62m5_i)
  begin
    if rising_edge(clk_62m5_i) then

      -- shift right and track last 5 bits
      shift_reg <= sampled_100m & shift_reg(shift_reg'high downto shift_reg'low + 1);

      if pps_csync_i = '1' then
        captured_pattern <= shift_reg;
      end if;
    end if;
  end process;

  -- NOTE: Vivado doesn't like a (lock_pattern_1a or lock_pattern_1b) in a case when statement which leads to
  -- "Choice in CASE statement alternative must be locally static.".
  p_phase_mux : process(captured_pattern)
  begin
    case captured_pattern is
      when lock_pattern_1a =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(1,lock_sweep_phase'length));
      when lock_pattern_1b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(1,lock_sweep_phase'length));
      when lock_pattern_2a =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(2,lock_sweep_phase'length));
      when lock_pattern_2b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(2,lock_sweep_phase'length));
      when lock_pattern_3a =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(3,lock_sweep_phase'length));
      when lock_pattern_3b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(3,lock_sweep_phase'length));
      when lock_pattern_4a =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(4,lock_sweep_phase'length));
      when lock_pattern_4b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(4,lock_sweep_phase'length));
      when lock_pattern_5a =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(5,lock_sweep_phase'length));
      when lock_pattern_5b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(5,lock_sweep_phase'length));
      when others =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(0,lock_sweep_phase'length));
    end case;
  end process;

  lock_sweep_o <= '0' when (lock_sweep_phase = std_logic_vector(to_unsigned(1,lock_sweep_phase'length))) else '1';
  lock_sweep_phase_o <= lock_sweep_phase;

--  your_instance_name : ila_0
--  PORT MAP (
--    clk => clk_62m5_i,
--    probe0(0) => pps_csync_i, 
--    probe1 => captured_pattern,
--    probe2 => lock_sweep_phase
--  );

end architecture struct;
