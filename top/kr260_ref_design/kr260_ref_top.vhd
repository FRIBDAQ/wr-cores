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
    pmod4_6_b : out std_logic
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
    gtwiz_reset_clk_freerun_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_all_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_pll_and_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_pll_and_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_datapath_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_qpll0lock_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_qpll1lock_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_cdr_stable_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_tx_done_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_rx_done_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_qpll0reset_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    gtwiz_reset_qpll1reset_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
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
    qpll0clk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll0refclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll1clk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    qpll1refclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rx8b10ben_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxcommadeten_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxmcommaalignen_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxpcommaalignen_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxslide_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxusrclk_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxusrclk2_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    tx8b10ben_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txctrl0_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    txctrl1_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    txctrl2_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    txpippmen_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpippmovrden_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpippmpd_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpippmsel_in : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpippmstepsize_in : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    txpllclksel_in : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
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
    rxcommadet_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxctrl0_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    rxctrl1_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    rxctrl2_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rxctrl3_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rxoutclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    rxpmaresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    txoutclk_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    txpmaresetdone_out : OUT STD_LOGIC_VECTOR(0 DOWNTO 0) 
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
  signal uart_rx, uart_tx : std_logic;
  signal sfp_scl_out, sfp_sda_out : std_logic;

  signal wb_wrpc_in: t_wishbone_master_in;
  signal wb_wrpc_out: t_wishbone_master_out;

