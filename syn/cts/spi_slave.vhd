--------------------------------------------------------------------------------
--
--   FileName:         spi_slave.vhd
--   Dependencies:     none
--   Design Software:  Quartus Prime Version 17.0.0 Build 595 SJ Lite Edition
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 7/5/2012 Scott Larson
--     Initial Public Release
--   Version 1.1 11/27/2012 Scott Larson
--     Added an asynchronous active low reset
--   Version 1.2 5/7/2019 Scott Larson
--     Modified architecture slightly to make it synthesizable with more tools
--   Version FRIB 4/17/2025 Genie Jhang
--     Adapted for processing WR core DAC SPI signals
--     It's now just relaying SPI data with no other information
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY spi_slave IS
  GENERIC(
    cpol    : STD_LOGIC := '0';  --spi clock polarity mode
    cpha    : STD_LOGIC := '0';  --spi clock phase mode
    d_width : INTEGER := 8);     --data width in bits
  PORT(
    sclk         : IN     STD_LOGIC;  --spi clk from master
    reset_n      : IN     STD_LOGIC;  --active low reset
    ss_n         : IN     STD_LOGIC;  --active low slave select
    mosi         : IN     STD_LOGIC;  --master out, slave in
    rx_req       : IN     STD_LOGIC;  --'1' while busy = '0' moves data to the rx_data output
    rrdy         : OUT    STD_LOGIC := '0';  --receive ready bit
    rx_data      : OUT    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');  --receive register output to logic
    busy         : OUT    STD_LOGIC := '0';  --busy signal to logic ('1' during transaction)
    block_spi    : IN     STD_LOGIC);
END spi_slave;

ARCHITECTURE logic OF spi_slave IS
  SIGNAL mode      : STD_LOGIC;  --groups modes by clock polarity relation to data
  SIGNAL clk       : STD_LOGIC;  --clock
  SIGNAL bit_cnt   : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --'1' for active transaction bit
  SIGNAL rx_buf    : STD_LOGIC_VECTOR(d_width-1 DOWNTO 0) := (OTHERS => '0');  --receiver buffer
  SIGNAL spi_ready : STD_LOGIC := '1';
BEGIN
  busy <= NOT ss_n;  --high during transactions
  
  process (block_spi, ss_n)
  begin
    if (spi_ready = '1' and block_spi = '1') or (block_spi = '1' and ss_n = '0') then
      spi_ready <= '0';
    elsif spi_ready <= '0' and block_spi = '0' and rising_edge(ss_n) then
      spi_ready <= '1';
    end if;
  end process;
  
  --adjust clock so writes are on rising edge and reads on falling edge
  mode <= cpol XOR cpha;  --'1' for modes that write on rising edge
  WITH mode SELECT clk <=     sclk WHEN '1',
                          NOT sclk WHEN OTHERS;

  --keep track of miso/mosi bit counts for data alignmnet
  PROCESS(ss_n, clk, spi_ready)
  BEGIN
    IF(ss_n = '1' OR reset_n = '0' OR spi_ready = '0') THEN                         --this slave is not selected or being reset
     bit_cnt <= (0 => '1', OTHERS => '0'); --reset miso/mosi bit count
    ELSE                                                         --this slave is selected
      IF(rising_edge(clk)) THEN                                  --new bit on miso/mosi
        bit_cnt <= bit_cnt(d_width-2 DOWNTO 0) & '0';          --shift active bit indicator
      END IF;
    END IF;
  END PROCESS;

  PROCESS(ss_n, clk, rx_req, spi_ready)
  BEGIN
  
    --rrdy register
    IF((ss_n = '1' AND rx_req = '1') OR reset_n = '0' OR spi_ready = '0') THEN
      rrdy <= '0';   --cleared by user logic or rx_data has been requested or reset
    ELSIF(falling_edge(clk)) THEN
      IF bit_cnt(d_width-1) = '1' THEN
        rrdy <= '1';   --set when new data received
      END IF;
    END IF;
    
    --receive registers
    --write to the receive register from master
    IF(reset_n = '0' OR spi_ready = '0') THEN
      rx_buf <= (OTHERS => '0');
    ELSE
      FOR i IN 0 TO d_width-1 LOOP          
        IF(bit_cnt(i) = '1' AND falling_edge(clk)) THEN
          rx_buf(d_width-1-i) <= mosi;
        END IF;
      END LOOP;
    END IF;

    --fulfill user logic request for receive data
    IF(reset_n = '0' OR spi_ready = '0') THEN
      rx_data <= (OTHERS => '0');
    ELSIF(ss_n = '1' AND rx_req = '1') THEN  
      rx_data <= rx_buf;
    END IF;

  END PROCESS;
END logic;
