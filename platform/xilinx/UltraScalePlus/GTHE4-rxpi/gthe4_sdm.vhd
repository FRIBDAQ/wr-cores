-------------------------------------------------------------------------------
-- Title      : SDM adapter for Xilinx GTHe4 (and probably others)
-- Project    : WR PTP Core
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

entity gthe4_sdm is
  port (
    --  System clock (same as WR core clk_sys)
    clk_62m5_i  : in std_logic;
    rst_n_i     : in std_logic;

    --  WR dac input
    dac_data_i : in  std_logic_vector(23 downto 0);
    dac_load_i : in  std_logic;

    --  sdm output
    sdm_data_o   : out std_logic_vector(24 downto 0);
    sdm_toggle_o : out std_logic
  );
end;

architecture top of gthe4_sdm is
  signal sdm_cnt : unsigned(5 downto 0);
  --  Boot bootstrap: until the SoftPLL issues its first DAC write, we must
  --  self-load the (biased) dac_data_i into the QPLL SDM so it comes up at
  --  N ~= nominal instead of the bare integer fbdiv.  `started` latches once
  --  the SoftPLL takes over; `boot_cnt` paces the auto-loads.  During this
  --  phase dac_data_i is constant (SoftPLL DAC = 0), so repeatedly latching it
  --  loads an identical N and cannot disturb the VCO frequency (no GT flap).
  signal started  : std_logic;
  signal boot_cnt : unsigned(12 downto 0);
begin
  process(clk_62m5_i)
  begin
    if rising_edge(clk_62m5_i) then
      if rst_n_i = '0' then
        sdm_cnt <= (others => '0');
        sdm_toggle_o <= '0';
        sdm_data_o <= (others => '0');
        started  <= '0';
        boot_cnt <= (others => '0');
      else
        if sdm_cnt = 0 then
          --  Idle, can accept a new value
          if dac_load_i = '1' then
            --  Real SoftPLL write: take over, stop the bring-up auto-load.
            --  Reformat.
            --  According to 73205, only LSB are significant.
            started <= '1';
            sdm_data_o <= (others => '0');
            sdm_data_o(23 downto 0) <= dac_data_i;
            sdm_cnt <= (others => '1');
          elsif started = '0' then
            --  Bring-up: periodically (re)load the biased dac_data_i until the
            --  SoftPLL takes over, so the QPLL latches N ~= nominal whenever it
            --  leaves reset (its reset timer differs from ours).
            if boot_cnt = 0 then
              sdm_data_o <= (others => '0');
              sdm_data_o(23 downto 0) <= dac_data_i;
              sdm_cnt <= (others => '1');
              boot_cnt <= (others => '1');
            else
              boot_cnt <= boot_cnt - 1;
            end if;
          end if;
        else
          --  FB CLK should be way higher than system clock
          if sdm_cnt(5 downto 4) = "00" then
            sdm_toggle_o <= '0';
          elsif sdm_cnt(5 downto 4) /= "11" then
            sdm_toggle_o <= '1';
          end if;
          sdm_cnt <= sdm_cnt - 1;
        end if;
      end if;
    end if;
  end process;
end top;