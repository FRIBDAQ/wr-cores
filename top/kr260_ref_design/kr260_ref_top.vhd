-------------------------------------------------------------------------------
-- Title      : WRPC reference design for KR260 board
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- Company    : CERN (BE-CO-HT)
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Copyright (c) 2024 CERN
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
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi4_pkg.all;
--use work.gencores_pkg.all;
use work.wishbone_pkg.all;
use work.endpoint_pkg.all;
--use work.wr_board_pkg.all;
--use work.wr_pxie_fmc_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity kr260_ref_top is
  port (
    -- ref0: 156.25
    -- ref1: 74.25 (12g sdi)
    refclk0_n_i : in std_logic;
    refclk0_p_i : in std_logic;

    clk_25m_i   : in std_logic;

    pad_txn_o : out std_logic;
    pad_txp_o : out std_logic;
    pad_rxn_i : in std_logic;
    pad_rxp_i : in std_logic;

    --helper_txn_o : out std_logic;
    --helper_txp_o : out std_logic;
    --helper_rxn_i : in std_logic;
    --helper_rxp_i : in std_logic;

    led1_o : out std_logic;
    led2_o : out std_logic;
    sfp_led1_o : out std_logic;
    sfp_led2_o : out std_logic;

    sfp_tx_fault_i : in std_logic;
    sfp_tx_disable_o : out std_logic;
    sfp_mod_abs_i : in std_logic;
    sfp_sda_b : inout std_logic;
    sfp_scl_b : inout std_logic;

    pmod4_2_b : out std_logic;
    pmod4_4_b : out std_logic;
    pmod4_6_b : out std_logic;
    pmod4_8_b : out std_logic
  );
end;

architecture top of kr260_ref_top is
  --  In sources, select the mpsoc.bd file and right-click to view instantiation template
  component mpsoc is
    port (
      M_AXI_araddr : out STD_LOGIC_VECTOR ( 39 downto 0 );
      M_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
      M_AXI_arready : in STD_LOGIC;
      M_AXI_arvalid : out STD_LOGIC;
      M_AXI_awaddr : out STD_LOGIC_VECTOR ( 39 downto 0 );
      M_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
      M_AXI_awready : in STD_LOGIC;
      M_AXI_awvalid : out STD_LOGIC;
      M_AXI_bready : out STD_LOGIC;
      M_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
      M_AXI_bvalid : in STD_LOGIC;
      M_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
      M_AXI_rready : out STD_LOGIC;
      M_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
      M_AXI_rvalid : in STD_LOGIC;
      M_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
      M_AXI_wready : in STD_LOGIC;
      M_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
      M_AXI_wvalid : out STD_LOGIC;
      UART_0_0_rxd : in STD_LOGIC;
      UART_0_0_txd : out STD_LOGIC;
      clk_axi : in STD_LOGIC;
      rst_axi_n : in STD_LOGIC
    );
  end component mpsoc;

  COMPONENT gthe4_sdm
  PORT (
    gtwiz_userclk_tx_active_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userclk_rx_active_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_done_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_done_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_userdata_tx_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    gtwiz_userdata_rx_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dmonitorclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    drpaddr_in : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    drpclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    drpdi_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    drpen_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    drpwe_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthrxn_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthrxp_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtrxreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gttxreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll0clk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll0refclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll1clk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll1refclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rx8b10ben_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxbufreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxcommadeten_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxmcommaalignen_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxpcommaalignen_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxpcsreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxpd_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    rxpmareset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxprogdivreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxslide_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxuserrdy_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxusrclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxusrclk2_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    tx8b10ben_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txctrl0_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    txctrl1_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    txctrl2_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    txpcsreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpd_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    txpippmen_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpippmovrden_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpippmpd_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpippmsel_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpippmstepsize_in : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    txpllclksel_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    txpmareset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txprogdivreset_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txuserrdy_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txusrclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txusrclk2_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    dmonitorout_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dmonitoroutclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    drpdo_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    drprdy_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthtxn_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gthtxp_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtpowergood_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxbyteisaligned_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxbyterealign_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxcdrlock_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxcommadet_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxctrl0_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    rxctrl1_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    rxctrl2_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rxctrl3_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rxoutclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxpmaresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    txoutclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpmaresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    txresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0) 
  );
END COMPONENT;

  signal refclk_156m25, refclk_156m25_int : std_logic;
  signal rst_n, rst : std_logic := '0';
  signal rst_cnt : natural range 0 to 15 := 0;

  signal qpll0_reset, qpll1_reset, qpll0_lock, qpll1_lock : std_logic;
  signal qpll0_outclk, qpll0_outrefclk : std_logic;
  signal qpll1_outclk, qpll1_outrefclk : std_logic;
  signal clk_25m : std_logic;

  signal count : natural range 0 to 156_250_000 - 1;
  signal clk_156m25, clk_62m5 : std_logic;
  signal clk_fb, pll_locked : std_logic;

  signal m_axi4_out : t_axi4_lite_master_out_32;
  signal m_axi4_in : t_axi4_lite_master_in_32;
  signal m_axi_araddr, m_axi_awaddr : std_logic_vector(39 downto 32);

  signal gth_rst, gth_rst_n: std_logic;
  signal gth_tx_rst, gth_rx_rst : std_logic;
  signal uart_rx, uart_tx : std_logic;
  signal sfp_scl_out, sfp_sda_out : std_logic;

  signal phy16_out : t_phy_16bits_from_wrc;
  signal phy16_in : t_phy_16bits_to_wrc;

  signal wb_wrpc_in, wb_wraux_in: t_wishbone_master_in;
  signal wb_wrpc_out, wb_wraux_out: t_wishbone_master_out;

--  signal phy16_out : t_phy_16bits_from_wrc;
--  signal phy16_in : t_phy_16bits_to_wrc;

  signal rx_cdr_stable_out : std_logic;

  signal gth_rx_data_in : std_logic_vector(15 downto 0);
  signal gth_tx_data_out : std_logic_vector(15 downto 0);
  signal gth_rx_slide_out, gth_rx_slide : std_logic;
  signal gth_rx_k_in, gth_rx_disp_err_in : std_logic_vector(15 downto 0);
  signal gth_rx_comma_in, gth_rx_dec_err_in : std_logic_vector(7 downto 0);
  signal gth_tx_k_out : std_logic_vector(7 downto 0) := (others => '0');
  signal gth_rx_byte_aligned_in : std_logic;
  signal gth_rx_comma_det_in : std_logic;
  signal gth_rx_pma_reset_done_in : std_logic;
  signal gth_tx_pma_reset_done_in : std_logic;

  signal gth_powergood : std_logic;
  signal gth_tx_prg_div_reset_done : std_logic;
  signal gth_tx_pd, gth_rx_pd : std_logic;

  signal gtrxreset, gttxreset : std_logic;
  signal rx_reset_done, tx_reset_done : std_logic;
  signal rxusrrdy, txusrrdy : std_logic;
  signal rxbufreset, rxpcsreset, rxpmareset : std_logic;
  signal txpcsreset, txpmareset : std_logic;
  signal phy_rst : std_logic;

  signal mpll_data_out : std_logic_vector(15 downto 0);
  signal hpll_data_out : std_logic_vector(31 downto 0);
  signal hpll_load, mpll_load : std_logic;

  signal hpll_data, mpll_data : std_logic_vector(24 downto 0);
  signal hpll_toggle, mpll_toggle : std_logic;
  signal hpll_cnt, mpll_cnt : unsigned(5 downto 0);

  signal rxoutclk_out, rxoutclk : std_logic;
  signal txoutclk_out, txoutclk : std_logic;
  
  signal dmonitorout : std_logic_vector(15 downto 0);
  signal rxpi_ext_0, rxpi_ext_1 : std_logic_vector(31 downto 7);
  signal gth_dmon_clk, gth_dmon_clk_out, gth_dmon_rst_n : std_logic;

  signal rxpi_fifo_samp, rxpi_data : std_logic_vector(31 downto 0);
  signal rxpi_one_samp, rxpi_one_samp_dmon : std_logic_vector(6 downto 0);
  signal rxpi_valid : std_logic;
  signal rxpi_rdcount : unsigned(31 downto 0);

  signal gth_status_a, gth_status : std_logic_vector(15 downto 0) := (others => '0');

  signal bitslide_force, bitslide_slide, bitslide_wr, bitslide_pulse : std_logic;
  signal bitslide_cnt : unsigned(1 downto 0);
  signal bitslide_pulse_rx, bitslide_pulse_rx_d, bitslide_pulse_out : std_logic;

  signal bitslide_val : std_logic_vector(4 downto 0);
  signal rdy_in, rdy_in_62m5, rdy_out_62m5 : std_logic;

  --  For phase shift
  signal ps_clk_fb, ps_clk_fb_bufg : std_logic;
  signal ps_clk_in_stopped, ps_clk_fb_stopped : std_logic;
  signal clk_ps_out, clk_ps : std_logic;
  signal ps_clk_locked, ps_clk_pd, ps_clk_rst, ps_clk_rst_n : std_logic;
  signal ps_clk_pen, ps_clk_done, ps_clk_incdec, ps_clk_busy : std_logic;
  signal ps_clk_shift, ps_clk_shift_wr : std_logic;
  signal ps_clk_phase : unsigned(15 downto 0);

  signal ps_clk_nsamp : std_logic_vector(23 downto 0);
  signal rxoutclk_sync : std_logic;
  signal ps_clk_nsamp_cnt, ps_clk_count, ps_clk_count_out : unsigned(23 downto 0);
  signal ps_clk_gen : unsigned(7 downto 0);

  signal abscal_tx, abscal_rx : std_logic;

  signal nbr_comma, nbr_bytealign, nbr_counter, nbr_comma_cnt, nbr_bytealign_cnt: unsigned(31 downto 0);
