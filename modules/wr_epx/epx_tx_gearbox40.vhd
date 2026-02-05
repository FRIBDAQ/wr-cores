-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  10G TX gearbox (40b)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity epx_tx_gearbox40 is
  port (
    clk_i : in  std_logic;
    rst_n_i : in std_logic;

    data_i : in std_logic_vector(0 to 65);
    ready_o : out std_logic;

    data_o : out std_logic_vector(0 to 39)
  );
end;

architecture arch of epx_tx_gearbox40 is
  subtype t_shift is natural range 0 to 66 - 2;
  signal shift : t_shift;
  signal ff : std_logic_vector(0 to 40 + 66 - 2 - 1);
  signal ready : std_logic;
begin
  ready_o <= ready;

  process (clk_i)
    variable nshift : t_shift;
  begin
    if rising_edge(clk_i) then
      data_o <= ff (0 to 39);
      report natural'image(shift) & ", ready=" & std_logic'image(ready);
      ff (0 to 63) <= ff (40 to 103);
      if ready = '1' then
        ff (shift to shift + 65) <= data_i;
      end if;

      if rst_n_i = '0' then
        shift <= 0;
        ready <= '1';
      else
        if ready = '0' then
          --  No new data, just shift.
          nshift := shift - 40;
          ready <= '1';
        else
          nshift := shift + 66 - 40;
          if nshift >= 40 then
            ready <= '0';
          else
            ready <= '1';
          end if;
        end if;
        shift <= nshift;
      end if;
    end if;
  end process;
end arch;
