-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 Nikhef (www.nikhef.nl/en/)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : WhiteRabbit PTP Core
-- Project    : WhiteRabbit
-------------------------------------------------------------------------------
-- File       : refclk_phase_sampler_10m.vhd
-- Author(s)  : Peter Jansweijer <peterj@nikhef.nl>
-- Company    : Nikhef
-- Created    : 2025-02-27
-- Last update: 2025-02-28
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Phase sampler to determine the phase between a 10 MHz
-- reference clock and the 62.5 MHz White Rabbit Reference clock
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gencores_pkg.all;

entity refclk_phase_sampler_10m is
  port (
    ---------------------------------------------------------------------------
    -- Clocks
    ---------------------------------------------------------------------------
    clk_10m_i          : in  std_logic;  -- 10 MHz Reference Clock
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
    lock_sweep_phase_o : out std_logic_vector(4 downto 0)
    );

end entity refclk_phase_sampler_10m;

architecture struct of refclk_phase_sampler_10m is

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  -- 25 lock patterns "a" (10 MHz lagging 62.5 MHz)
  constant lock_pattern_1a    : std_logic_vector(24 downto 0) :=  "1110001110001110001110000"; -- 0x1c71c70
  constant lock_pattern_2a    : std_logic_vector(24 downto 0) :=  "0111000111000111000111000"; -- 0x0e38e38
  constant lock_pattern_3a    : std_logic_vector(24 downto 0) :=  "0011100011100011100011100"; -- 0x071c71c
  constant lock_pattern_4a    : std_logic_vector(24 downto 0) :=  "0001110001110001110001110"; -- 0x038e38e
  constant lock_pattern_5a    : std_logic_vector(24 downto 0) :=  "0000111000111000111000111"; -- 0x01c71c7
  constant lock_pattern_6a    : std_logic_vector(24 downto 0) :=  "1000011100011100011100011"; -- 0x10e38e3
  constant lock_pattern_7a    : std_logic_vector(24 downto 0) :=  "1100001110001110001110001"; -- 0x1871c71
  constant lock_pattern_8a    : std_logic_vector(24 downto 0) :=  "1110000111000111000111000"; -- 0x1c38e38
  constant lock_pattern_9a    : std_logic_vector(24 downto 0) :=  "0111000011100011100011100"; -- 0x0e1c71c
  constant lock_pattern_10a   : std_logic_vector(24 downto 0) :=  "0011100001110001110001110"; -- 0x070e38e
  constant lock_pattern_11a   : std_logic_vector(24 downto 0) :=  "0001110000111000111000111"; -- 0x03871c7
  constant lock_pattern_12a   : std_logic_vector(24 downto 0) :=  "1000111000011100011100011"; -- 0x11c38e3
  constant lock_pattern_13a   : std_logic_vector(24 downto 0) :=  "1100011100001110001110001"; -- 0x18e1c71
  constant lock_pattern_14a   : std_logic_vector(24 downto 0) :=  "1110001110000111000111000"; -- 0x1c70e38
  constant lock_pattern_15a   : std_logic_vector(24 downto 0) :=  "0111000111000011100011100"; -- 0x0e3871c
  constant lock_pattern_16a   : std_logic_vector(24 downto 0) :=  "0011100011100001110001110"; -- 0x071c38e
  constant lock_pattern_17a   : std_logic_vector(24 downto 0) :=  "0001110001110000111000111"; -- 0x038e1c7
  constant lock_pattern_18a   : std_logic_vector(24 downto 0) :=  "1000111000111000011100011"; -- 0x11c70e3
  constant lock_pattern_19a   : std_logic_vector(24 downto 0) :=  "1100011100011100001110001"; -- 0x18e3871
  constant lock_pattern_20a   : std_logic_vector(24 downto 0) :=  "1110001110001110000111000"; -- 0x1c71c38
  constant lock_pattern_21a   : std_logic_vector(24 downto 0) :=  "0111000111000111000011100"; -- 0x0e38e1c
  constant lock_pattern_22a   : std_logic_vector(24 downto 0) :=  "0011100011100011100001110"; -- 0x071c70e
  constant lock_pattern_23a   : std_logic_vector(24 downto 0) :=  "0001110001110001110000111"; -- 0x038e387
  constant lock_pattern_24a   : std_logic_vector(24 downto 0) :=  "1000111000111000111000011"; -- 0x11c71c3
  constant lock_pattern_25a   : std_logic_vector(24 downto 0) :=  "1100011100011100011100001"; -- 0x18e38e1

