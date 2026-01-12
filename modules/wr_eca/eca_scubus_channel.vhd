-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2013 GSI / Wesley W. Terpstra <w.terpstra@gsi.de> / Stefan Rauch <s.rauch@gsi.de>
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--! @file eca_gpio_channel.vhd
--! @brief ECA-GPIO Adapter
--! @author Wesley W. Terpstra <w.terpstra@gsi.de>
--! @author Stefan Rauch <s.rauch@gsi.de>
--!
--! This component takes an action channel and sends the tag to the SCU bus
--!
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.eca_pkg.all;

entity eca_scubus_channel is
  port(
    clk_i     : in  std_logic;
    rst_n_i   : in  std_logic;
    channel_i : in  t_channel;
    tag_valid : out std_logic;
    tag       : out std_logic_vector(31 downto 0));  
end eca_scubus_channel;

architecture rtl of eca_scubus_channel is
  -- Out of principle, tell quartus to leave my design alone.
  attribute altera_attribute : string; 
  attribute altera_attribute of rtl : architecture is "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF";
  signal s_tag    : std_logic_vector(31 downto 0);
  signal s_valid  : std_logic;
  type state_type is (idle, cnt);
  signal sm_state : state_type;
  
begin
  
  tag_valid <= s_valid;
  tag       <= s_tag;

  main : process(clk_i) is
    variable v_cnt : unsigned(1 downto 0);
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        s_tag <= (others => '0');
        s_valid <= '0';
        v_cnt := (others => '0');
      else
        case sm_state is
        
          when idle =>
            s_valid <= '0';
            v_cnt := (others => '0');
            if channel_i.valid = '1' then
              s_tag     <= channel_i.tag;
              sm_state  <= cnt;
            end if;
            
          when cnt =>
            s_valid <= '1';
            if v_cnt = 3 then
              sm_state <= idle;
            else
              v_cnt := v_cnt + 1;
            end if;
               
        end case;
      

      end if;
    end if;
  end process;
  
end rtl;
