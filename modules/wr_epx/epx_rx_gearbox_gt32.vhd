-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  10G RX gearbox interface (for GTHe4)
-------------------------------------------------------------------------------

--  Driver for GTHe4 (and other) RX gearbox:
--   reformat data
--   synchronization
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.epx_pkg.all;

entity epx_rx_gearbox_gt32 is
  port (
    clk_i : in  std_logic;
    rst_n_i : in std_logic;

    --  From the GTH
    rx_data_i : in std_logic_vector(31 downto 0);
    rx_data_valid_i : in std_logic;
    rx_header_i : in std_logic_vector(1 downto 0);
    rx_header_valid_i : in std_logic;

    data_o : out t_blk66;
    valid_o : out std_logic;
    rx_gearbox_slip_o : out std_logic;
    lock_o : out std_logic
  );
end;

architecture arch of epx_rx_gearbox_gt32 is
  --  66b/64b sync
  type t_sync_fsm is (S_INIT, S_RESET, S_TEST, S_VALID, S_INVALID);
  signal sync_state                         : t_sync_fsm;
  signal sync_cnt, sync_invalid_cnt         : natural range 0 to 63;
  signal sync_locked                        : std_logic;
begin
  process (clk_i)
  begin
    if rising_edge(clk_i) then
      valid_o <= '0';
      if rx_data_valid_i = '1' then
        if rx_header_valid_i = '1' then
          data_o(0 to 1) <= rx_header_i(1 downto 0);
          data_o(2 to 33) <= rx_data_i;
        else
          data_o(34 to 65) <= rx_data_i;
          valid_o <= '1';
        end if;
      end if;
    end if;
  end process;


  process(clk_i)
  begin
    if rising_edge(clk_i) then
      rx_gearbox_slip_o <= '0';

      if rst_n_i = '0' then
        sync_state <= S_INIT;
      else
        case sync_state is
          when S_INIT =>
            sync_locked <= '0';
            sync_state <= S_RESET;
          when S_RESET =>
            sync_cnt <= 0;
            sync_invalid_cnt <= 0;
            sync_state <= S_TEST;
          when S_TEST =>
            if rx_header_valid_i = '1' then
              if rx_header_i(1 downto 0) = "01" or rx_header_i(1 downto 0) = "10" then
                sync_state <= S_VALID;
              else
                sync_state <= S_INVALID;
              end if;
            end if;
          when S_VALID =>
            if sync_cnt = 63 then
              if sync_invalid_cnt = 0 then
                sync_locked <= '1';
              end if;
              sync_state <= S_RESET;
            else
              sync_cnt <= sync_cnt + 1;
              sync_state <= S_TEST;
            end if;
          when S_INVALID =>
            if sync_invalid_cnt = 15 or sync_locked = '0' then
              sync_locked <= '0';
              --  Slip.
              rx_gearbox_slip_o <= '1';
              sync_state <= S_RESET;
            else
              sync_invalid_cnt <= sync_invalid_cnt + 1;
              sync_state <= S_TEST;
            end if;
        end case;
      end if;
    end if;
  end process;

  lock_o <= sync_locked;
end arch;
