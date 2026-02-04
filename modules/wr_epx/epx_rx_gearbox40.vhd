-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  10G RX gearbox (40b)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.epx_pkg.all;

entity epx_rx_gearbox40 is
  port (
    clk_i : in  std_logic;
    rst_n_i : in std_logic;

    --  Input from the transceiver
    --  Bit 0 is the first received bit.
    data_i : in std_logic_vector(0 to 39);

    --  66b output
    data_o : out t_blk66;
    valid_o : out std_logic;

    lock_o : out std_logic
  );
end;

architecture arch of epx_rx_gearbox40 is
  --  We try to keep the shift amount so that data_o always
  --  contains a bit of the first word.  So ideally the amount
  --  should be between 0 and (width - 1).
  --  But if the last amount was (width - 1), the next amount
  --  will be 66 - width + (width - 1) = 65.
  --  We should add 1 to this upper bound in case of slip.
  subtype t_shift is natural range 0 to 40 + 66 - 40;
  signal shift : t_shift;
  signal ff : std_logic_vector(0 to 3*40 - 1);

  signal txdata : std_logic_vector(0 to 65);
  signal is_lock, valid : std_logic;
  subtype t_lock_cnt is natural range 0 to 63;
  signal lock_cnt : t_lock_cnt;

  signal slip : std_logic;
begin
  data_o <= txdata;
  lock_o <= is_lock;
  valid_o <= valid;

  process (clk_i)
    variable nshift : t_shift;
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        shift <= 0;
        valid <= '0';
      else
        --  Shift and append data.
        ff <= ff (40 to 3*40-1) & data_i;

        if shift >= 40 then
          --  Not enough data, not valid
          valid <= '0';
          txdata <= (others => 'X');
          --  As no data are output, just follow the shift in ff.
          nshift := shift - 40;
        else
          --  Data are valid
          valid <= '1';
          txdata <= ff (shift to shift + 65);
          --  As data are output, skip 66b but also follow the shift
          nshift := shift + 66 - 40;
        end if;

        if slip = '1' then
          nshift := nshift + 1;
        end if;
        shift <= nshift;
      end if;
    end if;
  end process;

  process (clk_i)
    variable sync_valid : boolean;
  begin
    if rising_edge(clk_i) then
      slip <= '0';
      if rst_n_i = '0' then
        is_lock <= '0';
      elsif valid = '1' then
        --  Sync patterns detection (on previous block)
        sync_valid := txdata (0 to 1) = "01" or txdata(0 to 1) = "10";

        --  Gearbox lock (set when sync patterns are in bit 0:1)
        if is_lock = '1' then
          if sync_valid then
            --  Increase the lock counter
            if lock_cnt < t_lock_cnt'high then
              lock_cnt <= lock_cnt + 1;
            end if;
          else
            --  Sync error
            if lock_cnt < t_lock_cnt'high then
              --  Lost lock
              is_lock <= '0';
            end if;
            lock_cnt <= 0;
          end if;
        else
          if sync_valid then
            --  Increase the lock counter
            if lock_cnt < t_lock_cnt'high then
              lock_cnt <= lock_cnt + 1;
            else
              --  Now locked.
              is_lock <= '1';
            end if;
          else
            if lock_cnt /= 0 then
              --  Insert a shift (after a delay)
              lock_cnt <= 0;
              slip <= '1';
            else
              lock_cnt <= 1;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
end arch;
