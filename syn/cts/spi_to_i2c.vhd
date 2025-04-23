--------------------------------------------------------------------------------
--
--   FileName:         spi_to_i2c.vhd
--   Dependencies:     spi_to_i2c_bridge.vhd (v1.0)
--                     spi_slave.vhd (v1.1)
--                     i2c_master.vhd (v1.0)
--   Design Software:  Quartus II 32-bit Version 11.1 Build 173 SJ Full Version
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
--   Version 1.0 12/05/2012 Scott Larson
--     Initial Public Release
--   Version FRIB 4/17/2025 Genie Jhang
--     Adapted for processing WR core DAC SPI signals
--     Calculating necessary information and send via I2C
--    
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.conv_integer;
use IEEE.NUMERIC_STD.ALL;

ENTITY spi_to_i2c IS
GENERIC(
  si5344_addr  : STD_LOGIC_VECTOR(7 DOWNTO 0);
  max_wr_size  : INTEGER := 3;
  si5344_fstep : INTEGER := 182 
);
PORT(
  clk         : IN   STD_LOGIC;                                     --system clock
  reset_n     : IN   STD_LOGIC;                                     --active low reset
  spi_rrdy    : IN   STD_LOGIC;                                     --receive ready signal from spi (new message arrived)
  spi_rx_data : IN   STD_LOGIC_VECTOR(23 DOWNTO 0);                 --message received on spi
  spi_busy    : IN   STD_LOGIC;                                     --spi slave busy signal (talking to spi master)
  spi_rx_req  : OUT  STD_LOGIC;                                     --request received message from the spi slave
  i2c_busy    : IN   STD_LOGIC;                                     --i2c busy signal (talking to i2c slave)
  i2c_ack_err : IN   STD_LOGIC;                                     --i2c acknowledge error flag
  i2c_ena     : OUT  STD_LOGIC;                                     --latch command into i2c master
  i2c_addr    : OUT  STD_LOGIC_VECTOR(6 DOWNTO 0);                  --i2c slave address
  i2c_rw      : OUT  STD_LOGIC;                                     --i2c read/write command
  i2c_data_wr : OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);                  --data to write over the i2c bus
  block_spi   : OUT  STD_LOGIC);
END spi_to_i2c;

ARCHITECTURE behavior OF spi_to_i2c IS
  TYPE machine IS(ready, spi_rx, calc_write_size, i2c, i2c_2, i2c_3, i2c_4);     --state machine datatype

  SIGNAL state         : machine;                       --current state
  SIGNAL message       : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others => '0'); --message sent and received
  SIGNAL i2c_busy_prev : STD_LOGIC;                     --previous busy signal for i2c transactions
  
  SIGNAL decinc             : STD_LOGIC;
  SIGNAL dac_value          : UNSIGNED(15 DOWNTO 0);
  SIGNAL prevdac_value      : UNSIGNED(15 DOWNTO 0) := x"8000";
  SIGNAL diff_dac_value     : UNSIGNED(15 DOWNTO 0);
  SIGNAL write_size_checker : UNSIGNED(max_wr_size - 1 DOWNTO 0);
  SIGNAL write_size         : UNSIGNED(8*max_wr_size - 1 DOWNTO 0);
  SIGNAL write_value        : UNSIGNED(8*max_wr_size - 1 DOWNTO 0);
  
