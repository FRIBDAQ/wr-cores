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

library work;
use work.wishbone_pkg.all;

entity cts_top is
  generic (
    -- Simulation-mode enable parameter. Set by default (synthesis) to 0, and
    -- changed to non-zero in the instantiation of the top level DUT in the testbench.
    -- Its purpose is to reduce some internal counters/timeouts to speed up simulations.
    g_SIMULATION: integer := 0;
    C_S_AXI_DATA_WIDTH : integer := 32;
    C_S_AXI_ADDR_WIDTH : integer := 40
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
    sfp_sda_in             : in  std_logic;
    sfp_sda_out            : out std_logic;
    sfp_scl_in             : in  std_logic;
    sfp_scl_out            : out std_logic;
    sfp_tx_disable_o       : out std_logic;
    sfp_los_i              : in  std_logic;

    ---------------------------------------------------------------------------
    -- UART
    ---------------------------------------------------------------------------
    uart_rxd_i             : in  std_logic;
    uart_txd_o             : out std_logic;

    ---------------------------------------------------------------------------
    -- Clock out
    ---------------------------------------------------------------------------
    clk_sys_o           : out std_logic;
    clk_10m_o           : out std_logic;
    clk_125m_o          : out std_logic;

    ---------------------------------------------------------------------------
    -- LEDs
    ---------------------------------------------------------------------------
    led_act_o     : out std_logic;
    led_link_o    : out std_logic;
    pps_p_o       : out std_logic;

    ---------------------------------------------------------------------------
    -- Ports of Axi Slave Bus Interface S_AXI
    ---------------------------------------------------------------------------
    S_AXI_aclk      : in std_logic;
    S_AXI_aresetn   : in  std_logic;
    S_AXI_awaddr    : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_awprot    : in  std_logic_vector(2 downto 0);
    S_AXI_awvalid   : in  std_logic;
    S_AXI_awready   : out std_logic;
    S_AXI_wdata     : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_wstrb     : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_wvalid    : in  std_logic;
    S_AXI_wready    : out std_logic;
    S_AXI_bresp     : out std_logic_vector(1 downto 0);
    S_AXI_bvalid    : out std_logic;
    S_AXI_bready    : in  std_logic;
    S_AXI_araddr    : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_arprot    : in  std_logic_vector(2 downto 0);
    S_AXI_arvalid   : in  std_logic;
    S_AXI_arready   : out std_logic;
    S_AXI_rdata     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_rresp     : out std_logic_vector(1 downto 0);
    S_AXI_rvalid    : out std_logic;
    S_AXI_rready    : in  std_logic
    );
end cts_top;

architecture Behavioral of cts_top is

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

    signal rst_n: std_logic;
    signal clk_sys_62m5 : std_logic;
    signal clk_ref      : std_logic;

    signal clk_500Mhz_fb : std_logic;
    signal clk_500Mhz_locked : std_logic;
    signal clk_500Mhz : std_logic;

    signal clk_10MHz : std_logic;
    signal clk_125MHz : std_logic;

    signal led_act_buf, led_link_buf, pps_p_buf: std_logic;

    signal wb_wrpc_in: t_wishbone_master_in;
    signal wb_wrpc_out: t_wishbone_master_out;

    ATTRIBUTE X_INTERFACE_INFO : STRING;
    ATTRIBUTE X_INTERFACE_INFO of clk_sys_o: SIGNAL is "xilinx.com:signal:clock:1.0 clk_sys_o CLK";
    ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
    ATTRIBUTE X_INTERFACE_PARAMETER of clk_sys_o: SIGNAL is "ASSOCIATED_BUSIF M_AXI_HPM0_LPD, ASSOCIATED_RESET S_AXI_aresetn, FREQ_HZ 62500000";

