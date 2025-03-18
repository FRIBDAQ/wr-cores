-------------------------------------------------------------------------------
-- Title      : WRPC reference design for CTS board
-- Project    : WR PTP Core for CTS board
-------------------------------------------------------------------------------
-- File       : cts_top.vhd
-- Author(s)  : Genie Jhang <changj@frib.msu.edu>
-- Company    : FRIB
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top-level file for the WRPC reference design on the CTS board.
-------------------------------------------------------------------------------
-- Copyright (c) 2024 FRIB
-------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
--
-- This source file is free software; you can redistribute it
-- and/or modify it under the terms of the GNU Lesser General
-- Public License as published by the Free Software Foundation;
-- either version 2.1 of the License, or (at your option) any
-- later version.
--
-- This source is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
-- PURPOSE.  See the GNU Lesser General Public License for more
-- details.
--
-- You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it
-- from http://www.gnu.org/licenses/lgpl-2.1.html
-------------------------------------------------------------------------------

use work.wr_cts_pkg.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity cts_top is
  generic (
    -- Simulation-mode enable parameter. Set by default (synthesis) to 0, and
    -- changed to non-zero in the instantiation of the top level DUT in the testbench.
    -- Its purpose is to reduce some internal counters/timeouts to speed up simulations.
    g_SIMULATION: integer := 0
    );
    Port (
    ---------------------------------------------------------------------------
    -- Clocks/resets
    ---------------------------------------------------------------------------
    ps_por_i               : in  std_logic;
    wr_clk_helper_125m_p_i : in  std_logic;
    wr_clk_helper_125m_n_i : in  std_logic;
    wr_clk_main_125m_p_i   : in  std_logic;
    wr_clk_main_125m_n_i   : in  std_logic;
    wr_clk_sfp_125m_p_i    : in  std_logic;
    wr_clk_sfp_125m_n_i    : in  std_logic;

    ---------------------------------------------------------------------------
    -- SPI interface to DACs
    ---------------------------------------------------------------------------
    plldac_sclk_o   : out std_logic;
    plldac_din_o    : out std_logic;
    pll25dac_cs_n_o : out std_logic;
    pll20dac_cs_n_o : out std_logic;

    ---------------------------------------------------------------------------
    -- EEPROM I2C interface for storing configuration and accessing unique ID
    ---------------------------------------------------------------------------
    eeprom_scl_in       : in  std_logic;
    eeprom_scl_out      : out std_logic;
    eeprom_sda_in       : in  std_logic;
    eeprom_sda_out      : out std_logic;

    ---------------------------------------------------------------------------
    -- SFP I/Os for transceiver
    ---------------------------------------------------------------------------
    sfp_txp_o              : out std_logic;
    sfp_txn_o              : out std_logic;
    sfp_rxp_i              : in  std_logic;
    sfp_rxn_i              : in  std_logic;
    sfp_det_i              : in  std_logic;
    sfp_sda_b              : inout std_logic;
    sfp_scl_b              : inout std_logic;
    sfp_tx_disable_o       : out std_logic;
    sfp_los_i              : in  std_logic;

    ---------------------------------------------------------------------------
    -- UART
    ---------------------------------------------------------------------------
    uart_rxd_i             : in  std_logic;
    uart_txd_o             : out std_logic;

    ---------------------------------------------------------------------------
    -- Helper clock I2C control
    ---------------------------------------------------------------------------
    si570_sda_in       : in  std_logic;
    si570_sda_out      : out std_logic;
    si570_scl_in       : in  std_logic;
    si570_scl_out      : out std_logic;

    ---------------------------------------------------------------------------
    -- Clock out
    ---------------------------------------------------------------------------
    clk_ref_10m_o       : out std_logic;

    ---------------------------------------------------------------------------
    -- LEDs
    ---------------------------------------------------------------------------
    led_act_o     : out std_logic;
    led_link_o    : out std_logic;
    pps_p_o       : out std_logic
    );
end cts_top;

architecture Behavioral of cts_top is
    signal rst_n: std_logic;
    signal clk_sys_62m5 : std_logic;
    signal clk_ref_125m : std_logic;

    signal sfp_scl_out, sfp_scl_in : std_logic;
    signal sfp_sda_out, sfp_sda_in : std_logic;
    signal sfp_scl_t, sfp_sda_t : std_logic;

    signal clk_10MHz_fb : std_logic;
    signal clk_10MHz_locked : std_logic;
    signal clk_10MHz : std_logic;

    signal led_act_buf, led_link_buf, pps_p_buf: std_logic;