-- 25 lock patterns "b" (10 MHz leading 62.5 MHz)
  constant lock_pattern_1b    : std_logic_vector(24 downto 0) :=  "1110001110001110001111000"; -- 0x1c71c78
  constant lock_pattern_2b    : std_logic_vector(24 downto 0) :=  "0111000111000111000111100"; -- 0x0e38e3c
  constant lock_pattern_3b    : std_logic_vector(24 downto 0) :=  "0011100011100011100011110"; -- 0x071c71e
  constant lock_pattern_4b    : std_logic_vector(24 downto 0) :=  "0001110001110001110001111"; -- 0x038e38f
  constant lock_pattern_5b    : std_logic_vector(24 downto 0) :=  "1000111000111000111000111"; -- 0x11c71c7
  constant lock_pattern_6b    : std_logic_vector(24 downto 0) :=  "1100011100011100011100011"; -- 0x18e38e3
  constant lock_pattern_7b    : std_logic_vector(24 downto 0) :=  "1110001110001110001110001"; -- 0x1c71c71
  constant lock_pattern_8b    : std_logic_vector(24 downto 0) :=  "1111000111000111000111000"; -- 0x1e38e38
  constant lock_pattern_9b    : std_logic_vector(24 downto 0) :=  "0111100011100011100011100"; -- 0x0f1c71c
  constant lock_pattern_10b   : std_logic_vector(24 downto 0) :=  "0011110001110001110001110"; -- 0x078e38e
  constant lock_pattern_11b   : std_logic_vector(24 downto 0) :=  "0001111000111000111000111"; -- 0x03c71c7
  constant lock_pattern_12b   : std_logic_vector(24 downto 0) :=  "1000111100011100011100011"; -- 0x11e38e3
  constant lock_pattern_13b   : std_logic_vector(24 downto 0) :=  "1100011110001110001110001"; -- 0x18f1c71
  constant lock_pattern_14b   : std_logic_vector(24 downto 0) :=  "1110001111000111000111000"; -- 0x1c78e38
  constant lock_pattern_15b   : std_logic_vector(24 downto 0) :=  "0111000111100011100011100"; -- 0x0e3c71c
  constant lock_pattern_16b   : std_logic_vector(24 downto 0) :=  "0011100011110001110001110"; -- 0x071e38e
  constant lock_pattern_17b   : std_logic_vector(24 downto 0) :=  "0001110001111000111000111"; -- 0x038f1c7
  constant lock_pattern_18b   : std_logic_vector(24 downto 0) :=  "1000111000111100011100011"; -- 0x11c78e3
  constant lock_pattern_19b   : std_logic_vector(24 downto 0) :=  "1100011100011110001110001"; -- 0x18c3c71
  constant lock_pattern_20b   : std_logic_vector(24 downto 0) :=  "1110001110001111000111000"; -- 0x1c71e38
  constant lock_pattern_21b   : std_logic_vector(24 downto 0) :=  "0111000111000111100011100"; -- 0x0e38f1c
  constant lock_pattern_22b   : std_logic_vector(24 downto 0) :=  "0011100011100011110001110"; -- 0x071c78e
  constant lock_pattern_23b   : std_logic_vector(24 downto 0) :=  "0001110001110001111000111"; -- 0x038e3c7
  constant lock_pattern_24b   : std_logic_vector(24 downto 0) :=  "1000111000111000111100011"; -- 0x11c71e3
  constant lock_pattern_25b   : std_logic_vector(24 downto 0) :=  "1100011100011100011110001"; -- 0x18e38f1

  signal sampled_10m          : std_logic;
  signal shift_reg            : std_logic_vector(24 downto 0) := (others => '0');
  signal captured_pattern     : std_logic_vector(24 downto 0) := (others => '0');
  signal lock_sweep_phase     : std_logic_vector(4 downto 0) := (others => '0');

--  COMPONENT ila_0
--  
--  PORT (
--      clk : IN STD_LOGIC;
--  
--      probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--      probe1 : IN STD_LOGIC_VECTOR(24 DOWNTO 0);
--      probe2 : IN STD_LOGIC_VECTOR(4 DOWNTO 0)
--  );
--  END COMPONENT  ;