begin
    rst_n <= not ps_por_i;

    cmp_xwrc_board_cts : xwrc_board_cts
    generic map (
      g_simulation   => g_SIMULATION,
      g_dpram_initf  => "../../wrc_cts_lpdc.bram")
    port map (
      areset_n_i             => rst_n,
      wr_clk_helper_125m_p_i => wr_clk_helper_125m_p_i,
      wr_clk_helper_125m_n_i => wr_clk_helper_125m_n_i,
      wr_clk_main_125m_p_i   => wr_clk_main_125m_p_i,
      wr_clk_main_125m_n_i   => wr_clk_main_125m_n_i,
      wr_clk_sfp_125m_p_i    => wr_clk_sfp_125m_p_i,
      wr_clk_sfp_125m_n_i    => wr_clk_sfp_125m_n_i,
      clk_sys_62m5_o         => clk_sys_62m5,
      clk_ref_125m_o         => clk_ref,


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

      wb_slave_i => wb_wrpc_out,
      wb_slave_o => wb_wrpc_in,

      eeprom_sda_i => eeprom_sda_in,
      eeprom_sda_o => eeprom_sda_out,
      eeprom_scl_i => eeprom_scl_in,
      eeprom_scl_o => eeprom_scl_out,

      uart_rxd_i   => uart_rxd_i,
      uart_txd_o   => uart_txd_o,

      led_act_o  => led_act_buf,
      led_link_o => led_link_buf,
      pps_p_o    => pps_p_buf
    );

   clk_sys_o <= clk_sys_62m5;

   clk_10m_mmcme4_inst : MMCME4_ADV
   generic map (
      BANDWIDTH => "OPTIMIZED",        -- Jitter programming
      CLKFBOUT_MULT_F => 25.0,          -- Multiply value for all CLKOUT
      CLKFBOUT_PHASE => 0.0,           -- Phase offset in degrees of CLKFB
      CLKFBOUT_USE_FINE_PS => "FALSE", -- Fine phase shift enable (TRUE/FALSE)
      CLKIN1_PERIOD => 16.0,            -- Input clock period in ns to ps resolution (i.e., 33.333 is 30 MHz).
      CLKOUT0_DIVIDE_F => 3.125,         -- Divide amount for CLKOUT0
      CLKOUT0_DUTY_CYCLE => 0.5,       -- Duty cycle for CLKOUT0
      CLKOUT0_PHASE => 0.0,            -- Phase offset for CLKOUT0
      CLKOUT0_USE_FINE_PS => "FALSE",  -- Fine phase shift enable (TRUE/FALSE)

      COMPENSATION => "AUTO",          -- Clock input compensation
      DIVCLK_DIVIDE => 1,              -- Master division value
      IS_RST_INVERTED => '1',
      STARTUP_WAIT => "FALSE"          -- Delays DONE until MMCM is locked
   )
   port map (
      CLKFBOUT => clk_500MHz_fb,         -- 1-bit output: Feedback clock
      CLKOUT0 => clk_500MHz,           -- 1-bit output: CLKOUT0
      LOCKED => clk_500MHz_locked,             -- 1-bit output: LOCK
      PSDONE => open,             -- 1-bit output: Phase shift done
      CDDCREQ => '0',           -- 1-bit input: Request to dynamic divide clock
      CLKFBIN => clk_500MHz_fb,           -- 1-bit input: Feedback clock
      CLKIN1 => clk_ref,             -- 1-bit input: Primary clock
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

   inst_mpsoc_map: entity work.mpsoc_map
   port map (
     aclk     => clk_sys_62m5,
     areset_n => rst_n,
     awaddr   => S_AXI_awaddr(11 downto 2),
     awvalid  => S_AXI_awvalid,
     awready  => S_AXI_awready,
     awprot   => "000",
     wvalid   => S_AXI_wvalid,
     wready   => S_AXI_wready,
     wdata    => S_AXI_wdata,
     wstrb    => S_AXI_wstrb,
     bvalid   => S_AXI_bvalid,
     bready   => S_AXI_bready,
     bresp    => S_AXI_bresp,
     araddr   => S_AXI_araddr(11 downto 2),
     arvalid  => S_AXI_arvalid,
     arready  => S_AXI_arready,
     arprot   => "000",
     rvalid   => S_AXI_rvalid,
     rready   => S_AXI_rready,
     rdata    => S_AXI_rdata,
     rresp    => S_AXI_rresp,

     wrpc_i   => wb_wrpc_in,
     wrpc_o   => wb_wrpc_out);

  cmp_gen_10_mhz: gen_x_mhz
    generic map (
      g_divide => 50
    )
    port map (
      clk_500m_i  => clk_500Mhz,
      rst_n_i     => rst_n,
      pps_i       => pps_p_buf,
      clk_x_mhz_o => clk_10Mhz
    );

   clk_10mhz_oddr: ODDRE1
   port map(
     Q  => clk_10m_o,
     C  => clk_500Mhz,
     D1 => clk_10MHz,
     D2 => clk_10MHz,
     SR => '0');

  cmp_gen_125_mhz: gen_x_mhz
    generic map (
      g_divide => 4
    )
    port map (
      clk_500m_i  => clk_500Mhz,
      rst_n_i     => rst_n,
      pps_i       => pps_p_buf,
      clk_x_mhz_o => clk_125Mhz
    );

   clk_125mhz_oddr: ODDRE1
   port map(
     Q  => clk_125m_o,
     C  => clk_500Mhz,
     D1 => clk_125MHz,
     D2 => clk_125MHz,
     SR => '0');


   act_led_inst : OBUF
   port map (
     I => led_act_buf,
     O => led_act_o);

   link_led_inst : OBUF
   port map (
     I => led_link_buf,
     O => led_link_o);

   oddr_pps_inst : ODDRE1
   port map(
     Q  => pps_p_o,
     C  => clk_500Mhz,
     D1 => pps_p_buf,
     D2 => pps_p_buf,
     SR => '0');

end Behavioral;
