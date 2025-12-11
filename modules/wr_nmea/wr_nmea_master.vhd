-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 1996 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : NMEA master interface
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : wr_nmea_master.vhd
-- Author     : Harvey Leicester
-- Company    : CERN BE-CEM-EDL
-- Created    : 2024-11-11
-- Last update: 2024-11-11
-- Platform   : FPGA-generic
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- NMEA GPZDA sentence generator
--
-- $--ZDA,hhmmss.ss,dd,mm,yyyy,xx,xx
-- An example of the ZDA message string is:
-- $GPZDA,172809.456,12,07,1996,00,00*45
--
-- Based on cute-wr by Guanghua Gong
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wr_nmea_master is
port
(

  clk_i   : in std_logic;
  rst_n_i : in std_logic;

  --bcd format
  sec_i   : in std_logic_vector(7 downto 0);
  min_i   : in std_logic_vector(7 downto 0);
  hour_i  : in std_logic_vector(7 downto 0);
  day_i   : in std_logic_vector(7 downto 0);
  month_i : in std_logic_vector(7 downto 0);
  year_i  : in std_logic_vector(15 downto 0);
  valid_i : in std_logic;
  tx_en_i : in std_logic;

  uart_bcr_i : in std_logic_vector(16 downto 0);

  busy_o  : out std_logic;
  nmea_o  : out std_logic
);
end entity wr_nmea_master;

architecture rtl of wr_nmea_master is

  constant c_FRAME_LEN    : integer := 38;
  constant c_CHECKSUM_IDX0 : integer := 34;
  constant c_CHECKSUM_IDX1 : integer := 35;
  constant c_DOLLAR       : std_logic_vector(7 downto 0) := X"24";
  constant c_G            : std_logic_vector(7 downto 0) := X"47";
  constant c_P            : std_logic_vector(7 downto 0) := X"50";
  constant c_Z            : std_logic_vector(7 downto 0) := X"5A";
  constant c_D            : std_logic_vector(7 downto 0) := X"44";
  constant c_A            : std_logic_vector(7 downto 0) := X"41";
  constant c_COMMA        : std_logic_vector(7 downto 0) := X"2C";
  constant c_DOT          : std_logic_vector(7 downto 0) := X"2E";
  constant c_ASTERISK     : std_logic_vector(7 downto 0) := X"2A";
  constant c_CR           : std_logic_vector(7 downto 0) := X"0D";
  constant c_LF           : std_logic_vector(7 downto 0) := X"0A";
  constant c_ZERO         : std_logic_vector(7 downto 0) := X"30";
  constant c_DIGIT_UPPER  : std_logic_vector(3 downto 0) := X"3";
  constant c_CHAR_M9      : std_logic_vector(7 downto 0) := X"37"; --character offset - 9

  type t_byte_array is array (natural range <>) of std_logic_vector(7 downto 0);

  signal nmea_s : t_byte_array(0 to c_FRAME_LEN-1);  --nmea sentance
  signal nmea_b : std_logic_vector(7 downto 0);      --nmea byte

  type t_nmea_state is
  (
    S_IDLE,
    S_TX_EN,
    S_WAIT_BUSY,
    S_WAIT_TX
  );

  signal nmea_state : t_nmea_state := S_IDLE;

  signal tx_busy    : std_logic;
  signal uart_tx_en : std_logic;
  signal baud_tick  : std_logic;
  signal tx_en      : std_logic;

  signal byte_cnt       : unsigned(7 downto 0);
  signal checksum       : unsigned(7 downto 0);
  signal checksum_ascii : unsigned(7 downto 0);

  signal baud_tick_rst_n : std_logic;

