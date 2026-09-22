----------------------------------------------------------------------------------
-- Company: Facility for Rare Isotope Beams
-- Engineer: Genie Jhang (changj@frib.msu.edu)
-- 
-- Create Date: 09/18/2026 02:51:13 PM
-- Design Name: 
-- Module Name: sync_clk_generator - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--      Generate clocks synchronized with the PPS input.
--      Synchronize reset and PPS once into the external 500 MHz domain,
--      then distribute the same reset and alignment pulse to every divider.
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

entity sync_clk_generator is
    Port ( rst_n      : in  STD_LOGIC;
           clk_500m_i : in  STD_LOGIC;
           pps_i      : in  STD_LOGIC;
           clk_sel_i  : in  STD_LOGIC_VECTOR(2 downto 0);
           clk_10m_o  : out STD_LOGIC;
           clk_mux_o  : out STD_LOGIC);
end sync_clk_generator;

architecture Behavioral of sync_clk_generator is

  component gen_x_mhz is
    generic (
      g_divide    : integer
    );
    port (
      clk_500m_i  : in  std_logic;
      rst_n_i     : in  std_logic;
      pps_i       : in  std_logic;
      clk_x_mhz_o : out std_logic
    );
  end component gen_x_mhz;

  signal clk_mux          : std_logic;
  signal clk_10m          : std_logic;
  signal clk_20m          : std_logic;
  signal clk_25m          : std_logic;
  signal clk_50m          : std_logic;
  signal clk_100m         : std_logic;
  signal clk_125m         : std_logic;

  -- Assert reset even if the Si5344 clock is stopped; release it only after
  -- four 500 MHz edges. Only the last stage drives the divider resets.
  signal rst_n_pipe      : std_logic_vector(3 downto 0) := (others => '0');
  signal rst_n_500m      : std_logic;

  -- Only the last PPS synchronizer stage may feed functional logic.
  -- PPS must remain high/low long enough to be sampled by clk_500m_i.
  signal pps_pipe        : std_logic_vector(2 downto 0) := (others => '0');
  signal pps_delayed     : std_logic := '0';
  signal pps_rise_500m   : std_logic := '0';

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of rst_n_pipe, pps_pipe : signal is "TRUE";
  attribute SHREG_EXTRACT : string;
  attribute SHREG_EXTRACT of rst_n_pipe, pps_pipe : signal is "NO";

--  signal clk_500m_fb      : std_logic;
--  signal clk_500m         : std_logic;
--  signal clk_500m_locked  : std_logic;
--  signal clk_500m_fb_buf  : std_logic;

begin

  pr_reset_sync : process (clk_500m_i, rst_n)
  begin
    if rst_n = '0' then
      rst_n_pipe <= (others => '0');
    elsif rising_edge(clk_500m_i) then
      rst_n_pipe <= rst_n_pipe(2 downto 0) & '1';
    end if;
  end process;

  rst_n_500m <= rst_n_pipe(3);

  pr_pps_sync : process (clk_500m_i)
  begin
    if rising_edge(clk_500m_i) then
      pps_pipe <= pps_pipe(1 downto 0) & pps_i;
      -- Keep tracking the PPS level during reset so reset release does not
      -- manufacture a rising edge when PPS has already been high.
      pps_delayed <= pps_pipe(2);
      if rst_n_500m = '0' then
        pps_rise_500m <= '0';
      else
        pps_rise_500m <= pps_pipe(2) and not pps_delayed;
      end if;
    end if;
  end process;

