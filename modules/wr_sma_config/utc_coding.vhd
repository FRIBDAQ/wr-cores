Library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity utc_coding is
  port(
    clk_ref_i : in std_logic;
    rst_n_i   : in std_logic;
    pps_i     : in std_logic;
    pps_valid_i : in std_logic;
    tm_utc_i  : in std_logic_vector(39 downto 0);
    tm_serial_o : out std_logic
  );
end utc_coding;

Architecture beha of utc_coding is
  type t_state is (idle, wt_utc, tx_utc);
  signal state : t_state;

  signal cnt : unsigned(5 downto 0);
  signal tm_utc_int : std_logic_vector(39 downto 0);
begin

  p_tm_serial : process(clk_ref_i)
  begin
    if rising_edge(clk_ref_i) then
      if rst_n_i = '0' then
        tm_serial_o <= '0';
        cnt <= (others => '0');
        state <= idle;
        tm_utc_int <= (others => '0');
      else
        case state is
          when idle =>
            if (pps_i = '1' and pps_valid_i = '1') then
              tm_serial_o <= '1';
              state <= wt_utc;
            else
              tm_serial_o <= '0';
            end if;

          when wt_utc =>
            tm_serial_o <= '0';
            tm_utc_int <= tm_utc_i;
            cnt <= to_unsigned(40,6);
            state <= tx_utc;

          when tx_utc =>
            tm_serial_o <= tm_utc_int(tm_utc_int'high);
            tm_utc_int <= tm_utc_int(tm_utc_int'high-1 downto 0) & '0';

            if cnt = 0 then
              state <= idle;
            else
              cnt <= cnt -1;
            end if;

          when others => state <= idle;
          
        end case;
      end if;
    end if;
  end process p_tm_serial;
end beha;