begin
    rst_n <= not ps_por_i;

    cmp_xwrc_board_cts : xwrc_board_cts
    generic map (
      g_simulation   => g_SIMULATION,
      g_dpram_initf  => "/home/geniejhang/work/wr-cores/syn/cts/wrc_kr260_si570.bram")
    port map (
      areset_n_i             => rst_n,
      wr_clk_helper_125m_p_i => wr_clk_helper_125m_p_i,
      wr_clk_helper_125m_n_i => wr_clk_helper_125m_n_i,
      wr_clk_main_125m_p_i   => wr_clk_main_125m_p_i,
      wr_clk_main_125m_n_i   => wr_clk_main_125m_n_i,
      wr_clk_sfp_125m_p_i    => wr_clk_sfp_125m_p_i,
      wr_clk_sfp_125m_n_i    => wr_clk_sfp_125m_n_i,
      clk_sys_62m5_o         => clk_sys_62m5,
      clk_ref_125m_o         => clk_ref_125m,

      plldac_sclk_o   => plldac_sclk_o,
      plldac_din_o    => plldac_din_o,
      pll25dac_cs_n_o => pll25dac_cs_n_o,
      pll20dac_cs_n_o => pll20dac_cs_n_o,

      sfp_txp_o       => sfp_txp_o,
      sfp_txn_o       => sfp_txn_o,
      sfp_rxp_i       => sfp_rxp_i,
      sfp_rxn_i       => sfp_rxn_i,
      sfp_det_i       => sfp_det_i,
      sfp_sda_i       => sfp_sda_in,
      sfp_sda_o       => sfp_sda_out,
      sfp_scl_i       => sfp_scl_in,
      sfp_scl_o       => sfp_scl_out,
      sfp_tx_disable_o => sfp_tx_disable_o,
      sfp_los_i        => sfp_los_i,

      eeprom_sda_i => eeprom_sda_in,
      eeprom_sda_o => eeprom_sda_out,
      eeprom_scl_i => eeprom_scl_in,
      eeprom_scl_o => eeprom_scl_out,

      si570_scl_o => si570_scl_out,
      si570_scl_i => si570_scl_in,
      si570_sda_o => si570_sda_out,
      si570_sda_i => si570_sda_in,

      uart_rxd_i   => uart_rxd_i,
      uart_txd_o   => uart_txd_o,

      led_act_o  => led_act_buf,
      led_link_o => led_link_buf,
      pps_p_o    => pps_p_buf
    );


   clk_10m_mmcme4_inst : MMCME4_ADV
   generic map (
      BANDWIDTH => "OPTIMIZED",        -- Jitter programming
      CLKFBOUT_MULT_F => 16.0,          -- Multiply value for all CLKOUT
      CLKFBOUT_PHASE => 0.0,           -- Phase offset in degrees of CLKFB
      CLKFBOUT_USE_FINE_PS => "FALSE", -- Fine phase shift enable (TRUE/FALSE)
      CLKIN1_PERIOD => 16.0,            -- Input clock period in ns to ps resolution (i.e., 33.333 is 30 MHz).
      CLKOUT0_DIVIDE_F => 100.0,         -- Divide amount for CLKOUT0
      CLKOUT0_DUTY_CYCLE => 0.5,       -- Duty cycle for CLKOUT0
      CLKOUT0_PHASE => 0.0,            -- Phase offset for CLKOUT0
      CLKOUT0_USE_FINE_PS => "FALSE",  -- Fine phase shift enable (TRUE/FALSE)
      COMPENSATION => "AUTO",          -- Clock input compensation
      DIVCLK_DIVIDE => 1,              -- Master division value
      IS_RST_INVERTED => '1',
      STARTUP_WAIT => "FALSE"          -- Delays DONE until MMCM is locked
   )
   port map (
      CLKFBOUT => clk_10MHz_fb,         -- 1-bit output: Feedback clock
      CLKOUT0 => clk_10MHz,           -- 1-bit output: CLKOUT0
      LOCKED => clk_10MHz_locked,             -- 1-bit output: LOCK
      PSDONE => open,             -- 1-bit output: Phase shift done
      CDDCREQ => '0',           -- 1-bit input: Request to dynamic divide clock
      CLKFBIN => clk_10MHz_fb,           -- 1-bit input: Feedback clock
      CLKIN1 => clk_ref_125m,             -- 1-bit input: Primary clock
      CLKIN2 => '0',             -- 1-bit input: Primary clock
      CLKINSEL => '1',         -- 1-bit input: Clock select, High=CLKIN1 Low=CLKIN2
      DADDR => (others => '0'),               -- 7-bit input: DRP address
      DCLK => '0',                 -- 1-bit input: DRP clock
      DEN => '0',                   -- 1-bit input: DRP enable
      DI => (others => '0'),                     -- 16-bit input: DRP data input
      DWE => '0',                   -- 1-bit input: DRP write enable
      PSCLK => '0',               -- 1-bit input: Phase shift clock
      PSEN => '0',                 -- 1-bit input: Phase shift enable
      PSINCDEC => '0',         -- 1-bit input: Phase shift increment/decrement
      PWRDWN => '0',             -- 1-bit input: Power-down
      RST => rst_n                    -- 1-bit input: Reset
   );

   clk_ref_10m_o <= clk_10MHz;

   sfp_scl_inst : IOBUF
   port map(
     IO => sfp_scl_b,
     O => sfp_scl_in,
     I => '0',
     T => sfp_scl_t);
   sfp_scl_t <= '0' when sfp_scl_out = '0' else '1';

   sfp_sda_inst : IOBUF
   port map(
     IO => sfp_sda_b,
     O => sfp_sda_in,
     I => '0',
     T => sfp_sda_t);
   sfp_sda_t <= '0' when sfp_sda_out = '0' else '1';

   act_led_inst : OBUF
   port map (
     I => led_act_buf,
     O => led_act_o);

   link_led_inst : OBUF
   port map (
     I => led_link_buf,
     O => led_link_o);

   pps_p_inst : OBUF
   port map(
     I => pps_p_buf,
     O => pps_p_o);

end Behavioral;
