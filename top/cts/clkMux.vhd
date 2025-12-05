----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/04/2025 03:03:16 PM
-- Design Name: 
-- Module Name: clkMux - Behavioral
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

entity clkMux is
    port (
        -- Data/Select Inputs (forming the 3-bit selection vector S)
        IN0_i  : in  std_logic;
        IN1_i  : in  std_logic;
        IN2_i  : in  std_logic;
        
        -- Clock Inputs
        clk_500m_i : in std_logic;
        clk0_i     : in  std_logic; -- Selected when S = "000"
        clk1_i     : in  std_logic; -- Selected when S = "001"
        clk2_i     : in  std_logic; -- Selected when S = "010"
        clk3_i     : in  std_logic; -- Selected when S = "100"
        
        -- Clock Output
        clk_o  : out std_logic
    );
end entity clkMux;

architecture behavioral of clkMux is
    -- Signal to concatenate the selection inputs into a single 3-bit vector
    signal select_s : std_logic_vector(2 downto 0);
    signal clk_sel  : std_logic;
begin

    -- Concatenate the individual inputs into the 3-bit select signal
    -- Note: IN2_i is the Most Significant Bit (MSB)
    select_s <= IN2_i & IN1_i & IN0_i;

    -- Use the selected signal assignment (multiplexer style)
    -- This drives the output clk_o based on the value of the select_s signal.
    with select_s select
        clk_sel <= clk0_i when "000",
                   clk1_i when "001",
                   clk2_i when "010",
                   clk3_i when "100",
                   '0'    when others; -- Safety net: drive '0' for all other combinations
                                    -- (e.g., "011", "101", "110", "111")

   clk_oddr: ODDRE1
   port map(
     Q  => clk_o,
     C  => clk_500m_i,
     D1 => clk_sel,
     D2 => clk_sel,
     SR => '0');
                                    
end architecture behavioral;