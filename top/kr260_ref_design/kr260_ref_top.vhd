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

  signal rst_n, rst : std_logic := '0';
  signal rst_cnt : natural range 0 to 15 := 0;

  signal clk_25m : std_logic;

  signal count : natural range 0 to 156_250_000 - 1;
  signal clk_62m5 : std_logic;
  signal clk_fb, pll_locked : std_logic;
  signal clk_ref : std_logic;

  signal m_axi4_out : t_axi4_lite_master_out_32;
  signal m_axi4_in : t_axi4_lite_master_in_32;
  signal m_axi_araddr, m_axi_awaddr : std_logic_vector(39 downto 32);

  signal uart_rx, uart_tx : std_logic;

  signal wb_wrpc_in: t_wishbone_master_in;
  signal wb_wrpc_out: t_wishbone_master_out;

  signal abscal_tx, abscal_rx : std_logic;

  signal spi_sclk, spi_cs_n, spi_mosi, spi_miso : std_logic;

  signal refclk0 : std_logic;
begin
  inst_wrc_board: entity work.xwrc_board_gthe4_rxpi
    generic map (
      g_refclk0_freq => 156_250_000
    )
    port map (
      refclk0_n_i => refclk0_n_i,
      refclk0_p_i => refclk0_p_i,
      refclk0_o => refclk0,
      clk_62m5_i => clk_62m5,
      clk_ref_o => clk_ref,
      rst_n_i => rst_n,
      pad_txn_o => pad_txn_o,
      pad_txp_o => pad_txp_o,
      pad_rxn_i => pad_rxn_i,
      pad_rxp_i => pad_rxp_i,
      led_act_o => sfp_led1_o,
      led_link_o => sfp_led2_o,
      sfp_tx_fault_i => sfp_tx_fault_i,
      sfp_tx_disable_o => sfp_tx_disable_o,
      sfp_mod_abs_i => sfp_mod_abs_i,
      sfp_sda_b => sfp_sda_b,
      sfp_scl_b => sfp_scl_b,
      wb_wrpc_i => wb_wrpc_out,
      wb_wrpc_o => wb_wrpc_in,
      abscal_txts_o => abscal_tx,
      abscal_rxts_o => abscal_rx,
      spi_sclk_o => spi_sclk,
      spi_ncs_o => spi_cs_n,
      spi_mosi_o => spi_mosi,
      spi_miso_i => spi_miso,
      uart_rxd_i => uart_rx,
      uart_txd_o => uart_tx
    );

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
      CLKIN1 => refclk0, -- 1-bit input: Primary clock
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
    ctrl_led2_o => open,
    ctrl_gth_rst_o => open,
    ctrl_gth_tx_rst_o => open,
    ctrl_gth_tx_pcs_rst_o => open,
    ctrl_gth_tx_pma_rst_o => open,
    ctrl_gth_rx_rst_o => open,
    ctrl_gth_rx_pcs_rst_o => open,
    ctrl_gth_rx_pma_rst_o => open,
    ctrl_gth_rx_buf_rst_o => open,
    status_i => (others => '0'),
    qpll0_sdm_o => open,
    qpll0_sdm_wr_o => open,
    qpll1_sdm_o => open,
    qpll1_sdm_wr_o => open,
    rxpi_count_i => (others => '0'),
    rxpi_tag_i => (others => '0'),
    rxpi_nsamp_o => open,
    rxpi_direct_i => (others => '0'),

    bitslide_slide_i => '0',
    bitslide_force_o => open,
    bitslide_slide_o => open,
    bitslide_wr_o => open,
    bitslide_value_i => (others => '0'),
    bitslide_value_o => open,

    nbr_comma_det_i => (others => '0'),
    nbr_byte_align_i => (others => '0')
  );
 
  inst_flash: entity work.wr_mac_flash
    port map (
      clk_i => clk_62m5,
      rst_n_i => rst_n,
      mac_addr_i => x"aa_01_02_03_04_05",
      mac_valid_i => '1',
      spi_sclk_i => spi_sclk,
      spi_cs_n_i => spi_cs_n,
      spi_mosi_i => spi_mosi,
      spi_miso_o => spi_miso
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
    pmod4_2_b <= clk_ref; --  The WR reference clock
    pmod4_4_b <= '0'; -- phy16_in.rx_clk; --  The recovered clock
    pmod4_6_b <= abscal_tx; -- '0'; -- clk_ps;
    pmod4_8_b <= abscal_rx;
  end block;

end top;
