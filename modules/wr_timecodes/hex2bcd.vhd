-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2012 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : Binaray to BCD converter
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : hex2bcd.vhd
-- Author     : Harvey Leicester
-- Company    : CERN BE-CEM-EDL
-- Created    : 2024-11-11
-- Last update: 2024-11-11
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- convert binary to binary coded decimal
-- Based on cute-wr by Guanghua Gong
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

---   Shift-and-Add-3 algorigthm (Double dabble conversion algorithm)
---   It takes g_hex_width*2 cycles

entity hex2bcd is
   generic( 
      g_hex_width  : integer := 8;    
      g_bcd_digits : integer := 8    
   );
   port(
      clk_i       : in std_logic;
      rst_n_i     : in std_logic;
      hex_i       : in std_logic_vector (g_hex_width-1 downto 0);
      hex_valid_i : in std_logic;
      bcd_o       : out std_logic_vector (g_bcd_digits*4-1 downto 0);
      bcd_valid_o : out std_logic
   );
end entity hex2bcd;

architecture rtl of hex2bcd is

   type t_convert_fsm_state is (S_IDLE, S_SHIFT, S_CHECK_ADD,S_DONE);
   signal fsm_state : t_convert_fsm_state;
   signal cnt : integer range 0 to g_hex_width-1;
   signal bcd_temp: unsigned(g_bcd_digits*4-1 downto 0);
   signal hex_temp: unsigned(g_hex_width-1 downto 0);
   signal hex_valid_1d : std_logic;

begin

  p_conveter: process(clk_i)
  begin
    if rising_edge(clk_i) then 
      if(rst_n_i = '0') then
         bcd_o    <= (others => '0');
         bcd_temp     <= (others => '0');
         hex_temp     <= (others => '0');
         hex_valid_1d <= '0';
         BCD_valid_o  <= '0';
         fsm_state<= S_IDLE;
         cnt      <= 0;
      else  
         hex_valid_1d <= hex_valid_i;
         case(fsm_state) is
              when S_IDLE => 
                   if hex_valid_1d = '0' and hex_valid_i = '1' then
                      bcd_temp      <= (others => '0');
                      BCD_valid_o  <= '0';
                      hex_temp      <= unsigned(hex_i);
                      fsm_state    <= S_SHIFT;
                      cnt          <= 0;
                   end if;
              when S_SHIFT => 
                      bcd_temp <= bcd_temp(g_bcd_digits*4-2 downto 0) & hex_temp(g_hex_width-1);
                      hex_temp <= hex_temp(g_hex_width-2 downto 0) & '0';
                    if cnt = g_hex_width-1 then
                      fsm_state <= S_DONE;
                    else
                      cnt       <= cnt + 1;
                      fsm_state    <= S_CHECK_ADD;        
                    end if;
              when S_CHECK_ADD => 
                      for i in 0 to g_bcd_digits-1 loop
                        if(bcd_temp (i*4+3 downto i*4) > 4) then  --add 3 to each digit that are bigger than 4!
                          bcd_temp(i*4+3 downto i*4) <= bcd_temp(i*4+3 downto i*4) + "0011";
                        end if;
                      end loop;
                      fsm_state <= S_SHIFT;
              when S_DONE =>
                   bcd_o       <= std_logic_vector(bcd_temp);
                   bcd_valid_o <= '1';
                   fsm_state   <= S_IDLE;  
              when others =>      fsm_state  <= S_IDLE; 
         end case;
      end if;
    end if;
  end process;

end rtl;