begin
  inst_ibufds_gt : IBUFDS_GTE4
      generic map (
        REFCLK_EN_TX_PATH  => '0',
        REFCLK_HROW_CK_SEL => "00",
        REFCLK_ICNTL_RX    => "00")
      port map (
        O     => refclk_156m25,
        ODIV2 => refclk_156m25_int,
        CEB   => '0',
        I     => refclk0_p_i,
        IB    => refclk0_n_i);

  inst_buf_gt : BUFG_GT
      port map (
        O => clk_156m25,
        CE => '1',
        CEMASK => '0',
        CLR => '0',
        CLRMASK => '0',
        DIV => "000",
        I => refclk_156m25_int);


  inst_bufg: BUFG
    port map (
      O => clk_25m,
      I => clk_25m_i);

  --  VCO: 800-1600Mhz
  --  input: 156.25 * 8 = 1250Mhz / 20 => 62.50
  --  input: 74.25 * 20 = 1485Mhz
  --         74.25 * 16 = 1188Mhz  / 19 => 62.52
  inst_mmcm_62m5: mmcme4_base
    generic map (
      BANDWIDTH => "OPTIMIZED",  -- Jitter programming
      CLKFBOUT_MULT_F => 8.0,   -- Multiply value for all CLKOUT
      CLKFBOUT_PHASE => 0.0,     -- Phase offset in degrees of CLKFB
      CLKIN1_PERIOD => 6.4,    -- Input clock period in ns to ps resolution (i.e., 33.333 is 30 MHz).
      CLKOUT0_DIVIDE_F => 20.0,  -- Divide amount for CLKOUT0
      CLKOUT0_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT0
      CLKOUT0_PHASE => 0.0,     -- Phase offset for CLKOUT0
      CLKOUT1_DIVIDE => 100,  -- Divide amount for CLKOUT (1-128)
      CLKOUT1_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT outputs (0.001-0.999).
      CLKOUT1_PHASE => 0.0,   -- Phase offset for CLKOUT outputs (-360.000-360.000).
      CLKOUT2_DIVIDE => 1,   -- Divide amount for CLKOUT (1-128)
      CLKOUT2_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT outputs (0.001-0.999).
      CLKOUT2_PHASE => 0.0,  -- Phase offset for CLKOUT outputs (-360.000-360.000).
      CLKOUT3_DIVIDE => 1,   -- Divide amount for CLKOUT (1-128)
      CLKOUT3_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT outputs (0.001-0.999).
      CLKOUT3_PHASE => 0.0, -- Phase offset for CLKOUT outputs (-360.000-360.000).
      CLKOUT4_CASCADE => "FALSE", -- Divide amount for CLKOUT (1-128)
      CLKOUT4_DIVIDE => 1, -- Divide amount for CLKOUT (1-128)
      CLKOUT4_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT outputs (0.001-0.999).
      CLKOUT4_PHASE => 0.0,  -- Phase offset for CLKOUT outputs (-360.000-360.000).
      CLKOUT5_DIVIDE => 1,  -- Divide amount for CLKOUT (1-128)
      CLKOUT5_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT outputs (0.001-0.999).
      CLKOUT5_PHASE => 0.0,   -- Phase offset for CLKOUT outputs (-360.000-360.000).
      CLKOUT6_DIVIDE => 1,   -- Divide amount for CLKOUT (1-128)
      CLKOUT6_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT outputs (0.001-0.999).
      CLKOUT6_PHASE => 0.0,    -- Phase offset for CLKOUT outputs (-360.000-360.000).
      DIVCLK_DIVIDE => 1,   -- Master division value
      IS_CLKFBIN_INVERTED => '0', -- Optional inversion for CLKFBIN
      IS_CLKIN1_INVERTED => '0', -- Optional inversion for CLKIN1
      IS_PWRDWN_INVERTED => '0', -- Optional inversion for PWRDWN
      IS_RST_INVERTED => '0',   -- Optional inversion for RST
      REF_JITTER1 => 0.0,   -- Reference input jitter in UI (0.000-0.999).
      STARTUP_WAIT => "FALSE" -- Delays DONE until MMCM is locked
      )
    port map (
      CLKFBOUT => clk_fb,  -- 1-bit output: Feedback clock pin to the MMCM
      CLKFBOUTB => open, -- 1-bit output: Inverted CLKFBOUT
      CLKOUT0 => clk_62m5, -- 1-bit output: CLKOUT0
      CLKOUT0B => open,  -- 1-bit output: Inverted CLKOUT0
      CLKOUT1 => open, -- pmod4_2_b,   -- 1-bit output: CLKOUT1
      CLKOUT1B => open,  -- 1-bit output: Inverted CLKOUT1
      CLKOUT2 => open,   -- 1-bit output: CLKOUT2
      CLKOUT2B => open,  -- 1-bit output: Inverted CLKOUT2
      CLKOUT3 => open,   -- 1-bit output: CLKOUT3
      CLKOUT3B => open,  -- 1-bit output: Inverted CLKOUT3
      CLKOUT4 => open,   -- 1-bit output: CLKOUT4
      CLKOUT5 => open,   -- 1-bit output: CLKOUT5
      CLKOUT6 => open,   -- 1-bit output: CLKOUT6
      LOCKED => pll_locked,  -- 1-bit output: LOCK
      CLKFBIN => clk_fb, -- 1-bit input: Feedback clock pin to the MMCM
      CLKIN1 => clk_156m25, -- 1-bit input: Primary clock
      PWRDWN => '0', -- 1-bit input: Power-down
      RST => '0'  -- 1-bit input: Reset
    );

      --  MMCM for phase shift
      --  Input: ref clock
      --  Output: shifted version of ref clock
      --  VCO: 1250Mhz (x20)
  inst_mmcm_ps : MMCME4_ADV
    generic map (
      BANDWIDTH => "OPTIMIZED",  -- Jitter programming
      CLKFBOUT_MULT_F => 20.0,    -- Multiply value for all CLKOUT
      CLKFBOUT_PHASE => 0.0,     -- Phase offset in degrees of CLKFB
      CLKFBOUT_USE_FINE_PS => "FALSE", -- Fine phase shift enable (TRUE/FALSE)
      CLKIN1_PERIOD => 16.0,            -- Input clock period in ns to ps resolution (i.e., 33.333 is 30 MHz).
      CLKIN2_PERIOD => 0.0,            -- Input clock period in ns to ps resolution (i.e., 33.333 is 30 MHz).
      CLKOUT0_DIVIDE_F => 20.0,        -- Divide amount for CLKOUT0
      CLKOUT0_DUTY_CYCLE => 0.5,       -- Duty cycle for CLKOUT0
      CLKOUT0_PHASE => 0.0,            -- Phase offset for CLKOUT0
      CLKOUT0_USE_FINE_PS => "TRUE",   -- Fine phase shift enable (TRUE/FALSE)
      CLKOUT1_DIVIDE => 1,             -- Divide amount for CLKOUT (1-128)
      CLKOUT1_DUTY_CYCLE => 0.5,       -- Duty cycle for CLKOUT outputs (0.001-0.999).
      CLKOUT1_PHASE => 0.0,            -- Phase offset for CLKOUT outputs (-360.000-360.000).
      CLKOUT1_USE_FINE_PS => "FALSE",
      CLKOUT2_DIVIDE => 1,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT2_PHASE => 0.0,
      CLKOUT2_USE_FINE_PS => "FALSE",
      CLKOUT3_DIVIDE => 1,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT3_PHASE => 0.0,
      CLKOUT3_USE_FINE_PS => "FALSE",
      CLKOUT4_CASCADE => "FALSE",
      CLKOUT4_DIVIDE => 1,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT4_PHASE => 0.0,
      CLKOUT4_USE_FINE_PS => "FALSE",
      CLKOUT5_DIVIDE => 1,
      CLKOUT5_DUTY_CYCLE => 0.5,
      CLKOUT5_PHASE => 0.0,
      CLKOUT5_USE_FINE_PS => "FALSE",
      CLKOUT6_DIVIDE => 1,
      CLKOUT6_DUTY_CYCLE => 0.5,
      CLKOUT6_PHASE => 0.0,
      CLKOUT6_USE_FINE_PS => "FALSE",
      COMPENSATION => "AUTO",            -- Clock input compensation
      DIVCLK_DIVIDE => 1,                -- Master division value
      IS_CLKFBIN_INVERTED => '0',
      IS_CLKIN1_INVERTED => '0',
      IS_CLKIN2_INVERTED => '0',
      IS_CLKINSEL_INVERTED => '0',
      IS_PSEN_INVERTED => '0',
      IS_PSINCDEC_INVERTED => '0',
      IS_PWRDWN_INVERTED => '0',
      IS_RST_INVERTED => '0',
      REF_JITTER1 => 0.0,
      REF_JITTER2 => 0.0,
      SS_EN => "FALSE",
      SS_MODE => "CENTER_HIGH",
      SS_MOD_PERIOD => 10000,
      STARTUP_WAIT => "FALSE"
      )
    port map (
      CDDCDONE => open, -- 1-bit output: Clock dynamic divide done
      CLKFBOUT => ps_clk_fb, -- 1-bit output: Feedback clock
      CLKFBOUTB => open, -- 1-bit output: Inverted CLKFBOUT
      CLKFBSTOPPED => ps_clk_fb_stopped, -- 1-bit output: Feedback clock stopped
      CLKINSTOPPED => ps_clk_in_stopped, -- 1-bit output: Input clock stopped
      CLKOUT0 => clk_ps_out,   -- 1-bit output: CLKOUT0
      CLKOUT0B => open, -- 1-bit output: Inverted CLKOUT0
      CLKOUT1  => open,   -- 1-bit output: CLKOUT1
      CLKOUT1B => open, -- 1-bit output: Inverted CLKOUT1
      CLKOUT2  => open,   -- 1-bit output: CLKOUT2
      CLKOUT2B => open, -- 1-bit output: Inverted CLKOUT2
      CLKOUT3  => open,   -- 1-bit output: CLKOUT3
      CLKOUT3B => open, -- 1-bit output: Inverted CLKOUT3
      CLKOUT4  => open,   -- 1-bit output: CLKOUT4
      CLKOUT5  => open,   -- 1-bit output: CLKOUT5
      CLKOUT6  => open,   -- 1-bit output: CLKOUT6
      DO => open,             -- 16-bit output: DRP data output
      DRDY =>  open,         -- 1-bit output: DRP ready
      LOCKED => ps_clk_locked,     -- 1-bit output: LOCK
      PSDONE => ps_clk_done,     -- 1-bit output: Phase shift done
      CDDCREQ => '0',   -- 1-bit input: Request to dynamic divide clock
      CLKFBIN => ps_clk_fb_bufg,   -- 1-bit input: Feedback clock
      CLKIN1 => txoutclk,     -- 1-bit input: Primary clock
      CLKIN2 => '0',     -- 1-bit input: Secondary clock
      CLKINSEL => '1', -- 1-bit input: Clock select, High=CLKIN1 Low=CLKIN2
      DADDR => (others => '0'),       -- 7-bit input: DRP address
      DCLK => '0',         -- 1-bit input: DRP clock
      DEN => '0',           -- 1-bit input: DRP enable
      DI => (others => '0'),             -- 16-bit input: DRP data input
      DWE => '0',           -- 1-bit input: DRP write enable
      PSCLK => clk_62m5,       -- 1-bit input: Phase shift clock
      PSEN => ps_clk_pen,         -- 1-bit input: Phase shift enable
      PSINCDEC => ps_clk_incdec, -- 1-bit input: Phase shift increment/decrement
      PWRDWN => ps_clk_pd,     -- 1-bit input: Power-down
      RST => ps_clk_rst            -- 1-bit input: Reset
      );

  inst_bufg_ps : BUFG
    port map (
      I => clk_ps_out,
      O => clk_ps
    );

  inst_bufg_ps_fb: BUFG
    port map (
      I => ps_clk_fb,
      O => ps_clk_fb_bufg
    );

  process(clk_62m5, pll_locked)
  begin
    if pll_locked = '0' then
      rst_n <= '0';
    elsif rising_edge(clk_62m5) then
      if rst_cnt = 15 then
        rst_n <= '1';
      else
        rst_n <= '0';
        rst_cnt <= rst_cnt + 1;
      end if;
    end if;
  end process;

  rst <= not rst_n;

  process(clk_25m)
  begin
    if rising_edge(clk_25m) then
      if rst_n = '0' then
        led1_o <= '0';
        led2_o <= '1';
        count <= 0;
      else
        if count = 12_500_000 - 1 then
          led1_o <= '1';
          led2_o <= '0';
          count <= count + 1;
        elsif count = 25_000_000 - 1 then
          led1_o <= '0';
          led2_o <= '1';
          count <= 0;
        else
          count <= count + 1;
        end if;
      end if;
    end if;
  end process;

  inst_mpsoc: mpsoc
    port map (
      M_AXI_awaddr(31 downto 0) => m_axi4_out.awaddr,
      M_AXI_awaddr(39 downto 32) => m_axi_awaddr,
      M_AXI_awprot => open,
      M_AXI_awvalid => m_axi4_out.awvalid,
      M_AXI_awready => m_axi4_in.awready,
      M_AXI_wdata => m_axi4_out.wdata,
      M_AXI_wstrb => m_axi4_out.wstrb,
      M_AXI_wvalid => m_axi4_out.wvalid,
      M_AXI_wready => m_axi4_in.wready,
      M_AXI_bresp => m_axi4_in.bresp,
      M_AXI_bvalid => m_axi4_in.bvalid,
      M_AXI_bready => m_axi4_out.bready,
      M_AXI_araddr(31 downto 0) => m_axi4_out.araddr,
      M_AXI_araddr(39 downto 32) => m_axi_araddr,
      M_AXI_arprot => open,
      M_AXI_arvalid => m_axi4_out.arvalid,
      M_AXI_arready => m_axi4_in.arready,
      M_AXI_rdata => m_axi4_in.rdata,
      M_AXI_rresp => m_axi4_in.rresp,
      M_AXI_rvalid => m_axi4_in.rvalid,
      M_AXI_rready => m_axi4_out.rready,
      UART_0_0_rxd => uart_rx,
      UART_0_0_txd => uart_tx,
      rst_axi_n => rst_n,
      clk_axi => clk_62m5
    );

  inst_mpsoc_map: entity work.mpsoc_map
  port map (
    aclk => clk_62m5,
    areset_n => rst_n,
    awaddr => m_axi4_out.awaddr(12 downto 2),
    awvalid => m_axi4_out.awvalid,
    awready => m_axi4_in.awready,
    awprot => "000",
    wvalid => m_axi4_out.wvalid,
    wready => m_axi4_in.wready,
    wdata => m_axi4_out.wdata,
    wstrb => m_axi4_out.wstrb,
    bvalid => m_axi4_in.bvalid,
    bready => m_axi4_out.bready,
    bresp => m_axi4_in.bresp,
    araddr => m_axi4_out.araddr(12 downto 2),
    arvalid => m_axi4_out.arvalid,
    arready => m_axi4_in.arready,
    arprot => "000",
    rvalid => m_axi4_in.rvalid,
    rready => m_axi4_out.rready,
    rdata => m_axi4_in.rdata,
    rresp => m_axi4_in.rresp,

    wrpc_i => wb_wrpc_in,
    wrpc_o => wb_wrpc_out,

    ctrl_led1_o => open,
    ctrl_led2_o => open,
    ctrl_gth_rst_o => open,
    ctrl_gth_tx_rst_o => open,
    ctrl_gth_tx_pcs_rst_o => open,
    ctrl_gth_tx_pma_rst_o => open,
    ctrl_gth_rx_rst_o => open,
    ctrl_gth_rx_pcs_rst_o => open,
    ctrl_gth_rx_pma_rst_o => open,
    ctrl_gth_rx_buf_rst_o => open,
    status_i(31 downto 16) => (others => '0'),
    status_i(15 downto 0) => gth_status,
    qpll0_sdm_o => open,
    qpll0_sdm_wr_o => open,
    qpll1_sdm_o => hpll_data_out,
    qpll1_sdm_wr_o => hpll_load,
    rxpi_count_i => std_logic_vector(rxpi_rdcount),
    rxpi_tag_i => rxpi_data,
    rxpi_nsamp_o => rxpi_fifo_samp,
    rxpi_direct_i(31 downto 7) => (others => '0'),
    rxpi_direct_i(6 downto 0) => rxpi_one_samp,

    bitslide_slide_i => '0',
    bitslide_force_o => bitslide_force,
    bitslide_slide_o => bitslide_slide,
    bitslide_wr_o => bitslide_wr,
    bitslide_value_i => bitslide_val,
    bitslide_value_o => open,

    nbr_comma_det_i => std_logic_vector(nbr_comma),
    nbr_byte_align_i => std_logic_vector(nbr_bytealign)
  );
 
  process (clk_62m5)
  begin
    if rising_edge(clk_62m5) then
      if rst_n = '0' then
        nbr_counter <= (others => '0');
        nbr_comma <= (others => '0');
        nbr_bytealign <= (others => '0');
        nbr_comma_cnt <= (others => '0');
        nbr_bytealign_cnt <= (others => '0');
      else
        if gth_rx_comma_det_in = '1' then
          nbr_comma_cnt <= nbr_comma_cnt + 1;
        end if;
        if gth_rx_byte_aligned_in = '1' then
          nbr_bytealign_cnt <= nbr_bytealign_cnt + 1;
        end if;
        nbr_counter <= nbr_counter + 1;
        if nbr_counter = 16#01_00_00_00# then
          nbr_counter <= (others => '0');
          nbr_comma <= nbr_comma_cnt;
          nbr_bytealign <= nbr_bytealign_cnt;
          nbr_comma_cnt <= (others => '0');
          nbr_bytealign_cnt <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  process (clk_62m5)
  begin
    if rising_edge(clk_62m5) then
      if rst_n = '0' then
        bitslide_pulse <= '0';
      else
        if bitslide_wr = '1' and bitslide_slide = '1' then
          bitslide_pulse <= '1';
          bitslide_cnt <= "11";
        elsif bitslide_cnt /= "00" then
          bitslide_cnt <= bitslide_cnt - 1;
        else
          bitslide_pulse <= '0';
        end if;
      end if;
    end if;
  end process;

  inst_sync_bitslide: entity work.gc_sync_ffs
    port map (
      clk_i => phy16_in.rx_clk,
      rst_n_i => '1',
      data_i => bitslide_pulse,
      synced_o => open,
      ppulse_o => bitslide_pulse_rx,
      npulse_o => open
    );
  
  process (phy16_in.rx_clk)
  begin
    if rising_edge(phy16_in.rx_clk) then
      bitslide_pulse_rx_d <= bitslide_pulse_rx;
      bitslide_pulse_out <= bitslide_pulse_rx or bitslide_pulse_rx_d;
    end if;
  end process;

  gth_rst_n <= not gth_rst;

   sfp_tx_disable_o <= phy16_out.sfp_tx_disable;
   phy16_in.sfp_tx_fault <= sfp_tx_fault_i;
 
  sfp_sda_b <= '0' when sfp_sda_out = '0' else 'Z';
  sfp_scl_b <= '0' when sfp_scl_out = '0' else 'Z';

  process(clk_62m5)
  begin
    if rising_edge(clk_62m5) then
      if rst_n = '0' then
        mpll_cnt <= (others => '0');
        hpll_cnt <= (others => '0');
        mpll_toggle <= '0';
        hpll_toggle <= '0';
      else
        if mpll_cnt = 0 then
          --  Idle, can accept a new value
          if mpll_load = '1' then
            --  Reformat.
            --  According to 73205, only LSB are significant.
            mpll_data <= (others => '0');
            mpll_data(13 downto 0) <= mpll_data_out(15 downto 2);
            mpll_cnt <= (others => '1');
          end if;
        else
          --  FB CLK should be way higher than system clock
          if mpll_cnt(5 downto 4) = "00" then
            mpll_toggle <= '0';
          elsif mpll_cnt(5 downto 4) /= "11" then
            mpll_toggle <= '1';
          end if;
          mpll_cnt <= mpll_cnt - 1;
        end if;

        if hpll_cnt = 0 then
          --  Idle, can accept a new value
          if hpll_load = '1' then
            --  Reformat.
            --  According to 73205, only LSB are significant.
            hpll_data <= (others => '0');
            hpll_data(23 downto 0) <= hpll_data_out(23 downto 0); -- b"1111_111" & hpll_data_out & '0';
            hpll_cnt <= (others => '1');
          end if;
        else
          --  FB CLK should be way higher than system clock
          if hpll_cnt(5 downto 4) = "00" then
            hpll_toggle <= '0';
          elsif mpll_cnt(5 downto 4) /= "11" then
            hpll_toggle <= '1';
          end if;
          hpll_cnt <= hpll_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  --  The common part of the gthe4.
  --  The values can be found in the top-level module generated when the common
  --  part is included.
  inst_gth_common: gthe4_common
    generic map (
      AEN_QPLL0_FBDIV       =>          '1',
      AEN_QPLL1_FBDIV       =>          '1',
      AEN_SDM0TOGGLE        =>          '0',
      AEN_SDM1TOGGLE        =>          '0',
      A_SDM0TOGGLE          =>          '0',
      A_SDM1DATA_HIGH       =>          "000000000",
      A_SDM1DATA_LOW        =>          "0000000000000000",
      A_SDM1TOGGLE          =>          '0',
      BIAS_CFG0             =>          "0000000000000000",
      BIAS_CFG1             =>          "0000000000000000",
      BIAS_CFG2             =>          "0000000100100100",
      BIAS_CFG3             =>          "0000000001000001",
      BIAS_CFG4             =>          "0000000000010000",
      BIAS_CFG_RSVD         =>          "0000000000000000",
      COMMON_CFG0           =>          "0000000000000000",
      COMMON_CFG1           =>          "0000000000000000",
      POR_CFG               =>          "0000000000000000",
      PPF0_CFG              =>          "0000011000000000",
      PPF1_CFG              =>          "0000011000000000",
      QPLL0CLKOUT_RATE      =>          "HALF",
      QPLL0_CFG0            =>          "0011001100011100",
      QPLL0_CFG1            =>          "1101000000111000",
      QPLL0_CFG1_G3         =>          "1101000000111000",
      QPLL0_CFG2            =>          "0000111111000000",
      QPLL0_CFG2_G3         =>          "0000111111000000",
      QPLL0_CFG3            =>          "0000000100100000",
      QPLL0_CFG4            =>          "0000000000000011",
      QPLL0_CP              =>          "0011111111",
      QPLL0_CP_G3           =>          "0000001111",
      QPLL0_FBDIV           =>          64,
      QPLL0_FBDIV_G3        =>          160,
      QPLL0_INIT_CFG0       =>          "0000001010110010",
      QPLL0_INIT_CFG1       =>          "00000000",
      QPLL0_LOCK_CFG        =>          "0010010111101000",
      QPLL0_LOCK_CFG_G3     =>          "0010010111101000",
      QPLL0_LPF             =>          "1000111111",
      QPLL0_LPF_G3          =>          "0111010101",
      QPLL0_PCI_EN          =>          '0',
      QPLL0_RATE_SW_USE_DRP =>          '1',
      QPLL0_REFCLK_DIV      =>          1,
      QPLL0_SDM_CFG0        =>          "0000000000000000",
      QPLL0_SDM_CFG1        =>          "0000000000000000",
      QPLL0_SDM_CFG2        =>          "0000000000000000",
      QPLL1CLKOUT_RATE      =>          "HALF",
      QPLL1_CFG0            =>          "0011001100011100",
      QPLL1_CFG1            =>          "1101000000111000",
      QPLL1_CFG1_G3         =>          "1101000000111000",
      QPLL1_CFG2            =>          "0000111111000011",
      QPLL1_CFG2_G3         =>          "0000111111000011",
      QPLL1_CFG3            =>          "0000000100100000",
      QPLL1_CFG4            =>          "0000000000000011",
      QPLL1_CP              =>          "0011111111",
      QPLL1_CP_G3           =>          "0001111111",
      QPLL1_FBDIV           =>          64,
      QPLL1_FBDIV_G3        =>          80,
      QPLL1_INIT_CFG0       =>          "0000001010110010",
      QPLL1_INIT_CFG1       =>          "00000000",
      QPLL1_LOCK_CFG        =>          "0010010111101000",
      QPLL1_LOCK_CFG_G3     =>          "0010010111101000",
      QPLL1_LPF             =>          "1000011111",
      QPLL1_LPF_G3          =>          "0111010100",
      QPLL1_PCI_EN          =>          '0',
      QPLL1_RATE_SW_USE_DRP =>          '1',
      QPLL1_REFCLK_DIV      =>          1,
      QPLL1_SDM_CFG0        =>          "0000000000000000",
      QPLL1_SDM_CFG1        =>          "0000000000000000",
      QPLL1_SDM_CFG2        =>          "0000000000000000",
      RSVD_ATTR0            =>          "0000000000000000",
      RSVD_ATTR1            =>          "0000000000000000",
      RSVD_ATTR2            =>          "0000000000000000",
      RSVD_ATTR3            =>          "0000000000000000",
      RXRECCLKOUT0_SEL      =>          "00",
      RXRECCLKOUT1_SEL      =>          "00",
      SARC_ENB              =>          '0',
      SARC_SEL              =>          '0',
      SDM0INITSEED0_0       =>          "0000000100010001",
      SDM0INITSEED0_1       =>          "000010001",
      SIM_DEVICE            =>          "ULTRASCALE_PLUS",
      SIM_MODE              =>          "FAST",
      SIM_RESET_SPEEDUP     =>          "TRUE"
    )
    port map (
      BGBYPASSB => '1',
      BGMONITORENB => '1',
      BGPDB => '1',
      BGRCALOVRD => "11111",
      BGRCALOVRDENB => '1',

      DRPADDR => (others => '0'),
      DRPCLK => clk_62m5,
      DRPDI => (others => '0'),
      DRPEN => '0',
      DRPWE => '0',
      DRPDO => open,
      DRPRDY => open,

      GTGREFCLK0 => '0',
      GTGREFCLK1 => '0',
      GTNORTHREFCLK00 => '0',
      GTNORTHREFCLK01 => '0',
      GTNORTHREFCLK10 => '0',
      GTNORTHREFCLK11 => '0',
      GTREFCLK00 => refclk_156m25,
      GTREFCLK01 => refclk_156m25,
      GTREFCLK10 => '0',
      GTREFCLK11 => '0',
      GTSOUTHREFCLK00 => '0',
      GTSOUTHREFCLK01 => '0',
      GTSOUTHREFCLK10 => '0',
      GTSOUTHREFCLK11 => '0',

      PCIERATEQPLL0 => "000",
      PCIERATEQPLL1 => "000",
      PMARSVD0 => x"00",
      PMARSVD1 => x"00",

      QPLL0CLKRSVD0 => '0',
      QPLL0CLKRSVD1 => '0',
      QPLL0FBDIV => x"40",
      QPLL0LOCKDETCLK => '0',
      QPLL0LOCKEN => '1',
      QPLL0PD => '0',
      QPLL0REFCLKSEL => "001", -- gtrefclk0
      QPLL0RESET => qpll0_reset,
      QPLL1CLKRSVD0 => '0',
      QPLL1CLKRSVD1 => '0',
      QPLL1FBDIV => x"40",
      QPLL1LOCKDETCLK => '0',
      QPLL1LOCKEN => '1',
      QPLL1PD => '0',
      QPLL1REFCLKSEL => "001",
      QPLL1RESET => qpll1_reset,
      QPLLRSVD1 => x"00",
      QPLLRSVD2 => "00000",
      QPLLRSVD3 => "00000",
      QPLLRSVD4 => x"00",
      RCALENB => '1',
      SDM0DATA => mpll_data,
      SDM0RESET => '0',
      SDM0TOGGLE => mpll_toggle,
      SDM0WIDTH => "00",  -- 00:24b
      SDM1DATA => hpll_data,
      SDM1RESET => '0',
      SDM1TOGGLE => hpll_toggle,
      SDM1WIDTH => "00",  -- 00:24b
      TCONGPI => b"00_0000_0000",
      TCONPOWERUP => '0',
      TCONRESET => "00",
      TCONRSVDIN1 => "00",
      PMARSVDOUT0 => open,
      PMARSVDOUT1 => open,
      QPLL0FBCLKLOST => open,
      QPLL0LOCK => qpll0_lock,
      QPLL0OUTCLK => qpll0_outclk,
      QPLL0OUTREFCLK => qpll0_outrefclk,
      QPLL0REFCLKLOST => open,
      QPLL1FBCLKLOST => open,
      QPLL1LOCK => qpll1_lock,
      QPLL1OUTCLK => qpll1_outclk,
      QPLL1OUTREFCLK => qpll1_outrefclk,
      QPLL1REFCLKLOST => open,
      QPLLDMONITOR0 => open,
      QPLLDMONITOR1 => open,
      REFCLKOUTMONITOR0 => open,
      REFCLKOUTMONITOR1 => open,
      RXRECCLK0SEL => open,
      RXRECCLK1SEL => open,
      SDM0FINALOUT => open,
      SDM0TESTDATA => open,
      SDM1FINALOUT => open,
      SDM1TESTDATA => open,
      TCONGPO => open,
      TCONRSVDOUT0 => open
  );


  inst_gth_channel: gthe4_sdm
    port map (
      gthrxn_in(0)  => pad_rxn_i,
      gthrxp_in(0)  => pad_rxp_i,
      gthtxn_out(0) => pad_txn_o,
      gthtxp_out(0) => pad_txp_o,

      gtrxreset_in(0) => gtrxreset,
      gttxreset_in(0) => gttxreset,
      rxpd_in(0)      => gth_rx_pd,
      rxpd_in(1)      => gth_rx_pd,
      txpd_in(0)      => gth_tx_pd,
      txpd_in(1)      => gth_tx_pd,
      txuserrdy_in(0) => txusrrdy,
      rxuserrdy_in(0) => rxusrrdy,

      txprogdivreset_in(0) => '0',
      rxprogdivreset_in(0) => '0',
      rxbufreset_in(0) => rxbufreset,
      rxpcsreset_in(0) => rxpcsreset,
      rxpmareset_in(0) => rxpmareset,
      txpmareset_in(0) => txpmareset,
      txpcsreset_in(0) => txpcsreset,

      rxoutclk_out(0) => rxoutclk_out,
      rxusrclk_in(0) => rxoutclk,
      rxusrclk2_in(0) => rxoutclk,
      txoutclk_out(0) => txoutclk_out,
      txusrclk_in(0) => txoutclk,
      txusrclk2_in(0) => txoutclk,

      rxcdrlock_out(0) => rx_cdr_stable_out,
      rxresetdone_out(0) => rx_reset_done,
      txresetdone_out(0) => tx_reset_done,

      gtwiz_userclk_tx_active_in(0) => '1',
      gtwiz_userclk_rx_active_in(0) => '1',
      gtwiz_reset_tx_done_in(0) => tx_reset_done,
      gtwiz_reset_rx_done_in(0) => tx_reset_done,

--      gtwiz_reset_qpll0reset_out(0) => qpll0_reset,
--      gtwiz_reset_qpll0lock_in(0) => qpll0_lock,
--      gtwiz_reset_qpll1reset_out(0) => qpll1_reset,
--      gtwiz_reset_qpll1lock_in(0) => qpll1_lock,
--      gtwiz_reset_clk_freerun_in(0) => clk_62m5,
--      gtwiz_reset_all_in(0) => gtwiz_reset_all_out,
--      gtwiz_reset_tx_pll_and_datapath_in(0) => '0',
--      gtwiz_reset_tx_datapath_in(0) => '0',
--      gtwiz_reset_rx_pll_and_datapath_in(0) => '0',
--      gtwiz_reset_rx_datapath_in(0) => '0',
--      gtwiz_reset_rx_cdr_stable_out(0) => gtwiz_reset_rx_cdr_stable_out, --gth_status_a(2),
--      gtwiz_reset_tx_done_out(0) => gtwiz_reset_tx_done_in, --gth_status_a(3),
--      gtwiz_reset_rx_done_out(0) => gtwiz_reset_rx_done_in, -- gth_status_a(4),
      gtwiz_userdata_tx_in => gth_tx_data_out,
      gtwiz_userdata_rx_out => gth_rx_data_in,

      qpll0clk_in(0) => qpll0_outclk,
      qpll0refclk_in(0) => qpll0_outrefclk,
      qpll1clk_in(0) => qpll1_outclk,
      qpll1refclk_in(0) => qpll1_outrefclk,

      txpllclksel_in => "11", --  11: QPLL0
      rx8b10ben_in(0) => '1',
      rxcommadeten_in(0) => '1',
      rxmcommaalignen_in(0) => '0',
      rxpcommaalignen_in(0) => '0',
      rxslide_in(0) => gth_rx_slide,
      tx8b10ben_in(0) => '1',
      txctrl0_in => x"0000",
      txctrl1_in => x"0000",
      txctrl2_in => gth_tx_k_out,
      gtpowergood_out(0) => gth_powergood,
      rxbyteisaligned_out(0) => gth_rx_byte_aligned_in,
      rxbyterealign_out => open,
      rxcommadet_out(0) => gth_rx_comma_det_in,
      rxctrl0_out => gth_rx_k_in,
      rxctrl1_out => gth_rx_disp_err_in,
      rxctrl2_out => gth_rx_comma_in,
      rxctrl3_out => gth_rx_dec_err_in,
      rxpmaresetdone_out(0) => gth_rx_pma_reset_done_in,
      txpmaresetdone_out(0) => gth_tx_pma_reset_done_in,
--      txprgdivresetdone_out(0) => gth_tx_prg_div_reset_done,

      txpippmen_in(0) => '0',
      txpippmovrden_in(0) => '0',
      txpippmsel_in(0) => '1',
      txpippmpd_in(0) => '0',
      txpippmstepsize_in => b"1_0001", -- txpippmstepsize, -- b"1_0000",

      drpaddr_in => (others => '0'),
      drpclk_in(0) => clk_62m5,
      drpdi_in => (others => '0'),
      drpdo_out   => open,
      drpen_in(0) => '0',
      drpwe_in(0) => '0',
      drprdy_out => open,

      dmonitorout_out => dmonitorout,
      dmonitoroutclk_out(0) => gth_dmon_clk_out,
      dmonitorclk_in(0) => gth_dmon_clk
  );

  inst_gthe4_map: entity work.rxpi_gthe4_map
    port map (
      rst_n_i => rst_n,
      clk_i => clk_62m5,
      wb_i => wb_wraux_out,
      wb_o => wb_wraux_in,
      reset_gth_rst_o => gth_rst,
      reset_gth_tx_rst_o => gth_tx_rst,
      reset_gth_tx_pcs_rst_o => txpcsreset,
      reset_gth_tx_pma_rst_o => txpmareset,
      reset_gth_rx_rst_o => gth_rx_rst,
      reset_gth_rx_pcs_rst_o => rxpcsreset,
      reset_gth_rx_pma_rst_o => rxpmareset,
      reset_gth_rx_buf_rst_o => rxbufreset,
      status_i(31 downto 17) => (others => '0'),
      status_i(16) => rdy_in_62m5,
      status_i(15 downto 0) => gth_status,
      ctrl_rdy_o => rdy_out_62m5,
      bitslide_i(4 downto 0) => bitslide_val,
      bitslide_i(31 downto 5) => (others => '0'),

      ps_ctrl_shift_i => '0',
      ps_ctrl_shift_o => ps_clk_shift,
      ps_ctrl_wr_o => ps_clk_shift_wr,
      ps_ctrl_rst_o => ps_clk_rst,
      ps_ctrl_pd_o => ps_clk_pd,
      ps_ctrl_incdec_o => ps_clk_incdec,
      ps_stat_phase_i => std_logic_vector(ps_clk_phase),
      ps_stat_fb_stopped_i => ps_clk_fb_stopped,
      ps_stat_in_stopped_i => ps_clk_in_stopped,
      ps_stat_locked_i => ps_clk_locked,
      ps_stat_ps_busy_i => ps_clk_busy,
      ps_count_val_o => ps_clk_nsamp,
      ps_res_val_i => std_logic_vector(ps_clk_count_out),
      ps_res_gen_i => std_logic_vector(ps_clk_gen)
    );

  inst_sync_rxoutclk: entity work.gc_sync
    port map (
      clk_i => clk_ps,
      rst_n_a_i => ps_clk_rst_n,
      d_i => rxoutclk,
      q_o => rxoutclk_sync
    );
  
  ps_clk_rst_n <= not ps_clk_rst;

  ps_clk_pen <= ps_clk_shift_wr and ps_clk_shift;

  process (clk_62m5)
  begin
    if rising_edge(clk_62m5) then
      if ps_clk_rst = '1' then
        ps_clk_phase <= (others => '0');
        ps_clk_busy <= '1';
      else
        if ps_clk_done = '1' then
          ps_clk_busy <= '1';
        end if;

        if ps_clk_pen = '1' then
          ps_clk_busy <= '0';

          if ps_clk_incdec = '1' then
            ps_clk_phase <= ps_clk_phase + 1;
          else
            ps_clk_phase <= ps_clk_phase - 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  process (clk_ps)
    variable cnt : unsigned(23 downto 0);
  begin
    if rising_edge(clk_ps) then
      if ps_clk_rst = '1' then
        ps_clk_nsamp_cnt <= unsigned (ps_clk_nsamp);
        ps_clk_gen <= x"00";
      else
        if ps_clk_nsamp_cnt = 0 then
          ps_clk_nsamp_cnt <= unsigned(ps_clk_nsamp);
          ps_clk_count_out <= ps_clk_count;
          ps_clk_gen <= ps_clk_gen + 1;
          cnt := (others => '0');
        else
          ps_clk_nsamp_cnt <= ps_clk_nsamp_cnt - 1;
          cnt := ps_clk_count;
        end if;

        --  Sample the sync signal
        if rxoutclk_sync = '1' then
          cnt := cnt + 1;
        end if;
        ps_clk_count <= cnt;
      end if;
    end if;
  end process;


  --  As PMA slide mode is used, there is no extra latency.
  phy16_in.rx_bitslide <= (others => '0');

  inst_sync_rdy: entity work.gc_sync
    port map (
      clk_i => rxoutclk,
      rst_n_a_i => '1',
      d_i => rdy_out_62m5,
      q_o => phy16_in.rdy
    );

  inst_sync_rdy_in: entity work.gc_sync
    port map (
      clk_i => clk_62m5,
      rst_n_a_i => '1',
      d_i => rdy_in,
      q_o => rdy_in_62m5
    );

  gth_rx_slide <= gth_rx_slide_out when bitslide_force = '0' else bitslide_pulse_out;

  inst_bufg_gt_tx: BUFG_GT
    port map (
      I => txoutclk_out,
      O => txoutclk,
      CE => '1',
      CEMASK => '1',
      CLR => '0',
      CLRMASK => '1',
      DIV => "000"
    );

    phy16_in.ref_clk <= txoutclk;

  inst_bufg_gt_rx: BUFG_GT
    port map (
      I => rxoutclk_out,
      O => rxoutclk,
      CE => '1',
      CEMASK => '1',
      CLR => '0',
      CLRMASK => '1',
      DIV => "000"
    );

    phy16_in.rx_clk <= rxoutclk;
  
  inst_gth_dmon_bufg: BUFG_GT
    port map (
      I => gth_dmon_clk_out,
      O => gth_dmon_clk,
      DIV => "000",
      CE => '1',
      CEMASK => '1',
      CLR => '0',
      CLRMASK => '1'
    );

  inst_wrcore : entity work.xwr_core
    generic map (
      g_board_name => "KR26",
      --         g_dpram_initf => "../../../../bin/wrpc/wrc_phy16.bram",
      g_dpram_initf => "",
      g_dpram_size => 192 * 1024 / 4,
      g_pcs_16bit => true,
      g_records_for_phy => true,
      g_softpll_enable_debugger => true
      )
    port map (
      clk_sys_i => clk_62m5,
      rst_n_i => rst_n,
      clk_dmtd_i => '0', -- open,
      clk_ref_i => phy16_in.ref_clk,
      clk_dmtd_over_i => open,
      clk_aux_i => open,
      clk_ext_i => open,
      clk_ext_mul_i => open,
      clk_ext_mul_locked_i => open,
      clk_ext_stopped_i => open,
      clk_ext_rst_o => open,
      pps_ext_i => open,
      rxpi_valid_i => rxpi_valid,
      rxpi_i => rxpi_data(29 downto 8),
      dac_hpll_load_p1_o => open,
      dac_hpll_data_o => open,
      dac_dpll_load_p1_o => mpll_load,
      dac_dpll_data_o => mpll_data_out,
      phy_ref_clk_i => open,
      phy_tx_data_o => open,
      phy_tx_k_o => open,
      phy_tx_disparity_i => open,
      phy_tx_enc_err_i => open,
      phy_rx_data_i => open,
      phy_rx_rbclk_i => open,
      phy_rx_rbclk_sampled_i => open,
      phy_rx_k_i => open,
      phy_rx_enc_err_i => open,
      phy_rx_bitslide_i => open,
      phy_mdio_master_o => open,
      phy_mdio_master_i => open,
      phy_rst_o => open,
      phy_rdy_i => open,
      phy_loopen_o => open,
      phy_loopen_vec_o => open,
      phy_tx_prbs_sel_o => open,
      phy_sfp_tx_fault_i => open,
      phy_sfp_los_i => open,
      phy_sfp_tx_disable_o => open,
      phy8_i => open,
      phy8_o => open,
      phy16_o => phy16_out,
      phy16_i => phy16_in,
      scl_o => open,
      scl_i => open,
      sda_o => open,
      sda_i => open,
      sfp_det_i => sfp_mod_abs_i,
      sfp_scl_o => sfp_scl_out,
      sfp_scl_i => sfp_scl_b,
      sfp_sda_o => sfp_sda_out,
      sfp_sda_i => sfp_sda_b,
      spi_sclk_o => open,
      spi_ncs_o => open,
      spi_mosi_o => open,
      spi_miso_i => open,
      owr_pwren_o => open,
      owr_en_o => open,
      owr_i => open,
      uart_rxd_i => uart_tx,
      uart_txd_o => uart_rx,
      slave_i => wb_wrpc_out,
      slave_o => wb_wrpc_in,
      aux_master_i => wb_wraux_in,
      aux_master_o => wb_wraux_out,
      wrf_src_o => open,
      wrf_src_i => open,
      wrf_snk_o => open,
      wrf_snk_i => open,
      timestamps_o => open,
      timestamps_ack_i => open,
      abscal_txts_o => abscal_tx,
      abscal_rxts_o => abscal_rx,
      fc_tx_pause_req_i => open,
      fc_tx_pause_delay_i => open,
      fc_tx_pause_ready_o => open,
      tm_link_up_o => open,
      tm_time_valid_o => open,
      tm_tai_o => open,
      tm_cycles_o => open,
      tm_clk_aux_lock_en_i => open,
      tm_clk_aux_locked_o => open,
      tm_dac_value_o => open,
      tm_dac_wr_o => open,
      pps_csync_o => open,
      pps_valid_o => open,
      pps_p_o => open,
      pps_led_o => open,
      rst_aux_n_o => open,
      led_act_o => sfp_led2_o,
      led_link_o => sfp_led1_o,
      link_ok_o => open,
      aux_diag_i => open,
      aux_diag_o => open,
      btn1_i => open,
      btn2_i => open
      );
    
  inst_gthe4_adapter: entity work.wr_gthe4_adapter
    port map (
      tx_locked_o => open,
      tx_data_i => phy16_out.tx_data,
      tx_k_i => phy16_out.tx_k,
      tx_disparity_o => phy16_in.tx_disparity,
      tx_enc_err_o => phy16_in.tx_enc_err,
      rx_data_o => phy16_in.rx_data,
      rx_k_o => phy16_in.rx_k,
      rx_enc_err_o => phy16_in.rx_enc_err,
      rx_bitslide_o => bitslide_val,
      rst_i => phy_rst,
      rdy_o => rdy_in,
      gtwiz_userclk_tx_reset_o => open,
      gtwiz_userclk_tx_active_i => '1',
      gtwiz_userclk_rx_reset_o => open,
      gtwiz_userclk_rx_active_i => '1',
      gtwiz_buffbypass_tx_reset_o => open,
      gtwiz_buffbypass_tx_done_i => '1',
      gtwiz_buffbypass_rx_reset_o => open,
      gtwiz_buffbypass_rx_start_user_o => open,
      gtwiz_buffbypass_rx_done_i => '1',
      gtwiz_reset_all_o => open,  --  same as phy_rst
      gtwiz_reset_tx_done_i => tx_reset_done,
      gtwiz_reset_rx_done_i => rx_reset_done,
      gth_rx_data_i => gth_rx_data_in,
      gth_tx_data_o => gth_tx_data_out,
      gth_rx_slide_o => gth_rx_slide_out,
      gth_rx_k_i => gth_rx_k_in(1 downto 0),
      gth_tx_k_o => gth_tx_k_out(1 downto 0),
      gth_rx_dec_err_i => gth_rx_dec_err_in(1 downto 0),
      gth_rx_disp_err_i => gth_rx_disp_err_in(1 downto 0),
      gth_rx_byte_aligned_i => gth_rx_byte_aligned_in,
      gth_rx_comma_det_i => gth_rx_comma_det_in,
      gth_rx_pma_reset_done_i => gth_rx_pma_reset_done_in,
      gth_tx_pma_reset_done_i => gth_tx_pma_reset_done_in,
      gth_rx_clk_i => phy16_in.rx_clk,
      gth_tx_clk_i => phy16_in.ref_clk
      );

  --  Generate some outputs on PMOD

  -- process(txoutclk)
  --   variable cnt : natural range 0 to 4 := 0;
  --   variable v : std_logic := '0';
  -- begin
  --   if rising_edge(txoutclk) then
  --     if cnt = 4 then
  --       cnt := 0;
  --       pmod4_6_b <= v;
  --       v := not v;
  --     else
  --       cnt := cnt + 1;
  --     end if;
  --   end if;
  -- end process;

  -- process(phy16_in.rx_clk)
  --   variable cnt : natural range 0 to 4 := 0;
  --   variable v   : std_logic            := '0';
  -- begin
  --   if rising_edge(phy16_in.rx_clk) then
  --     if cnt = 4 then
  --       cnt := 0;
  --       pmod4_4_b <= v;
  --       v := not v;
  --     else
  --       cnt := cnt + 1;
  --     end if;
  --   end if;
  -- end process;

  -- pmod4_4_b <= gth_dmon_clk;

  b_pmod: block
  begin
    pmod4_2_b <= phy16_in.ref_clk; --  The WR reference clock
    pmod4_4_b <= '0'; -- phy16_in.rx_clk; --  The recovered clock
    pmod4_6_b <= abscal_tx; -- '0'; -- clk_ps;
    pmod4_8_b <= abscal_rx;
  end block;

  --  clk_ps; phase shift clock

  inst_gth_rst_sync: entity work.gc_sync
    port map (
      clk_i => gth_dmon_clk,
      rst_n_a_i => '1',
      d_i => gth_rst_n,
      q_o => gth_dmon_rst_n
    );
  
  b_rxpi: block
    alias rxpi is dmonitorout(6 downto 0);
    signal rxpi_ext : std_logic_vector(31 downto 0);
    alias rxpi_d is rxpi_ext(rxpi'range);

    signal rxpi_cnt : unsigned(31 downto 0);
    signal rxpi_acc : unsigned(31 downto 0);
    signal rxpi_res : std_logic_vector(31 downto 0);
    signal rxpi_wr, rxpi_sync_ack : std_logic;
  begin
    process(gth_dmon_clk)
    begin
      if rising_edge(gth_dmon_clk) then
        rxpi_wr <= '0';
        rxpi_one_samp_dmon <= rxpi;

        if gth_dmon_rst_n = '0' then
          --  Start point
          case rxpi(6 downto 5) is
            when "00" =>
              --  Might go below 0.
              rxpi_ext_0 <= x"000000" & '0';
              rxpi_ext_1 <= x"ffffff" & '1';
            when "11" =>
              --  Might go above 0x7f
              rxpi_ext_0 <= x"000000" & '1';
              rxpi_ext_1 <= x"000000" & '0';
            when others =>
              --  Safe
              rxpi_ext_0 <= (others => '0');
              rxpi_ext_1 <= (others => '0');
          end case;
          rxpi_cnt <= unsigned(rxpi_fifo_samp);
        else
          if rxpi_sync_ack = '1' then
            rxpi_wr <= '0';
          end if;
          if rxpi_cnt = 0 then
            rxpi_res <= std_logic_vector(rxpi_acc);
            rxpi_acc <= unsigned(rxpi_ext);
            rxpi_wr <= '1';
            rxpi_cnt <= unsigned(rxpi_fifo_samp);
          else
            rxpi_acc <= rxpi_acc + unsigned(rxpi_ext);
            rxpi_cnt <= rxpi_cnt - 1;
          end if;

          --  Extend rxpi
          if rxpi(rxpi'high) = '1' then
            rxpi_ext(rxpi_ext_1'range) <= rxpi_ext_1;
          else
            rxpi_ext(rxpi_ext_0'range) <= rxpi_ext_0;
          end if;
          rxpi_ext(rxpi'range) <= rxpi;

          --  Update extensions.
          --  When rxpi increases:
          if rxpi_d(6 downto 3) = "0100" and rxpi(6 downto 3) = "0101" then
            --  Moving towards 1.
            rxpi_ext_1 <= rxpi_ext_0;
          end if;
          if rxpi_d(6 downto 3) = "1100" and rxpi(6 downto 3) = "1101" then
            --  Moving towards 0.
            rxpi_ext_0 <= std_logic_vector(unsigned(rxpi_ext_1) + 1);
          end if;

          --  When rxpi decreases:
          if rxpi_d(6 downto 3) = "1011" and rxpi(6 downto 3) = "1010" then
            --  Moving away from 1.
            rxpi_ext_0 <= rxpi_ext_1;
          end if;
          if rxpi_d(6 downto 3) = "0011" and rxpi(6 downto 3) = "0010" then
            --  Moving towards 0.
            rxpi_ext_1 <= std_logic_vector(unsigned(rxpi_ext_0) - 1);
          end if;
        end if;
      end if;
    end process;

    --  Synchronizer for rxpi acc.
    inst_sync_rxpi: entity work.gc_sync_word_wr
      generic map (
        g_auto_wr => false,
        g_width => 32
      )
      port map (
        clk_in_i => gth_dmon_clk,
        rst_in_n_i => gth_dmon_rst_n,
        clk_out_i => clk_62m5,
        rst_out_n_i => rst_n,
        data_i => rxpi_res,
        wr_i => rxpi_wr,
        busy_o => open,
        ack_o => rxpi_sync_ack,
        data_o => rxpi_data,
        wr_o => rxpi_valid
      );

    inst_sync_rxpi_one: entity work.gc_sync_word_wr
      generic map (
        g_auto_wr => true,
        g_width => 7
      )
      port map (
        clk_in_i => gth_dmon_clk,
        rst_in_n_i => gth_dmon_rst_n,
        clk_out_i => clk_62m5,
        rst_out_n_i => rst_n,
        data_i => rxpi_one_samp_dmon,
        wr_i => open,
        busy_o => open,
        ack_o => open,
        data_o => rxpi_one_samp,
        wr_o => open
      );
  end block;

  process (clk_62m5)
  begin
    if rising_edge(clk_62m5) then
      if rst_n = '0' then
        rxpi_rdcount <= (others => '0');
      else
        if rxpi_valid = '1' then
          rxpi_rdcount <= rxpi_rdcount + 1;
        end if;
      end if;
    end if;
  end process;

  b_rst: block
    signal powergood_dly : std_logic;
    constant pg_dly_len : natural := 250_000 / 16; --  250us / clk_cyc
    signal pg_dly_cnt : natural range 0 to pg_dly_len := 0;
    constant pd_dly_len : natural := 10;
    signal pd_dly_cnt : natural range 0 to pd_dly_len;
    signal pd_dly : std_logic;
  begin
    process (clk_62m5, gth_powergood)
    begin
      if gth_powergood = '0' then
        powergood_dly <= '0';
        pg_dly_cnt <= 0;
      elsif rising_edge(clk_62m5) then
        if pg_dly_cnt = pg_dly_len then
          powergood_dly <= '1';
        else
          pg_dly_cnt <= pg_dly_cnt + 1;
        end if;
      end if;
    end process;

    process (clk_62m5)
    begin
      if rising_edge(clk_62m5) then
        if phy_rst = '1' then
          pd_dly <= '1';
          pd_dly_cnt <= 0;
        elsif pd_dly_cnt < pd_dly_len then
          pd_dly_cnt <= pd_dly_cnt + 1;
        else
          pd_dly <= '0';
        end if;
      end if;
    end process;

    phy_rst <= gth_rst or phy16_out.rst;

    qpll1_reset <= not powergood_dly;
    qpll0_reset <= not powergood_dly;

    rxusrrdy <= powergood_dly;
    txusrrdy <= powergood_dly;

    gth_rx_pd <= phy_rst;
    gth_tx_pd <= phy_rst;

    gttxreset <= not powergood_dly or not qpll0_lock or pd_dly or gth_rx_rst;
    gtrxreset <= not powergood_dly or not qpll0_lock or pd_dly or gth_tx_rst;
  end block;

  gen_ila: if true generate
    component ila_0
      port (
        clk    : in STD_LOGIC;
        probe0 : in STD_LOGIC_VECTOR(63 downto 0)
      );
    end component  ;

  begin
    gth_status_a(0) <= gth_powergood;
    gth_status_a(1) <= rx_cdr_stable_out;
    gth_status_a(2) <= tx_reset_done;
    gth_status_a(3) <= rx_reset_done;

    gth_status_a(4) <= qpll0_reset;
    gth_status_a(5) <= qpll0_lock;
    gth_status_a(6) <= qpll1_reset;
    gth_status_a(7) <= qpll1_lock;

    gth_status_a(8) <= gth_rx_pma_reset_done_in;
    gth_status_a(9) <= gth_rx_pma_reset_done_in;
    gth_status_a(10) <= gth_rx_byte_aligned_in;
    gth_status_a(11) <= gth_rx_comma_det_in;

    gth_status_a(12) <= gth_tx_prg_div_reset_done;
    gth_status_a(13) <= rdy_in;
    gth_status_a(14) <= gth_rx_slide;
    gth_status_a(15) <= phy_rst;

    gen_sync: for i in gth_status'range generate
      inst_sync: entity work.gc_sync
        port map (
          clk_i => clk_62m5,
          rst_n_a_i => rst_n,
          d_i => gth_status_a(i),
          q_o => gth_status(i)
          );
    end generate;

    inst_ila: ila_0
      port map (
        clk => phy16_in.rx_clk,
        probe0 (15 downto 0) => phy16_in.rx_data,
        probe0(16) => gth_rx_byte_aligned_in,
        probe0(17) => gth_rx_comma_det_in,
        probe0(18) => gth_rx_slide,
        probe0(19) => bitslide_force,
        probe0(20) => bitslide_pulse_rx,
        probe0(21) => bitslide_wr,
        probe0(22) => bitslide_slide,
        probe0(23) => bitslide_force,
        probe0(28 downto 24) => phy16_in.rx_bitslide,
        probe0(30 downto 29) => gth_rx_k_in(1 downto 0),
        probe0(32 downto 31) => gth_rx_disp_err_in(1 downto 0),
        probe0(34 downto 33) => gth_rx_comma_in(1 downto 0),
        probe0(36 downto 35) => gth_rx_dec_err_in(1 downto 0),
        probe0(63 downto 37) => (others => '0')
        --probe0 (31 downto 16) => gth_status(15 downto 0)
        );
  end generate;
end top;
