library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wrc_dac_driver is
  generic (
    g_dither_amplitude_log2 : integer                       := 7;
    g_dither_clock_div_log2 : integer                       := 7;
    g_dither_init_value     : std_logic_vector(31 downto 0) := x"deadbeef"
    );
  port (
    clk_sys_i   : in std_logic;
    rst_sys_n_i : in std_logic;

    x_valid_i : in std_logic;
    x_i       : in std_logic_vector(23 downto 0);

    y_o       : out std_logic_vector(15 downto 0);
    y_valid_o : out std_logic
    );

end wrc_dac_driver;

architecture rtl of wrc_dac_driver is

  function f_xorshift32_next(x : std_logic_vector) return std_logic_vector is
    variable tmp : unsigned(31 downto 0);
  begin
    tmp := unsigned(x);
    tmp := tmp xor (tmp sll 13);
    tmp := tmp xor (tmp srl 17);
    tmp := tmp xor (tmp sll 5);
    return std_logic_vector(tmp);
  end f_xorshift32_next;

  signal sr_div_cnt : unsigned(15 downto 0);
  signal sr_div_p   : std_logic;

  signal rnd_state  : std_logic_vector(31 downto 0);
  signal x_latched  : signed(24 downto 0);
  signal y_dithered : signed(24 downto 0);
  signal dither     : signed(g_dither_amplitude_log2+1 downto 0);
begin

  dither <= signed("00"&rnd_state(g_dither_amplitude_log2-1 downto 0));


  p_clock_div : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_sys_n_i = '0' then
        sr_div_cnt <= (others => '0');
        sr_div_p   <= '0';
      elsif sr_div_cnt(g_dither_clock_div_log2) = '1' then
        sr_div_cnt <= (others => '0');
        sr_div_p   <= '1';
      else
        sr_div_cnt <= sr_div_cnt + 1;
        sr_div_p   <= '0';
      end if;
    end if;
  end process;

  p_dither : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_sys_n_i = '0' then
        rnd_state <= g_dither_init_value;
        y_valid_o <= '0';
      else
        if x_valid_i = '1' then
          x_latched <= signed('0'&x_i);
        end if;

        if sr_div_p = '1' then
          rnd_state  <= f_xorshift32_next(rnd_state);
          y_dithered <= x_latched + dither;
          y_o        <= std_logic_vector(y_dithered(23 downto 8));
          y_valid_o <= '1';
        else
          y_valid_o <= '0';
        end if;
      end if;
    end if;
  end process;

end rtl;



