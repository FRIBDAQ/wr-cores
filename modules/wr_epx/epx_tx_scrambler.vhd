-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  10G TX scrambler
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.epx_pkg.all;

entity epx_tx_scrambler is
  generic (
    g_enable : boolean := true
  );
  port (
    clk_i : in  std_logic;
    rst_n_i : in std_logic;

    data_i : in t_blk66;
    ready_o : out std_logic;

    data_o : out t_blk66;
    ready_i : in std_logic
    );
end;

architecture arch of epx_tx_scrambler is
  signal lfsr : std_logic_vector(0 to 57);
  signal ready : std_logic;
begin
  ready_o <= ready;

  process(clk_i)
    variable v_lfsr : std_logic_vector(0 to 57);
    variable b : std_logic;
    variable data : t_blk66;
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ready <= '1';
        lfsr <= (others => '0');
        data_o <= (others => 'X');
        data := (others => 'X');
      else
        if ready = '1' then
          v_lfsr := lfsr;
          for i in 0 to 63 loop
            b := data_i(2 + i);
            if g_enable then
              b := b xor v_lfsr(38) xor v_lfsr(57);
            end if;
            data(2 + i) := b;
            v_lfsr := b & v_lfsr(0 to 56);
          end loop;

          data (0 to 1) := data_i (0 to 1);
          lfsr <= v_lfsr;
        end if;
        ready <= ready_i;

        if ready_i = '1' then
          data_o <= data;
        end if;
      end if;
    end if;
  end process;
end arch;