begin  -- architecture struct

  -- The WR reference clock = 62.5 MHz (16 ns) and the external frequency 10 MHz (100 ns).
  -- The Least Common Multiplier (LCM): LCM(16, 100) = 400 ns which means that after
  -- 400 / 16 = 25 clock ticks of the WR reference clock, both clocks are in phase again.
  -- In other words, there are 25 possible phase lock positions.
  -- The clk_10m_i is sampled with clk_62m5_i and the samples are stored in a shift register.
  -- this shift register needs to be (at least) 25 bits since the pattern repeats after 25 WR
  -- reference clock ticks. The 25 repeating patterns are:
  -- 0x1c71c70, 0x0e38e38, etc. when clk_10m_i slightly lags the rising edges of clk_62m5_i
  -- 0x1c71c78, 0x0e38e3c, etc. when clk_10m_i slightly leads the rising edges of clk_62m5_i
  -- so due to a possibly small phase difference between the clocks (leading or lagging
  -- eachother) there are in fact 50 possible repeating patterns that reflect the 25 phase
  -- lock positions in sets of two patterns:
  -- 1:  "1110001110001110001110000" = 0x1c71c70 or "1110001110001110001111000" = 0x1c71c78 (i.e., lock_pattern_1a or lock_pattern_1b)
  -- 2:  "0111000111000111000111000" = 0x0e38e38 or "0111000111000111000111100" = 0x0e38e3c
  --                 :                     :                    :                     :
  -- 25: "1100011100011100011100001" = 0x18e38e1 or "1100011100011100011110001" = 0x18e38f1
  -- NOTE-1: clk_10m_i must have 50% duty cycle!
  -- NOTE-2: although clk_10m_i and the 62.5 MHz WR reference clock are phase locked, they must
  --         have a clear phase offset in order to unambiguously sample clk_10m_i.

  -- The pattern is captured by pps_csync_i at the WR reference clock cycle that is destined
  -- to be the "start of a second". The captured value shows at what position the WR
  -- reference clock locked with respect to the 10 MHz oscillator frequency. Only one of
  -- the 25 phase lock positions (number 1) is allowed for the others lock_sweep_o = '1'.
  -- Output phase_o is an index to 1 of the 25 phase offsets.

  U_sample_62m5 : gc_sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_62m5_i,
      rst_n_i  => '1',
      data_i   => clk_10m_i,
      synced_o => sampled_10m);

  p_quantify_phase : process(clk_62m5_i)
  begin
    if rising_edge(clk_62m5_i) then

      -- shift right and track last 5 bits
      shift_reg <= sampled_10m & shift_reg(shift_reg'high downto shift_reg'low + 1);

      if pps_csync_i = '1' then
        captured_pattern <= shift_reg;
      end if;
    end if;
  end process;

  p_phase_mux : process(captured_pattern)
  begin
    case captured_pattern is
      when lock_pattern_1a | lock_pattern_1b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(1,lock_sweep_phase'length));
      when lock_pattern_2a | lock_pattern_2b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(2,lock_sweep_phase'length));
      when lock_pattern_3a | lock_pattern_3b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(3,lock_sweep_phase'length));
      when lock_pattern_4a | lock_pattern_4b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(4,lock_sweep_phase'length));
      when lock_pattern_5a | lock_pattern_5b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(5,lock_sweep_phase'length));
      when lock_pattern_6a | lock_pattern_6b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(6,lock_sweep_phase'length));
      when lock_pattern_7a | lock_pattern_7b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(7,lock_sweep_phase'length));
      when lock_pattern_8a | lock_pattern_8b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(8,lock_sweep_phase'length));
      when lock_pattern_9a | lock_pattern_9b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(9,lock_sweep_phase'length));
      when lock_pattern_10a | lock_pattern_10b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(10,lock_sweep_phase'length));
      when lock_pattern_11a | lock_pattern_11b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(11,lock_sweep_phase'length));
      when lock_pattern_12a | lock_pattern_12b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(12,lock_sweep_phase'length));
      when lock_pattern_13a | lock_pattern_13b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(13,lock_sweep_phase'length));
      when lock_pattern_14a | lock_pattern_14b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(14,lock_sweep_phase'length));
      when lock_pattern_15a | lock_pattern_15b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(15,lock_sweep_phase'length));
      when lock_pattern_16a | lock_pattern_16b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(16,lock_sweep_phase'length));
      when lock_pattern_17a | lock_pattern_17b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(17,lock_sweep_phase'length));
      when lock_pattern_18a | lock_pattern_18b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(18,lock_sweep_phase'length));
      when lock_pattern_19a | lock_pattern_19b=>
        lock_sweep_phase <= std_logic_vector(to_unsigned(19,lock_sweep_phase'length));
      when lock_pattern_20a | lock_pattern_20b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(20,lock_sweep_phase'length));
      when lock_pattern_21a | lock_pattern_21b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(21,lock_sweep_phase'length));
      when lock_pattern_22a | lock_pattern_22b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(22,lock_sweep_phase'length));
      when lock_pattern_23a | lock_pattern_23b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(23,lock_sweep_phase'length));
      when lock_pattern_24a | lock_pattern_24b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(24,lock_sweep_phase'length));
      when lock_pattern_25a | lock_pattern_25b =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(25,lock_sweep_phase'length));
      when others =>
        lock_sweep_phase <= std_logic_vector(to_unsigned(0,lock_sweep_phase'length));
    end case;
  end process;

  lock_sweep_o <= '0' when (lock_sweep_phase = std_logic_vector(to_unsigned(1,lock_sweep_phase'length))) else '1';
  lock_sweep_phase_o <= lock_sweep_phase;

--  your_instance_name : ila_0
--  PORT MAP (
--      clk => clk_62m5_i,
--      probe0(0) => pps_csync_i, 
--      probe1 => captured_pattern,
--      probe2 => lock_sweep_phase
--  );

end architecture struct;
