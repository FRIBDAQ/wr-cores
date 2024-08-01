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
--use work.wr_board_pkg.all;
--use work.wr_pxie_fmc_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity kr260_ref_top is
  port (
    refclk1_n_i : in std_logic;
    refclk1_p_i : in std_logic;

    pad_txn_o : out std_logic;
    pad_txp_o : out std_logic;

    pad_rxn_i : in std_logic;
    pad_rxp_i : in std_logic;

    led1_o : out std_logic;
    led2_o : out std_logic;
    sfp_led1_o : out std_logic;
    sfp_led2_o : out std_logic
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

  component gtwizard_ultrascale_qpll_example_top
    port (
      clk_gth_i : in std_logic;
      pad_rxn_i : in std_logic;
      pad_rxp_i : in std_logic;
      pad_txn_o : out std_logic;
      pad_txp_o : out std_logic;

      hb_gtwiz_reset_clk_freerun_in : in std_logic;
      hb_gtwiz_reset_all_in : in std_logic;

      link_down_latched_reset_in : in std_logic;
      serdes_ready_out : out std_logic;  
      link_down_latched_out : out std_logic;

      reset_all_o : out std_logic;
      userclk_tx_reset_o : out std_logic;
      userclk_tx_active_o : out std_logic;
      userclk_rx_reset_o : out std_logic;
      userclk_rx_active_o : out std_logic;
      buffbypass_tx_reset_o : out std_logic;
      buffbypass_tx_done_o : out std_logic;
      buffbypass_tx_error_o : out std_logic;
      buffbypass_rx_reset_o : out std_logic;
      buffbypass_rx_done_o : out std_logic;
      buffbypass_rx_error_o : out std_logic;
      reset_tx_pll_and_datapath_o : out std_logic;
      reset_tx_datapath_o : out std_logic;
      reset_rx_pll_and_datapath_o : out std_logic;
      reset_rx_datapath_o : out std_logic;
      reset_rx_cdr_stable_o : out std_logic;
      reset_tx_done_o : out std_logic;
      reset_rx_done_o : out std_logic;
      rx_pma_reset_done_o : out std_logic;
      tx_pma_reset_done_o : out std_logic;
      tx_prgdiv_reset_done_o : out std_logic;
      gt_powergood_o : out std_logic
    );
  end component;

  signal refclk_74m25, refclk_74m25_int : std_logic;
  signal rst_n, rst : std_logic := '0';
  signal rst_cnt : natural range 0 to 15 := 0;

  signal count : natural range 0 to 74_250_000 - 1;
  signal clk_74m25, clk_62m5 : std_logic;
  signal clk_fb, pll_locked : std_logic;

  signal m_axi4_out : t_axi4_lite_master_out_32;
  signal m_axi4_in : t_axi4_lite_master_in_32;
  signal m_axi_araddr, m_axi_awaddr : std_logic_vector(39 downto 32);

  signal gth_rst : std_logic;
  signal gth_status_a, gth_status : std_logic_vector(21 downto 0);
  signal uart_rx, uart_tx : std_logic;

  signal wb_wrpc_in: t_wishbone_master_in;
  signal wb_wrpc_out: t_wishbone_master_out;
begin
  inst_ibufds_gt : IBUFDS_GTE4
      generic map (
        REFCLK_EN_TX_PATH  => '0',
        REFCLK_HROW_CK_SEL => "00",
        REFCLK_ICNTL_RX    => "00")
      port map (
        O     => refclk_74m25,
        ODIV2 => refclk_74m25_int,
        CEB   => '0',
        I     => refclk1_p_i,
        IB    => refclk1_n_i);

  inst_buf_gt : BUFG_GT
      port map (
        O => clk_74m25,
        CE => '1',
        CEMASK => '0',
        CLR => '0',
        CLRMASK => '0',
        DIV => "000",
        I => refclk_74m25_int);
 
  --  VCO: 800-1600Mhz
  --  input: 74.25 * 20 = 1485Mhz
  --         74.25 * 16 = 1188Mhz  / 19 => 62.52
  inst_mmcm: mmcme4_base
    generic map (
      BANDWIDTH => "OPTIMIZED",  -- Jitter programming
      CLKFBOUT_MULT_F => 16.0,   -- Multiply value for all CLKOUT
      CLKFBOUT_PHASE => 0.0,     -- Phase offset in degrees of CLKFB
      CLKIN1_PERIOD => 13.468,    -- Input clock period in ns to ps resolution (i.e., 33.333 is 30 MHz).
      CLKOUT0_DIVIDE_F => 19.0,  -- Divide amount for CLKOUT0
      CLKOUT0_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT0
      CLKOUT0_PHASE => 0.0,     -- Phase offset for CLKOUT0
      CLKOUT1_DIVIDE => 1,  -- Divide amount for CLKOUT (1-128)
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
      CLKOUT1 => open,   -- 1-bit output: CLKOUT1
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
      CLKIN1 => clk_74m25, -- 1-bit input: Primary clock
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

  process(clk_62m5)
  begin
    if rising_edge(clk_62m5) then
      if rst_n = '0' then
        led1_o <= '0';
        led2_o <= '1';
        count <= 0;
      else
        if count = 31_250_000 - 1 then
          led1_o <= '1';
          led2_o <= '0';
          count <= count + 1;
        elsif count = 62_500_000 - 1 then
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
  inst_map: entity work.mpsoc_map
  port map (
    aclk => clk_62m5,
    areset_n => rst_n,
    awaddr => m_axi4_out.awaddr(13 downto 2),
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
    araddr => m_axi4_out.araddr(13 downto 2),
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
    status_i (gth_status'range) => gth_status,
    status_i (31 downto gth_status'left + 1) => (others => '0')
  );

  inst_wrcore : entity work.xwr_core
    generic map (
      g_board_name => "KR26",
      g_dpram_initf => "../../../../bin/wrpc/wrc_phy8.bram",
      g_dpram_size => 192 * 1024 / 4
    )
    port map (
      clk_sys_i => clk_62m5,
      rst_n_i => rst_n,

      clk_dmtd_i => clk_62m5,
      clk_ref_i => clk_62m5,

      sfp_det_i => '0',

      uart_rxd_i => uart_tx,
      uart_txd_o => uart_rx,

      slave_i => wb_wrpc_out,
      slave_o => wb_wrpc_in
    );
  -- uart_rx <= uart_tx;

  inst_gth: gtwizard_ultrascale_qpll_example_top
    port map (
      clk_gth_i => refclk_74m25,
      pad_rxn_i => pad_rxn_i,
      pad_rxp_i => pad_rxp_i,
      pad_txn_o => pad_txn_o,
      pad_txp_o => pad_txp_o,
      hb_gtwiz_reset_clk_freerun_in => clk_62m5,
      hb_gtwiz_reset_all_in => rst,
      link_down_latched_reset_in => rst,
      serdes_ready_out => sfp_led1_o,
      reset_all_o => gth_status_a(0),
      userclk_tx_reset_o => gth_status_a(1),
      userclk_tx_active_o => gth_status_a(2),
      userclk_rx_reset_o => gth_status_a(3),
      userclk_rx_active_o => gth_status_a(4),
      buffbypass_tx_reset_o => gth_status_a(5),
      buffbypass_tx_done_o => gth_status_a(6),
      buffbypass_tx_error_o => gth_status_a(7),
      buffbypass_rx_reset_o => gth_status_a(8),
      buffbypass_rx_done_o => gth_status_a(9),
      buffbypass_rx_error_o => gth_status_a(10),
      reset_tx_pll_and_datapath_o => gth_status_a(11),
      reset_tx_datapath_o => gth_status_a(12),
      reset_rx_pll_and_datapath_o => gth_status_a(13),
      reset_rx_datapath_o => gth_status_a(14),
      reset_rx_cdr_stable_o => gth_status_a(15),
      reset_tx_done_o => gth_status_a(16),
      reset_rx_done_o => gth_status_a(17),
      rx_pma_reset_done_o => gth_status_a(18),
      tx_pma_reset_done_o => gth_status_a(19),
      tx_prgdiv_reset_done_o => gth_status_a(20),
      gt_powergood_o => gth_status_a(21)
    );

  gen_sync: for i in gth_status'range generate
    inst_sync: entity work.gc_sync
    port map (
      clk_i => clk_62m5,
      rst_n_a_i => rst_n,
      d_i => gth_status_a(i),
      q_o => gth_status(i)
    );
  end generate;
end top;