begin

  tx_en <= tx_en_i and valid_i;

  p_sr: process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if(rst_n_i = '0') then
        nmea_s <= (others => (others => '0'));
      else
        if(tx_en = '1') then
          nmea_s <= (others => (others => '0'));
          nmea_s(0)   <= c_DOLLAR;
          nmea_s(1)   <= c_G;
          nmea_s(2)   <= c_P;
          nmea_s(3)   <= c_Z;
          nmea_s(4)   <= c_D;
          nmea_s(5)   <= c_A;
          nmea_s(6)   <= c_COMMA;
          nmea_s(7)   <= c_DIGIT_UPPER & hour_i(7 downto 4);
          nmea_s(8)   <= c_DIGIT_UPPER & hour_i(3 downto 0);
          nmea_s(9)   <= c_DIGIT_UPPER & min_i(7 downto 4);
          nmea_s(10)  <= c_DIGIT_UPPER & min_i(3 downto 0);
          nmea_s(11)  <= c_DIGIT_UPPER & sec_i(7 downto 4);
          nmea_s(12)  <= c_DIGIT_UPPER & sec_i(3 downto 0);
          nmea_s(13)  <= c_DOT;
          nmea_s(14)  <= c_ZERO;
          nmea_s(15)  <= c_ZERO;
          nmea_s(16)  <= c_COMMA;
          nmea_s(17)  <= c_DIGIT_UPPER & day_i(7 downto 4);
          nmea_s(18)  <= c_DIGIT_UPPER & day_i(3 downto 0);
          nmea_s(19)  <= c_COMMA;
          nmea_s(20)  <= c_DIGIT_UPPER & month_i(7 downto 4);
          nmea_s(21)  <= c_DIGIT_UPPER & month_i(3 downto 0);
          nmea_s(22)  <= c_COMMA;
          nmea_s(23)  <= c_DIGIT_UPPER & year_i(15 downto 12);
          nmea_s(24)  <= c_DIGIT_UPPER & year_i(11 downto 8);
          nmea_s(25)  <= c_DIGIT_UPPER & year_i(7 downto 4);
          nmea_s(26)  <= c_DIGIT_UPPER & year_i(3 downto 0);
          nmea_s(27)  <= c_COMMA;
          nmea_s(28)  <= c_ZERO;
          nmea_s(29)  <= c_ZERO;
          nmea_s(30)  <= c_COMMA;
          nmea_s(31)  <= c_ZERO;
          nmea_s(32)  <= c_ZERO;
          nmea_s(33)  <= c_ASTERISK;
          nmea_s(34)  <= c_ZERO; --checksum
          nmea_s(35)  <= c_ZERO; --checksum
          nmea_s(36)  <= c_CR;
          nmea_s(37)  <= c_LF;
        end if;
      end if;
    end if;
  end process;

  nmea_b <= std_logic_vector(checksum_ascii) when byte_cnt = c_CHECKSUM_IDX0 or byte_cnt = c_CHECKSUM_IDX1 else nmea_s(to_integer(byte_cnt));

  p_sm: process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if(rst_n_i = '0') then
        nmea_state <= S_IDLE;
        byte_cnt <= (others => '0');
        checksum <= (others => '0');
        uart_tx_en <= '0';
      else

        uart_tx_en <= '0';

        case nmea_state is

          when S_IDLE =>  byte_cnt <= (others => '0');
                          checksum <= (others => '0');
                          if(tx_en = '1') then
                            nmea_state <= S_TX_EN;
                          end if;

          when S_TX_EN =>   uart_tx_en <= '1';
                            nmea_state <= S_WAIT_BUSY;
                            if(byte_cnt < c_CHECKSUM_IDX0-1 and nmea_b /= c_DOLLAR) then
                              checksum <= checksum xor unsigned(nmea_b);
                            end if;

          when S_WAIT_BUSY => if(tx_busy = '1') then
                                byte_cnt <= byte_cnt + 1;
                                nmea_state <= S_WAIT_TX;
                              end if;

          when S_WAIT_TX => if(tx_busy = '0') then
                              nmea_state <= S_TX_EN;
                              if(byte_cnt >= c_FRAME_LEN-1) then
                                nmea_state <= S_IDLE;
                                byte_cnt <= (others => '0');
                                checksum <= (others => '0');
                              end if;
                            end if;

          when others    => nmea_state <= S_IDLE;

        end case;
      end if;
    end if;
  end process;

  p_checksum_gen: process(clk_i) is
  begin
    if rising_edge(clk_i) then
      if(rst_n_i = '0') then
        checksum_ascii <= (others => '0');
      else
        checksum_ascii <= (others => '0');
        if(byte_cnt = c_CHECKSUM_IDX0) then
          if(checksum(7 downto 4) > 9) then
            checksum_ascii <= unsigned(c_CHAR_M9) + checksum(7 downto 4); --character
          else
            checksum_ascii <= unsigned(c_ZERO) + checksum(7 downto 4); --number
          end if;
        elsif(byte_cnt = c_CHECKSUM_IDX1) then
          if(checksum(3 downto 0) > 9) then
            checksum_ascii <= unsigned(c_CHAR_M9) + checksum(3 downto 0); --character
          else
            checksum_ascii <= unsigned(c_ZERO) + checksum(3 downto 0); --number
          end if;
        end if;
      end if;
    end if;
  end process;

  baud_tick_rst_n <= rst_n_i and not tx_en; --resync baud ticks

  U_baud_gen : entity work.uart_baud_gen
  port map
  (
    clk_sys_i    => clk_i,
    rst_n_i      => baud_tick_rst_n,
    baudrate_i   => uart_bcr_i,
    baud_tick_o  => baud_tick,
    baud8_tick_o => open
  );

  U_tx : entity work.uart_async_tx
  port map
  (
    clk_sys_i    => clk_i,
    rst_n_i      => rst_n_i,
    baud_tick_i  => baud_tick,
    txd_o        => nmea_o,
    tx_start_p_i => uart_tx_en,
    tx_data_i    => nmea_b,
    tx_busy_o    => tx_busy
  );

  busy_o <= '1' when nmea_state /= S_IDLE else '0';

end architecture;

