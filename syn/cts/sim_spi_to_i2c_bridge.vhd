----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/17/2025 12:27:45 PM
-- Design Name: 
-- Module Name: sim_spi_to_i2c_bridge - Behavioral
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity sim_spi_to_i2c_bridge is
GENERIC(
  sys_clk_frq  : INTEGER   := 50_000_000; --system clock speed in Hz
  i2c_scl_frq  : INTEGER   := 400_000;    --speed the i2c bus (scl) will run at in Hz
  spi_cpol    : STD_LOGIC := '1';        --spi clock polarity mode
  spi_cpha    : STD_LOGIC := '0';
  si5344_addr : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"6a";
  max_wr_size : INTEGER := 3);       --spi clock phase mode
end sim_spi_to_i2c_bridge;

architecture Behavioral of sim_spi_to_i2c_bridge is

  --declare spi slave component
  COMPONENT spi_slave IS
    GENERIC(
      cpol    : STD_LOGIC; --spi clock polarity mode
      cpha    : STD_LOGIC; --spi clock phase mode
      d_width : INTEGER);  --data width in bits
    PORT(
      sclk         : IN     STD_LOGIC;                            --spi clk from master
      reset_n      : IN     STD_LOGIC;                            --active low reset
      ss_n         : IN     STD_LOGIC;                            --active low slave select
      mosi         : IN     STD_LOGIC;                            --master out, slave in
      rx_req       : IN     STD_LOGIC;                            --'1' while busy = '0' moves data to the rx_data output
      rrdy         : OUT    STD_LOGIC := '0';                     --receive ready bit
      rx_data      : OUT    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0); --receive register output to logic
      busy         : OUT    STD_LOGIC := '0';                     --busy signal to logic ('1' during transaction)
      block_spi    : IN     STD_LOGIC);
  END COMPONENT spi_slave;

  --declare spi to i2c component
  COMPONENT spi_to_i2c IS
    GENERIC(
      si5344_addr  : STD_LOGIC_VECTOR(7 DOWNTO 0);
      max_wr_size  : INTEGER;
      si5344_fstep : INTEGER); 
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
  END COMPONENT spi_to_i2c;
  
  --declare i2c master component
  COMPONENT i2c_master IS
    GENERIC(
      input_clk   : INTEGER;  --input clock speed from user logic in Hz
      bus_clk     : INTEGER); --speed the i2c bus (scl) will run at in Hz
    PORT(
      clk       : IN     STD_LOGIC;                    --system clock
      reset_n   : IN     STD_LOGIC;                    --active low reset
      ena       : IN     STD_LOGIC;                    --latch in command
      addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
      rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
      data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
      busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
      data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
      ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
      sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
      scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
  END COMPONENT i2c_master;

  CONSTANT spi_d_width : INTEGER := 24;  --spi data width in bits
  SIGNAL   spi_busy    : STD_LOGIC;
  SIGNAL   spi_tx_ena  : STD_LOGIC;
  SIGNAL   spi_tx_data : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL   spi_rx_req  : STD_LOGIC;
  SIGNAL   spi_rx_data : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL   spi_rrdy    : STD_LOGIC;
  SIGNAL   i2c_ena     : STD_LOGIC;
  SIGNAL   i2c_addr    : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL   i2c_rw      : STD_LOGIC;
  SIGNAL   i2c_data_wr : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL   i2c_data_rd : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL   i2c_ack_err : STD_LOGIC;
  SIGNAL   i2c_busy    : STD_LOGIC;

  signal clock   : STD_LOGIC;
  signal clk     : STD_LOGIC;
  signal reset_n : STD_LOGIC;  --active low reset
  signal sclk    : STD_LOGIC;  --spi serial clock
  signal ss_n    : STD_LOGIC;  --spi slave select
  signal mosi    : STD_LOGIC := '0';  --spi master out, slave in
  signal miso    : STD_LOGIC;  --spi master in, slave out
  signal trdy    : STD_LOGIC;  --spi transmit ready
  
  signal scl     : STD_LOGIC;  --i2c serial clock
  signal sda     : STD_LOGIC; --i2c serial select
  
  signal block_spi : STD_LOGIC;
  
begin

    test_process : process
      variable i : integer := 0;
    begin
      reset_n <= '0';
      wait for 100 ns;
      reset_n <= '1';
      wait for 100 ns;
      sclk <= '1';
      ss_n <= '1';
      wait for 100 ns;
      ss_n <= '0';
      wait for 14 ns;
      for i in 0 to 24 loop
        sclk <= '0';
        wait for 147 ns;
        sclk <= '1';
        wait for 147 ns;
      end loop;
      ss_n <= '1';
      wait for 500 ns;
      ss_n <= '0';
      wait for 14 ns;
      for i in 0 to 24 loop
        sclk <= '0';
        wait for 147 ns;
        sclk <= '1';
        wait for 147 ns;
      end loop;
      ss_n <= '1';
      wait for 334900 ns;
      ss_n <= '0';
      wait for 14 ns;
      for i in 0 to 24 loop
        sclk <= '0';
        wait for 147 ns;
        sclk <= '1';
        wait for 147 ns;
      end loop;
      ss_n <= '1';
      wait for 500 ns;
      ss_n <= '0';
      wait for 14 ns;
      for i in 0 to 24 loop
        sclk <= '0';
        wait for 147 ns;
        sclk <= '1';
        wait for 147 ns;
      end loop;
      ss_n <= '1';
      wait;
    end process;
    
    clk_process : process
    begin
        while true loop
            clock <= '0';
            wait for 10 ns;
            clock <= '1';
            wait for 10 ns;
        end loop;
        wait;
    end process;
    
    sig_process : process (ss_n, sclk)
    begin
      if ss_n = '0' and rising_edge(sclk) then
          mosi <= not mosi;
        end if;
    end process;

  --instantiate the spi slave
  spi_slave_0:  spi_slave
    GENERIC MAP(
      cpol    => spi_cpol,
      cpha    => spi_cpha,
      d_width => spi_d_width
    )
    PORT MAP(
      sclk      => sclk,
      reset_n   => reset_n,
      ss_n      => ss_n,
      mosi      => mosi,
      rx_req    => spi_rx_req,
      rrdy      => spi_rrdy,
      rx_data   => spi_rx_data,
      busy      => spi_busy,
      block_spi => block_spi
    );

  --instantiate the bridge component
  spi_to_i2c_0:  spi_to_i2c
    GENERIC MAP(
      si5344_addr  => si5344_addr,
      max_wr_size  => max_wr_size,
      si5344_fstep => 182
    )
    PORT MAP(
      clk         => clock,
      reset_n     => reset_n,
      spi_rrdy    => spi_rrdy,
      spi_rx_data => spi_rx_data,
      spi_busy    => spi_busy,
      spi_rx_req  => spi_rx_req,
      i2c_busy    => i2c_busy,
      i2c_ack_err => i2c_ack_err,
      i2c_ena     => i2c_ena,
      i2c_addr    => i2c_addr,
      i2c_rw      => i2c_rw,
      i2c_data_wr => i2c_data_wr,
      block_spi   => block_spi
    );  
    
  --instantiate the i2c master
  i2c_master_0:  i2c_master
    GENERIC MAP(
      input_clk => sys_clk_frq,
      bus_clk   => i2c_scl_frq
    )
    PORT MAP(
      clk       => clock,
      reset_n   => reset_n,
      ena       => i2c_ena,
      addr      => i2c_addr,
      rw        => i2c_rw,
      data_wr   => i2c_data_wr,
      busy      => i2c_busy,
      data_rd   => i2c_data_rd,
      ack_error => i2c_ack_err,
      sda       => sda,
      scl       => scl
    );  

end Behavioral;
