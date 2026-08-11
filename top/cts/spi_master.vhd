-------------------------------------------------------------------------------
-- spi_master.vhd
-- Minimal SPI master, mode 0 (CPOL=0, CPHA=0), MSB first, 8 bits per transfer.
--
-- One byte per 'start' pulse.  Chip-select is NOT driven here: the caller holds
-- CS low across as many byte transfers as the transaction needs, so commands +
-- address + data frame naturally.  SCK idles low.
--
--   SCK period = clk / (2*g_CLK_DIV)     e.g. 100 MHz / (2*64) = 781 kHz
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master is
  generic (
    g_CLK_DIV : positive := 64   -- clk cycles per half SCK period
  );
  port (
    clk_i   : in  std_logic;
    rst_i   : in  std_logic;                     -- synchronous, active high
    -- byte handshake
    start_i : in  std_logic;                     -- pulse: begin one 8-bit xfer
    tx_i    : in  std_logic_vector(7 downto 0);  -- byte to shift out (MSB first)
    rx_o    : out std_logic_vector(7 downto 0);  -- byte shifted in
    busy_o  : out std_logic;
    done_o  : out std_logic;                     -- 1-clk pulse, rx_o valid
    -- SPI pins
    sck_o   : out std_logic;
    mosi_o  : out std_logic;
    miso_i  : in  std_logic
  );
end entity spi_master;

architecture rtl of spi_master is
  type t_state is (IDLE, LOW_PH, HIGH_PH, FINISH);
  signal state  : t_state := IDLE;
  signal div    : integer range 0 to g_CLK_DIV-1 := 0;
  signal bitcnt : integer range 0 to 8 := 0;
  signal txsr   : std_logic_vector(7 downto 0) := (others => '0');
  signal rxsr   : std_logic_vector(7 downto 0) := (others => '0');
  signal sck    : std_logic := '0';
begin

  sck_o  <= sck;
  mosi_o <= txsr(7);                     -- MSB is on the wire
  rx_o   <= rxsr;
  busy_o <= '0' when state = IDLE else '1';

  process(clk_i)
  begin
    if rising_edge(clk_i) then
      done_o <= '0';
      if rst_i = '1' then
        state  <= IDLE;
        sck    <= '0';
        div    <= 0;
        bitcnt <= 0;
        txsr   <= (others => '0');
        rxsr   <= (others => '0');
      else
        case state is

          when IDLE =>
            sck <= '0';
            if start_i = '1' then
              txsr   <= tx_i;            -- mosi immediately = tx_i(7)
              bitcnt <= 8;
              div    <= 0;
              sck    <= '0';
              state  <= LOW_PH;
            end if;

          when LOW_PH =>                 -- SCK low; MOSI stable
            if div = g_CLK_DIV-1 then
              div  <= 0;
              sck  <= '1';                            -- rising edge
              rxsr <= rxsr(6 downto 0) & miso_i;      -- sample MISO
              state <= HIGH_PH;
            else
              div <= div + 1;
            end if;

          when HIGH_PH =>               -- SCK high
            if div = g_CLK_DIV-1 then
              div    <= 0;
              sck    <= '0';                          -- falling edge
              bitcnt <= bitcnt - 1;
              if bitcnt = 1 then
                state <= FINISH;
              else
                txsr  <= txsr(6 downto 0) & '0';      -- next bit -> MSB
                state <= LOW_PH;
              end if;
            else
              div <= div + 1;
            end if;

          when FINISH =>
            done_o <= '1';
            state  <= IDLE;

        end case;
      end if;
    end if;
  end process;

end architecture rtl;