--  signal phy16_out : t_phy_16bits_from_wrc;
--  signal phy16_in : t_phy_16bits_to_wrc;

  signal gtwiz_reset_all_out : std_logic;
  signal gtwiz_reset_tx_done_in : std_logic;
  signal gtwiz_reset_rx_done_in : std_logic;

  signal gtwiz_reset_rx_cdr_stable_out : std_logic;

  signal gth_rx_data_in : std_logic_vector(15 downto 0);
  signal gth_tx_data_out : std_logic_vector(15 downto 0);
  signal gth_rx_slide_out : std_logic;
  signal gth_rx_k_in : std_logic_vector(15 downto 0);
  signal gth_tx_k_out : std_logic_vector(7 downto 0) := (others => '0');
  signal gth_rx_byte_aligned_in : std_logic;
  signal gth_rx_comma_det_in : std_logic;
  signal gth_rx_pma_reset_done_in : std_logic;
  signal gth_tx_pma_reset_done_in : std_logic;

  signal gth_powergood : std_logic;
  signal gth_tx_prg_div_reset_done : std_logic;

  signal mpll_data_out : std_logic_vector(31 downto 0);
  signal hpll_data_out : std_logic_vector(31 downto 0);
  signal hpll_load, mpll_load : std_logic;

  signal hpll_data, mpll_data : std_logic_vector(24 downto 0);
  signal hpll_toggle, mpll_toggle : std_logic;
  signal hpll_cnt, mpll_cnt : unsigned(5 downto 0);

  signal rxoutclk_out, rxoutclk : std_logic;
  signal txoutclk_out, txoutclk : std_logic;
  
  signal dmonitorout : std_logic_vector(15 downto 0);
  alias rxpi is dmonitorout(6 downto 0);
  signal rxpi_ext : std_logic_vector(31 downto 0);
  alias rxpi_d is rxpi_ext(rxpi'range);
  signal rxpi_ext_0, rxpi_ext_1 : std_logic_vector(31 downto 7);
  signal gth_dmon_clk, gth_dmon_clk_out, gth_dmon_rst_n : std_logic;

  signal rxpi_fifo_en, rxpi_fifo_rd, rxpi_fifo_nfull_wr : std_logic;
  signal rxpi_fifo_samp , rxpi_fifo_nfull, rxpi_fifo_dout : std_logic_vector(31 downto 0);
  signal rxpi_fifo_rdcount: std_logic_vector(31 downto 0) := (others => '0');

  signal gth_status_a, gth_status : std_logic_vector(15 downto 0) := (others => '0');

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
  inst_mmcm: mmcme4_base
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
      CLKOUT1 => pmod4_2_b,   -- 1-bit output: CLKOUT1
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
    ctrl_led2_o => sfp_led2_o,
    ctrl_gth_rst_o => gth_rst,
    status_i(31 downto 16) => (others => '0'),
    status_i(15 downto 0) => gth_status,
    qpll0_sdm_o => mpll_data_out,
    qpll0_sdm_wr_o => mpll_load,
    qpll1_sdm_o => hpll_data_out,
    qpll1_sdm_wr_o => hpll_load,
    fifo_rdcount_i => rxpi_fifo_rdcount,
    fifo_nfull_i => rxpi_fifo_nfull,
    fifo_nfull_o => open,
    fifo_nfull_wr_o => rxpi_fifo_nfull_wr,
    fifo_data_i => rxpi_fifo_dout,
    fifo_data_rd_o => rxpi_fifo_rd,
    rxpi_samp_o => rxpi_fifo_samp,
    fifo_ctrl_en_o => rxpi_fifo_en
  );

  gth_rst_n <= not gth_rst;

  wb_wrpc_in <= (dat => x"deadbeef", ack => '1', rty => '0', err => '0', stall => '0');

  sfp_tx_disable_o <= '0';

  sfp_sda_b <= 'Z';
  sfp_scl_b <= 'Z';

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
            mpll_data(23 downto 0) <= mpll_data_out(23 downto 0);
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
  inst_common: gthe4_common
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


  inst_gth: gthe4_sdm
    port map (
      gthrxn_in(0)  => pad_rxn_i,
      gthrxp_in(0)  => pad_rxp_i,
      gthtxn_out(0) => pad_txn_o,
      gthtxp_out(0) => pad_txp_o,

      rxoutclk_out(0) => rxoutclk_out,
      rxusrclk_in(0) => rxoutclk,
      rxusrclk2_in(0) => rxoutclk,
      txoutclk_out(0) => txoutclk_out,
      txusrclk_in(0) => txoutclk,
      txusrclk2_in(0) => txoutclk,

      gtwiz_userclk_tx_active_in(0) => '1',
      gtwiz_userclk_rx_active_in(0) => '1',
      
      gtwiz_reset_qpll0reset_out(0) => qpll0_reset,
      gtwiz_reset_qpll0lock_in(0) => qpll0_lock,
      gtwiz_reset_qpll1reset_out(0) => qpll1_reset,
      gtwiz_reset_qpll1lock_in(0) => qpll1_lock,
      gtwiz_reset_clk_freerun_in(0) => clk_62m5,
      gtwiz_reset_all_in(0) => gtwiz_reset_all_out,
      gtwiz_reset_tx_pll_and_datapath_in(0) => '0',
      gtwiz_reset_tx_datapath_in(0) => '0',
      gtwiz_reset_rx_pll_and_datapath_in(0) => '0',
      gtwiz_reset_rx_datapath_in(0) => '0',
      gtwiz_reset_rx_cdr_stable_out(0) => gtwiz_reset_rx_cdr_stable_out, --gth_status_a(2),
      gtwiz_reset_tx_done_out(0) => gtwiz_reset_tx_done_in, --gth_status_a(3),
      gtwiz_reset_rx_done_out(0) => gtwiz_reset_rx_done_in, -- gth_status_a(4),
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
      rxslide_in(0) => gth_rx_slide_out,
      tx8b10ben_in(0) => '1',
      txctrl0_in => x"0000",
      txctrl1_in => x"0000",
      txctrl2_in => gth_tx_k_out,
      gtpowergood_out(0) => gth_powergood,
      rxbyteisaligned_out(0) => gth_rx_byte_aligned_in,
      rxbyterealign_out => open,
      rxcommadet_out(0) => gth_rx_comma_det_in,
      rxctrl0_out => gth_rx_k_in,
      rxctrl1_out => open,
      rxctrl2_out => open,
      rxctrl3_out => open,
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

    gtwiz_reset_all_out <= gth_rst;


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

  gth_tx_data_out <= x"bcbc";
  gth_rx_k_in <= x"0001";

  --  Generate some outputs on PMOD

  process(txoutclk)
    variable cnt : natural range 0 to 4 := 0;
    variable v : std_logic := '0';
  begin
    if rising_edge(txoutclk) then
      if cnt = 4 then
        cnt := 0;
        pmod4_6_b <= v;
        v := not v;
      else
        cnt := cnt + 1;
      end if;
    end if;
  end process;

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

  pmod4_4_b <= gth_dmon_clk;

  inst_gth_rst_sync: entity work.gc_sync
    port map (
      clk_i => gth_dmon_clk,
      rst_n_a_i => '1',
      d_i => gth_rst_n,
      q_o => gth_dmon_rst_n
    );
  
  process(gth_dmon_clk)
  begin
    if rising_edge(gth_dmon_clk) then
      if gth_dmon_rst_n = '0' then
        rxpi_ext_0 <= (others => '0');
        rxpi_ext_1 <= (others => '0');
      else
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

  b_fifo: block
    signal rxpi_fifo_cnt : unsigned(31 downto 0);
    signal rxpi_fifo_odd, rxpi_fifo_we, rxpi_fifo_full : std_logic;
    signal rxpi_fifo_din : std_logic_vector(31 downto 0);
  begin
    process (gth_dmon_clk)
    begin
      if rising_edge(gth_dmon_clk) then
        rxpi_fifo_we <= '0';
        if gth_dmon_rst_n = '0' then
          rxpi_fifo_cnt <= unsigned(rxpi_fifo_samp);
          rxpi_fifo_odd <= '0';
          rxpi_fifo_nfull <= (others => '0');
        else
          if rxpi_fifo_en = '1' then
            if rxpi_fifo_cnt = 0 then
              if rxpi_fifo_odd = '0' then
                rxpi_fifo_din(15 downto 0) <= rxpi_ext(15 downto 0);
                rxpi_fifo_odd <= '1';
              else
                rxpi_fifo_din(31 downto 16) <= rxpi_ext(15 downto 0);
                rxpi_fifo_odd <= '0';
                if rxpi_fifo_full = '0' then
                  rxpi_fifo_we <= '1';
                else
                  rxpi_fifo_nfull <= std_logic_vector(unsigned(rxpi_fifo_nfull) + 1);
                end if;
              end if;
              rxpi_fifo_cnt <= unsigned(rxpi_fifo_samp);
            else
              rxpi_fifo_cnt <= rxpi_fifo_cnt - 1;
            end if;
          end if;
          if rxpi_fifo_nfull_wr = '1' then
            rxpi_fifo_nfull <= (others => '0');
          end if;
        end if;
      end if;
    end process;

  inst_rxpi_fifo: entity work.inferred_async_fifo
    generic map (
      g_data_width => 32,
      g_size => 4 * 1024,
      g_show_ahead => True,
      g_with_rd_empty => True,
      g_with_rd_full => True,
      g_with_rd_almost_empty => False,
      g_with_rd_almost_full => False,
      g_with_rd_count => True,
      g_with_wr_empty => False,
      g_with_wr_full => True,
      g_with_wr_almost_empty => False,
      g_with_wr_almost_full => False,
      g_with_wr_count => False,
      g_almost_empty_threshold => 0,
      g_almost_full_threshold => 1,
      g_memory_implementation_hint => open
    )
    port map (
      rst_n_i => gth_dmon_rst_n,
      clk_wr_i => gth_dmon_clk,
      d_i => rxpi_fifo_din,
      we_i => rxpi_fifo_we,
      wr_empty_o => open,
      wr_full_o => rxpi_fifo_full,
      wr_almost_empty_o => open,
      wr_almost_full_o => open,
      wr_count_o => open,
      clk_rd_i => clk_62m5,
      q_o => rxpi_fifo_dout,
      rd_i => rxpi_fifo_rd,
      rd_empty_o => open,
      rd_full_o => rxpi_fifo_rdcount(12),  --  When the fifo is full, rd_count_o = 0.
      rd_almost_empty_o => open,
      rd_almost_full_o => open,
      rd_count_o => rxpi_fifo_rdcount(11 downto 0)
    );
  end block;

  gth_rx_slide_out <= '0';

  gen_ila: if true generate
    component ila_0
      port (
        clk    : in STD_LOGIC;
        probe0 : in STD_LOGIC_VECTOR(31 downto 0)
      );
    end component  ;

  begin
    gth_status_a(0) <= gth_powergood;
    gth_status_a(1) <= gtwiz_reset_rx_cdr_stable_out;
    gth_status_a(2) <= gtwiz_reset_tx_done_in;
    gth_status_a(3) <= gtwiz_reset_rx_done_in;

    gth_status_a(4) <= qpll0_reset;
    gth_status_a(5) <= qpll0_lock;
    gth_status_a(6) <= qpll1_reset;
    gth_status_a(7) <= qpll1_lock;

    gth_status_a(8) <= gth_rx_pma_reset_done_in;
    gth_status_a(9) <= gth_rx_pma_reset_done_in;
    gth_status_a(10) <= gth_rx_byte_aligned_in;
    gth_status_a(11) <= gth_rx_comma_det_in;

    gth_status_a(12) <= gth_tx_prg_div_reset_done;
    gth_status_a(13) <= '0';
    gth_status_a(14) <= '0';
    gth_status_a(15) <= gth_rst;

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
        clk => gth_dmon_clk,
        probe0 (15 downto 0) => rxpi_ext(15 downto 0),
        probe0 (31 downto 16) => gth_status(15 downto 0)
        );
  end generate;
end top;