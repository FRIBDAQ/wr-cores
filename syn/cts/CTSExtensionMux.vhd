----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/05/2025 03:56:24 PM
-- Design Name: 
-- Module Name: CTSExtensionMux - RTL
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity CTSExtensionMux is
    Port ( A0_i           : in STD_LOGIC;
           A1_i           : in STD_LOGIC;
           eeprom_scl_i   : in  STD_LOGIC;
           eeprom_scl_o   : out STD_LOGIC;
           eeprom_sda_i   : in  STD_LOGIC;
           eeprom_sda_o   : out STD_LOGIC;
           A0_o           : out   STD_LOGIC;
           A1_o           : out   STD_LOGIC;
           DA_b           : inout STD_LOGIC;
           DB_b           : inout STD_LOGIC;
           plldac_sclk_i  : in STD_LOGIC;
           plldac_din_i   : in STD_LOGIC);
end CTSExtensionMux;

architecture RTL of CTSExtensionMux is

    signal eeprom_scl_out, eeprom_scl_in : std_logic;
    signal eeprom_sda_out, eeprom_sda_in : std_logic;
        
    signal dacpll_off     : std_logic;
    signal DA_out, DA_in  : std_logic;
    signal DB_out, DB_in  : std_logic;
    signal DA_t, DB_t     : std_logic;

begin

    dacpll_off <= A0_i and A1_i;

    DA_out <= '0' when dacpll_off = '1' else plldac_sclk_i;
    DB_out <= '0' when dacpll_off = '1' else plldac_din_i;

    mux_da_inst : IOBUF
    port map (
      IO => DA_b,
      O  => DA_in,
      I  => DA_out,
      T  => DA_t);
    DA_t <= '0' when eeprom_sda_out = '0' or dacpll_off = '1' else '1';
    eeprom_sda_in <= DA_in;

    mux_db_inst : IOBUF
    port map (
      IO => DB_b,
      O  => DB_in,
      I  => DB_out,
      T  => DB_t);
    DB_t <= '0' when eeprom_scl_out = '0' or dacpll_off = '1' else '1';
    eeprom_scl_in <= DB_in;

end RTL;
