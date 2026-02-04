-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  10G TX gearbox (64b)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity epx_tx_gearbox is
  port (
    clk : in  std_logic;
    rst_n_i : in std_logic;

    data_i : in std_logic_vector(0 to 65);
    ready_o : out std_logic;

    data_o : out std_logic_vector(0 to 63)
  );
end;

architecture arch of epx_tx_gearbox is
  signal count : natural;
  signal ff : std_logic_vector(0 to 129);
  signal ready : std_logic;
begin
  ready_o <= ready;

  process (clk)
  begin
    if rising_edge(clk) then
      data_o <= ff (0 to 63);
      ff (0 to 65) <= ff (64 to 129);
      if ready = '1' then
        ff (count to count + 65) <= data_i;
      end if;
      ready <= '1';

      if rst_n_i = '0' then
        count <= 0;
      elsif count = 64 then
        ready <= '0';
        count <= 0;
      else
        count <= count + 2;
      end if;
    end if;
  end process;
end arch;
