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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity CTSExtensionMux is
    Port ( clk_10MHz_i    : in    STD_LOGIC;
           A0_i           : in    STD_LOGIC;
           A1_i           : in    STD_LOGIC;
           eeprom_scl_i   : in    STD_LOGIC;
           eeprom_scl_o   : out   STD_LOGIC;
           eeprom_sda_i   : in    STD_LOGIC;
           eeprom_sda_o   : out   STD_LOGIC;
           sfp_scl_i      : in    STD_LOGIC;
           sfp_scl_o      : out   STD_LOGIC;
           sfp_sda_i      : in    STD_LOGIC;
           sfp_sda_o      : out   STD_LOGIC;
           A0_o           : out   STD_LOGIC;
           A1_o           : out   STD_LOGIC;
           DA_b           : inout STD_LOGIC;
           DB_b           : inout STD_LOGIC;
           plldac_sclk_i  : in    STD_LOGIC;
           plldac_din_i   : in    STD_LOGIC);
end CTSExtensionMux;

architecture RTL of CTSExtensionMux is

    signal i2c_priority   : std_logic;
    signal busy_counter   : unsigned(9 downto 0);

    signal dacpll_off     : std_logic;
    signal A0_out, A1_out : std_logic;
    signal DA_out, DA_in  : std_logic;
    signal DB_out, DB_in  : std_logic;
    signal DA_t, DB_t     : std_logic;

begin

    process (clk_10MHz_i)
    begin
        if rising_edge(clk_10MHz_i)
        then
            if eeprom_scl_i = '0' or eeprom_sda_i = '0' or sfp_scl_i = '0' or sfp_sda_i = '0' then
                i2c_priority <= '1';

                busy_counter <= (others => '0');
            else
                busy_counter <= busy_counter + 1;

                if busy_counter >= 1000 then
                    i2c_priority <= '0';
                end if;
            end if;
        end if;
    end process;

    dacpll_off <= (A0_i and A1_i) or i2c_priority;

    DA_out <= plldac_sclk_i when dacpll_off = '0' else eeprom_sda_i and sfp_sda_i;
    DB_out <= plldac_din_i when dacpll_off = '0' else eeprom_scl_i and sfp_scl_i;

    mux_da_inst : IOBUF
    port map (
      IO => DA_b,
      O  => DA_in,
      I  => DA_out,
      T  => DA_t);
    DA_t <= '0' when eeprom_sda_i = '0' or sfp_sda_i = '0' or dacpll_off = '0' else '1';
    eeprom_sda_o <= DA_in;
    sfp_sda_o <= DA_in;

    mux_db_inst : IOBUF
    port map (
      IO => DB_b,
      O  => DB_in,
      I  => DB_out,
      T  => DB_t);
    DB_t <= '0' when eeprom_scl_i = '0' or sfp_scl_i = '0' or dacpll_off = '0' else '1';
    eeprom_scl_o <= DB_in;
    sfp_scl_o <= DB_in;

    A0_out <= '1' when i2c_priority = '1' else A0_i;

    a0_inst : OBUF
    port map (
      I => A0_out,
      O => A0_o);

    A1_out <= '1' when i2c_priority = '1' else A1_i;

    a1_inst : OBUF
    port map(
      I => A1_out,
      O => A1_o);

end RTL;