BEGIN

  dac_value <= UNSIGNED(message(15 downto 0));

  decinc <= '1' when prevdac_value > dac_value else -- '1': decrease '0': increase
            '0';

  diff_dac_value <= dac_value - prevdac_value when decinc = '0' else
                    prevdac_value - dac_value;

  write_value <= resize(resize(diff_dac_value, 8*max_wr_size)*to_unsigned(si5344_fstep, 8*max_wr_size), 8*max_wr_size);

  write_size_checker_inst : for i in 0 to max_wr_size - 1 generate
    write_size_checker(i) <= write_value(i*8 + 7) or write_value(i*8 + 6) or write_value(i*8 + 5) or write_value(i*8 + 4) or write_value(i*8 + 3) or write_value(i*8 + 2) or write_value(i*8 + 1) or write_value(i*8);  
  end generate write_size_checker_inst;

  PROCESS(clk, reset_n)
    VARIABLE i2c_busy_cnt : INTEGER := 0;  --keeps track of i2c busy signals during transaction
    VARIABLE ii           : INTEGER;
  BEGIN

    IF(reset_n = '0') THEN                 --reset asserted
      i2c_busy_cnt := 0; 
      i2c_ena <= '0';
      spi_rx_req <= '0';
      state <= ready;
    ELSIF(clk'EVENT AND clk = '1') THEN
      CASE state IS

        WHEN ready =>
          IF(spi_busy = '0' AND spi_rrdy = '1') THEN --new message from spi
            spi_rx_req <= '1';                       --request message from spi
            state <= spi_rx;                         --retrieve message from spi
          ELSE                                       --no new message from spi
            block_spi <= '0';
            state <= ready;                          --wait for new message from spi
          END IF;

        WHEN spi_rx =>
          message <= spi_rx_data;        --retrieve message from spi
          spi_rx_req <= '0';             --stop requesting
          state <= calc_write_size;

        when calc_write_size =>
          write_size <= (others => '0');
          for ii in max_wr_size downto 1 loop
            if write_size_checker(ii - 1) = '1' then
              write_size <= to_unsigned(ii, 8*max_wr_size);
              exit;
            end if;
          end loop;
          state <= i2c;

        WHEN i2c =>
          if write_size = 0 then
            i2c_busy_cnt := 0;                          --reset busy_cnt for next transaction
            prevdac_value <= dac_value;
            state <= ready;
          else
            block_spi <= '1';

            i2c_busy_prev <= i2c_busy;                      --capture the value of the previous i2c busy signal
            IF(i2c_busy_prev = '0' AND i2c_busy = '1') THEN --i2c busy just went high
              i2c_busy_cnt := i2c_busy_cnt + 1;             --counts the times busy has gone from low to high during transaction
            END IF;
            CASE i2c_busy_cnt IS                            --busy_cnt keeps track of which command we are on
              WHEN 0 =>                                     --no command latched in yet
                i2c_ena <= '1';                               --initiate the transaction
                i2c_addr <= si5344_addr(6 downto 0);                    --slave address is this 7 bits of message
                i2c_rw <= '0';                                --write the name of the slave register to access
                i2c_data_wr <= x"01";          --the slave register to access is these 8 bits
              WHEN 1 =>                                     --1st busy high: command 1 latched, okay to issue command 2
                i2c_rw <= '0';                             --command to read or right the slave register is bit 16
                i2c_data_wr <= x"03";           --data to write to register (i2c master ignores if it's a read)
              WHEN 2 =>                                     --2nd busy high: command 2 latched, ready to stop
                i2c_ena <= '0';                               --deassert enable to stop transaction after command 2
                IF(i2c_busy = '0') THEN                       --indicates command 2 is finished and any data is ready
                  i2c_busy_cnt := 0;                          --reset busy_cnt for next transaction
                  state <= i2c_2;
                END IF;
              WHEN OTHERS => NULL;
            END CASE;
          end if;

        WHEN i2c_2 =>
          i2c_busy_prev <= i2c_busy;                      --capture the value of the previous i2c busy signal
          IF(i2c_busy_prev = '0' AND i2c_busy = '1') THEN --i2c busy just went high
            i2c_busy_cnt := i2c_busy_cnt + 1;             --counts the times busy has gone from low to high during transaction
          END IF;
          IF i2c_busy_cnt = 0 THEN
            i2c_ena <= '1';                               --initiate the transaction
            i2c_addr <= si5344_addr(6 downto 0);                    --slave address is this 7 bits of message
            i2c_rw <= '0';                                --write the name of the slave register to access
            i2c_data_wr <= x"3b";          --the slave register to access is these 8 bits
          ELSIF i2c_busy_cnt <= write_size THEN
            i2c_rw <= '0';                             --command to read or right the slave register is bit 16
            i2c_data_wr <= std_logic_vector(write_value(i2c_busy_cnt*8 - 1 downto (i2c_busy_cnt - 1)*8));           --data to write to register (i2c master ignores if it's a read)
          ELSE
            i2c_ena <= '0';                               --deassert enable to stop transaction after command 2
            IF(i2c_busy = '0') THEN                       --indicates command 2 is finished and any data is ready
              message(23) <= i2c_ack_err;                 --let spi master know if there was an i2c ack error
              i2c_busy_cnt := 0;                          --reset busy_cnt for next transaction
              state <= i2c_3;
            END IF;
          END IF;

        WHEN i2c_3 =>
          i2c_busy_prev <= i2c_busy;                      --capture the value of the previous i2c busy signal
          IF(i2c_busy_prev = '0' AND i2c_busy = '1') THEN --i2c busy just went high
            i2c_busy_cnt := i2c_busy_cnt + 1;             --counts the times busy has gone from low to high during transaction
          END IF;
          CASE i2c_busy_cnt IS                            --busy_cnt keeps track of which command we are on
            WHEN 0 =>                                     --no command latched in yet
              i2c_ena <= '1';                               --initiate the transaction
              i2c_addr <= si5344_addr(6 downto 0);                    --slave address is this 7 bits of message
              i2c_rw <= '0';                                --write the name of the slave register to access
              i2c_data_wr <= x"01";          --the slave register to access is these 8 bits
            WHEN 1 =>                                     --1st busy high: command 1 latched, okay to issue command 2
              i2c_rw <= '0';                             --command to read or right the slave register is bit 16
              i2c_data_wr <= x"00";           --data to write to register (i2c master ignores if it's a read)
            WHEN 2 =>                                     --2nd busy high: command 2 latched, ready to stop
              i2c_ena <= '0';                               --deassert enable to stop transaction after command 2
              IF(i2c_busy = '0') THEN                       --indicates command 2 is finished and any data is ready
                i2c_busy_cnt := 0;                          --reset busy_cnt for next transaction
                state <= i2c_4;
              END IF;
            WHEN OTHERS => NULL;
          END CASE;

        WHEN i2c_4 =>
          i2c_busy_prev <= i2c_busy;                      --capture the value of the previous i2c busy signal
          IF(i2c_busy_prev = '0' AND i2c_busy = '1') THEN --i2c busy just went high
            i2c_busy_cnt := i2c_busy_cnt + 1;             --counts the times busy has gone from low to high during transaction
          END IF;
          CASE i2c_busy_cnt IS                            --busy_cnt keeps track of which command we are on
            WHEN 0 =>                                     --no command latched in yet
              i2c_ena <= '1';                               --initiate the transaction
              i2c_addr <= si5344_addr(6 downto 0);                    --slave address is this 7 bits of message
              i2c_rw <= '0';                                --write the name of the slave register to access
              i2c_data_wr <= x"1d";          --the slave register to access is these 8 bits
            WHEN 1 =>                                     --1st busy high: command 1 latched, okay to issue command 2
              i2c_rw <= '0';                             --command to read or right the slave register is bit 16
              i2c_data_wr <= (conv_integer(decinc) => '1', others => '0');           --data to write to register (i2c master ignores if it's a read)
            WHEN 2 =>                                     --2nd busy high: command 2 latched, ready to stop
              i2c_ena <= '0';                               --deassert enable to stop transaction after command 2
              IF(i2c_busy = '0') THEN                       --indicates command 2 is finished and any data is ready
                i2c_busy_cnt := 0;                          --reset busy_cnt for next transaction
                prevdac_value <= dac_value;
                state <= ready;
              END IF;
            WHEN OTHERS => NULL;
          END CASE;
      END CASE;
    END IF;
  END PROCESS;
END behavior;