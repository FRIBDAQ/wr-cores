-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  10G RX descrambler
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.epx_pkg.all;

entity epx_rx_descrambler is
  generic (
    --  Enable descrambler.  Should always be true unless you need to debug
    --  and see unscrambled data in the waveforms.
    g_enable : boolean := true
  );
  port (
    clk_i : in  std_logic;
    rst_n_i : in std_logic;

    data_i : in t_blk66;
    valid_i : in std_logic;
    lock_i : in std_logic;

    data_o : out t_blk66;
    valid_o : out std_logic;
    lock_o : out std_logic
  );
end;

architecture arch of epx_rx_descrambler is
  signal lfsr : std_logic_vector(0 to 57);
begin
  process(clk_i)
    variable v_lfsr : std_logic_vector(0 to 57);
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        valid_o <= '0';
        lock_o <= '0';
        lfsr <= (others => '0');
        data_o <= (others => 'X');
      elsif valid_i = '1' and lock_i = '1' then
        v_lfsr := lfsr;
        for i in 0 to 63 loop
          if g_enable then
            data_o(2 + i) <= data_i(2 + i) xor v_lfsr(38) xor v_lfsr(57);
          else
            data_o(2 + i) <= data_i(2 + i);
          end if;
          v_lfsr := data_i(2 + i) & v_lfsr(0 to 56);
        end loop;
        data_o(0 to 1) <= data_i(0 to 1);
        lfsr <= v_lfsr;
        valid_o <= '1';
        lock_o <= '1';
      else
        valid_o <= '0';
        lock_o <= lock_i;
      end if;
    end if;
  end process;
end arch;
