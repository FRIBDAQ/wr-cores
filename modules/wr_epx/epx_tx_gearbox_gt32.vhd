-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  10G TX gearbox interface (with gthe4)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity epx_tx_gearbox_gt32 is
  port (
    clk_i : in  std_logic;
    rst_n_i : in std_logic;

    data_i : in std_logic_vector(0 to 65);
    ready_o : out std_logic;

    tx_data_o : out std_logic_vector(31 downto 0);
    tx_header_o : out std_logic_vector(1 downto 0);
    tx_sequence_o : out std_logic_vector(6 downto 0)
  );
end;

architecture arch of epx_tx_gearbox_gt32 is
  signal tx_seq_hl : std_logic;
  signal tx_sequence, tx_sequence_inc : std_logic_vector(6 downto 0);
begin
    tx_sequence_o <= tx_sequence;

    process (clk_i)
    begin
      if rising_edge(clk_i) then
        if rst_n_i = '0' then
          tx_sequence <= (others => '0');
          tx_header_o <= data_i(0 to 1);
          tx_data_o <= data_i(2 to 33);
          tx_seq_hl <= '0';
        else
          if tx_seq_hl = '0' then
            tx_data_o <= data_i(34 to 65);
            tx_seq_hl <= '1';
          else
            tx_header_o <= data_i(0 to 1);
            tx_data_o <= data_i(2 to 33);
            tx_seq_hl <= '0';
            if tx_sequence /= b"010_0000" then
              tx_sequence <= tx_sequence_inc;
            else
              tx_sequence <= (others => '0');
            end if;
          end if;
        end if;
      end if;
    end process;

    tx_sequence_inc <= std_logic_vector(unsigned(tx_sequence) + 1);

    ready_o <= '1' when tx_seq_hl = '0' and tx_sequence_inc(5 downto 0) /= b"10_0000" else '0';
end arch;
