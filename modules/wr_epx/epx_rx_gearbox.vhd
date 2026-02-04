-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  10G RX gearbox (64b)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.epx_pkg.all;

entity epx_rx_gearbox is
  port (
    clk_i : in  std_logic;
    rst_n_i : in std_logic;

    data_i : in std_logic_vector(0 to 63);

    data_o : out t_blk66;
    valid_o : out std_logic;
    lock_o : out std_logic
  );
end;

architecture arch of epx_rx_gearbox is
  signal shift : natural range 0 to 127;
  signal ff : std_logic_vector(0 to 131);

  signal txdata : std_logic_vector(0 to 65);
  signal is_lock : std_logic;
  subtype t_lock_cnt is natural range 0 to 63;
  signal lock_cnt : t_lock_cnt;
begin
  data_o <= txdata;
  lock_o <= is_lock;

  process (clk_i)
    variable sync_valid : boolean;
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        shift <= 0;
        valid_o <= '0';
        is_lock <= '0';
      else
        --  Extract block
        txdata <= ff (shift to shift + 65);

        --  Insert data.
        --  Padding is appended to avoid bound errors on extraction.
        ff <= ff (64 to 127) & data_i & "XXXX";

        --  Sync patterns detection (on previous block)
        sync_valid := txdata (0 to 1) = "01" or txdata(0 to 1) = "10";
          
        if shift >= 64 then
          --  Not enough data, not valid
          shift <= shift - 64;
          valid_o <= '0';
        else
          --  Data are valid
          valid_o <= '1';
          shift <= shift + 2;

          --  Gearbox lock (set when sync patterns are in bit 0:1)
          if is_lock = '1' then
            if sync_valid then
              --  Increase the lock counter
              if lock_cnt < t_lock_cnt'high then
                lock_cnt <= lock_cnt + 1;
              end if;
            else
              --  Not synced
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
                shift <= shift + 1;
              else
                lock_cnt <= 1;
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
end arch;