--  clk_500m_mmcme4_inst : MMCME4_ADV
--  generic map (
--     BANDWIDTH => "OPTIMIZED",        -- Jitter programming
--     CLKFBOUT_MULT_F => 24.0,          -- Multiply value for all CLKOUT
--     CLKFBOUT_PHASE => 0.0,           -- Phase offset in degrees of CLKFB
--     CLKFBOUT_USE_FINE_PS => "FALSE", -- Fine phase shift enable (TRUE/FALSE)
--     CLKIN1_PERIOD => 16.0,            -- Input clock period in ns to ps resolution (i.e., 33.333 is 30 MHz).
--     CLKOUT0_DIVIDE_F => 3.0,         -- Divide amount for CLKOUT0
--     CLKOUT0_DUTY_CYCLE => 0.5,       -- Duty cycle for CLKOUT0
--     CLKOUT0_PHASE => 0.0,            -- Phase offset for CLKOUT0
--     CLKOUT0_USE_FINE_PS => "FALSE",  -- Fine phase shift enable (TRUE/FALSE)

--     COMPENSATION => "AUTO",          -- Clock input compensation
--     DIVCLK_DIVIDE => 1,              -- Master division value
--     IS_RST_INVERTED => '1',
--     STARTUP_WAIT => "FALSE"          -- Delays DONE until MMCM is locked
--  )
--  port map (
--     CLKFBOUT => clk_500m_fb,         -- 1-bit output: Feedback clock
--     CLKOUT0 => clk_500m,           -- 1-bit output: CLKOUT0
--     LOCKED => clk_500m_locked,             -- 1-bit output: LOCK
--     PSDONE => open,             -- 1-bit output: Phase shift done
--     CDDCREQ => '0',           -- 1-bit input: Request to dynamic divide clock
--     CLKFBIN => clk_500m_fb,           -- 1-bit input: Feedback clock
--     CLKIN1 => clk_i,             -- 1-bit input: Primary clock
--     CLKIN2 => '0',             -- 1-bit input: Primary clock
--     CLKINSEL => '1',         -- 1-bit input: Clock select, High=CLKIN1 Low=CLKIN2
--     DADDR => (others => '0'),               -- 7-bit input: DRP address
--     DCLK => '0',                 -- 1-bit input: DRP clock
--     DEN => '0',                   -- 1-bit input: DRP enable
--     DI => (others => '0'),                     -- 16-bit input: DRP data input
--     DWE => '0',                   -- 1-bit input: DRP write enable
--     PSCLK => '0',               -- 1-bit input: Phase shift clock
--     PSEN => '0',                 -- 1-bit input: Phase shift enable
--     PSINCDEC => '0',         -- 1-bit input: Phase shift increment/decrement
--     PWRDWN => '0',             -- 1-bit input: Power-down
--     RST => rst_n                    -- 1-bit input: Reset
--  );
  
  cmp_gen_10_mhz: gen_x_mhz
    generic map (
      g_divide => 50
    )
    port map (
      clk_500m_i  => clk_500m_i,
      rst_n_i     => rst_n_500m,
      pps_i       => pps_rise_500m,
      clk_x_mhz_o => clk_10m_o
    );

  cmp_gen_20_mhz: gen_x_mhz
    generic map (
      g_divide => 25
    )
    port map (
      clk_500m_i  => clk_500m_i,
      rst_n_i     => rst_n_500m,
      pps_i       => pps_rise_500m,
      clk_x_mhz_o => clk_20m
    );

  cmp_gen_25_mhz: gen_x_mhz
    generic map (
      g_divide => 20
    )
    port map (
      clk_500m_i  => clk_500m_i,
      rst_n_i     => rst_n_500m,
      pps_i       => pps_rise_500m,
      clk_x_mhz_o => clk_25m
    );

  cmp_gen_50_mhz: gen_x_mhz
    generic map (
      g_divide => 10
    )
    port map (
      clk_500m_i  => clk_500m_i,
      rst_n_i     => rst_n_500m,
      pps_i       => pps_rise_500m,
      clk_x_mhz_o => clk_50m
    );

  cmp_gen_100_mhz: gen_x_mhz
    generic map (
      g_divide => 5
    )
    port map (
      clk_500m_i  => clk_500m_i,
      rst_n_i     => rst_n_500m,
      pps_i       => pps_rise_500m,
      clk_x_mhz_o => clk_100m
    );
    
  cmp_gen_125_mhz: gen_x_mhz
    generic map (
      g_divide => 4
    )
    port map (
      clk_500m_i  => clk_500m_i,
      rst_n_i     => rst_n_500m,
      pps_i       => pps_rise_500m,
      clk_x_mhz_o => clk_125m
    );

   clk_mux_o <= clk_125m  when clk_sel_i = "000" else
                clk_20m   when clk_sel_i = "001" else
                clk_25m   when clk_sel_i = "010" else
                clk_50m   when clk_sel_i = "011" else
                clk_100m  when clk_sel_i = "100" else
                '1';
              
--   clk_10m_oddr: ODDRE1
--   port map(
--     Q  => clk_10m_o,
--     C  => clk_500m,
--     D1 => clk_10m,
--     D2 => clk_10m,
--     SR => '0');
    
--   clk_mux_oddr: ODDRE1
--   port map(
--     Q  => clk_mux_o,
--     C  => clk_500m,
--     D1 => clk_mux,
--     D2 => clk_mux,
--     SR => '0');

end Behavioral;
