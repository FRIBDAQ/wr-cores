-------------------------------------------------------------------------------
-- Title      : WRPC reference design for CTS board
-- Orig. Title: WRPC reference design for KR260 board
-- Project    : WR PTP Core
-- URL        : http://www.github.com/FRIBDAQ/wr-cores.git
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

entity cts_top is
  port (
    GTH_REFCLK1_n : in std_logic;
    GTH_REFCLK1_p : in std_logic;

    GTH_SFP_TX0_n : out std_logic;
    GTH_SFP_TX0_p : out std_logic;
    GTH_SFP_RX0_n : in std_logic;
    GTH_SFP_RX0_p : in std_logic;

    LED_FPGA_DS0 : out std_logic;
    LED_FPGA_DS1 : out std_logic;

    SFP_TX_FAULT0 : in std_logic;
    SFP_DISABLE0 : out std_logic;
    SFP_MOD_ABS0 : in std_logic;
    P2_HDIO3_SDA : inout std_logic;
    P2_HDIO4_SCL : inout std_logic;

    EEPROM_CSN0 : out std_logic;
    EEPROM_CSN1 : out std_logic;
    EEPROM_SCK0 : out std_logic;
    EEPROM_SI0  : out std_logic;
    EEPROM_SO0  : in  std_logic;

--    P2_HDIO1_SDA : inout std_logic;
--    P2_HDIO2_SCL : inout std_logic;

    LEMO_HP_OUT_n : out std_logic_vector(3 downto 0);
    LEMO_HP_OUT_p : out std_logic_vector(3 downto 0)
  );
end;

architecture top of cts_top is
  --  In sources, select the mpsoc.bd file and right-click to view instantiation template
  component mpsoc is
  port (
    M_AXI_awaddr : out STD_LOGIC_VECTOR ( 39 downto 0 );
    M_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_awvalid : out STD_LOGIC;
    M_AXI_awready : in STD_LOGIC;
    M_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M_AXI_wvalid : out STD_LOGIC;
    M_AXI_wready : in STD_LOGIC;
    M_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_bvalid : in STD_LOGIC;
    M_AXI_bready : out STD_LOGIC;
    M_AXI_araddr : out STD_LOGIC_VECTOR ( 39 downto 0 );
    M_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M_AXI_arvalid : out STD_LOGIC;
    M_AXI_arready : in STD_LOGIC;
    M_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M_AXI_rvalid : in STD_LOGIC;
    M_AXI_rready : out STD_LOGIC;
    UART_0_0_txd : out STD_LOGIC;
    UART_0_0_rxd : in STD_LOGIC;
    rst_axi_n : in STD_LOGIC;
    clk_axi : in STD_LOGIC;
    irq : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  end component mpsoc;

  signal rst_n, rst : std_logic := '0';
  signal rst_cnt : natural range 0 to 15 := 0;

  signal clk_62m5 : std_logic;
  signal clk_fb, pll_locked : std_logic;
  signal clk_ref : std_logic;

  signal m_axi4_out : t_axi4_lite_master_out_32;
  signal m_axi4_in : t_axi4_lite_master_in_32;
  signal m_axi_araddr, m_axi_awaddr : std_logic_vector(39 downto 32);

  signal uart_rx, uart_tx : std_logic;
  signal nimo : std_logic_vector(3 downto 0);
  signal led_link_o : std_logic;
  signal led_act_o : std_logic;

  signal wb_wrpc_host_in,  wb_wrpc_dev_in,  wb_wrpc_aux_in: t_wishbone_master_in;
  signal wb_wrpc_host_out, wb_wrpc_dev_out, wb_wrpc_aux_out: t_wishbone_master_out;
  signal irq : std_logic;

  signal abscal_tx, abscal_rx : std_logic;


  signal refclk1_int, refclk1 : std_logic;

  -- SPI-EEPROM pin nets (driven by the PL spi_master).
  signal ee_sck, ee_csn0, ee_csn1, ee_si, ee_so : std_logic;
  -- PL SPI master register interface (mpsoc_map @ 0x2000)
  signal spi_cs_reg, spi_tx_reg, spi_rx_reg : std_logic_vector(31 downto 0);
  signal spi_tx_wr, spi_busy, spi_done : std_logic;
  signal spi_rx_data : std_logic_vector(7 downto 0);
begin
  -- PL SPI master for the two 25AA02E48 EEPROMs, driven by the R5 through
  -- mpsoc_map registers SPI_CS/SPI_TX/SPI_RX (@ 0x2000).  Replaces the WR-core
  -- SYSCON bit-bang; CS is register-held across the bytes of a transaction and
  -- the master shifts one byte per SPI_TX write.
  inst_spi_master : entity work.spi_master
    generic map (
      g_CLK_DIV => 8           -- 62.5 MHz / (2*8) = 3.9 MHz SCK (< 5 MHz max)
    )
    port map (
      clk_i   => clk_62m5,
      rst_i   => rst,          -- active high (rst = not rst_n)
      start_i => spi_tx_wr,
      tx_i    => spi_tx_reg(7 downto 0),
      rx_o    => spi_rx_data,
      busy_o  => spi_busy,
      done_o  => spi_done,
      sck_o   => ee_sck,
      mosi_o  => ee_si,
      miso_i  => ee_so
    );

  ee_csn0 <= spi_cs_reg(0);
  ee_csn1 <= spi_cs_reg(1);
  spi_rx_reg(7 downto 0)  <= spi_rx_data;
  spi_rx_reg(8)           <= spi_busy;
  spi_rx_reg(31 downto 9) <= (others => '0');

  -- SPI master drives the physical EEPROM pins.
  EEPROM_SCK0 <= ee_sck;
  EEPROM_CSN0 <= ee_csn0;
  EEPROM_CSN1 <= ee_csn1;
  EEPROM_SI0  <= ee_si;
  ee_so       <= EEPROM_SO0;

  inst_wrc_board: entity work.xwrc_board_gthe4_rxpi
    generic map (
      g_refclk0_freq => 155_038_760,
      g_board_name => "CTS ",
      g_dpram_initf => "",
      g_dpram_size => (128+64) * 1024 / 4
    )
    port map (
      refclk0_n_i => GTH_REFCLK1_n,
      refclk0_p_i => GTH_REFCLK1_p,
      refclk0_int_o => refclk1_int,
      refclk0_gt_o => open,
      clk_62m5_i => clk_62m5,
      clk_ref_o => clk_ref,
      rst_n_i => rst_n,
      pad_txn_o => GTH_SFP_TX0_n,
      pad_txp_o => GTH_SFP_TX0_p,
      pad_rxn_i => GTH_SFP_RX0_n,
      pad_rxp_i => GTH_SFP_RX0_p,
      led_act_o => led_act_o,
      led_link_o => led_link_o,
      sfp_tx_fault_i => SFP_TX_FAULT0,
      sfp_tx_disable_o => SFP_DISABLE0,
      sfp_mod_abs_i => SFP_MOD_ABS0,
      sfp_sda_b => P2_HDIO3_SDA,
      sfp_scl_b => P2_HDIO4_SCL,
      dac_dpll_data_o => open,
      dac_dpll_load_p1_o => open,
      wb_wrpc_host_i => wb_wrpc_host_out,
      wb_wrpc_host_o => wb_wrpc_host_in,
      wb_wrpc_dev_i => wb_wrpc_dev_out,
      wb_wrpc_dev_o => wb_wrpc_dev_in,
      wb_wrpc_aux_i => wb_wrpc_aux_out,
      wb_wrpc_aux_o => wb_wrpc_aux_in,
      irq_o => irq,
      wrf_snk_i => open,
      wrf_snk_o => open,
      wrf_src_i => open,
      wrf_src_o => open,
      abscal_txts_o => abscal_tx,
      abscal_rxts_o => abscal_rx,
      -- WR-core SYSCON bit-bang SPI no longer used (PL spi_master drives the
      -- EEPROM now); leave its pins unconnected.
      spi_sclk_o => open,
      spi_ncs_o => open,
      spi_cs2_o => open,
      spi_mosi_o => open,
      spi_miso_i => '1',
      eeprom_scl_b => open,
      eeprom_sda_b => open,
      uart_rxd_i => uart_rx,
      uart_txd_o => uart_tx,
      tm_link_up_o => open,
      tm_time_valid_o => open,
      tm_tai_o => open,
      tm_cycles_o => open,
      pps_valid_o => open,
      pps_p_o => nimo(0),
      pps_led_o => open
    );

  inst_buf_gt : BUFG_GT
    port map (
      O => refclk1,
      CE => '1',
      CEMASK => '0',
      CLR => '0',
      CLRMASK => '0',
      DIV => "000",
      I => refclk1_int);


  --  VCO: 800-1600Mhz
  --  input: 156.25 * 8 = 1250Mhz / 20 => 62.50
  --  input: 74.25 * 20 = 1485Mhz
  --         74.25 * 16 = 1188Mhz  / 19 => 62.52
  inst_mmcm_62m5: mmcme4_base
    generic map (
      BANDWIDTH => "OPTIMIZED",  -- Jitter programming
      CLKFBOUT_MULT_F => 16.125, -- refclk 155.038760MHz / DIVCLK 2 * 16.125 = 1250MHz VCO (unchanged)
      CLKFBOUT_PHASE => 0.0,     -- Phase offset in degrees of CLKFB
      CLKIN1_PERIOD => 6.45,    -- Input clock period in ns (155.038760 MHz).
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
      DIVCLK_DIVIDE => 2,   -- Master division value (2 with MULT 16.125 keeps VCO=1250MHz => clk_62m5=62.5MHz exact)
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
      CLKIN1 => refclk1, -- 1-bit input: Primary clock
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
      irq(0) => irq,
      clk_axi => clk_62m5
    );

  inst_mpsoc_map: entity work.mpsoc_map
  port map (
    aclk => clk_62m5,
    areset_n => rst_n,
    awaddr => m_axi4_out.awaddr(14 downto 2),
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
    araddr => m_axi4_out.araddr(14 downto 2),
    arvalid => m_axi4_out.arvalid,
    arready => m_axi4_in.arready,
    arprot => "000",
    rvalid => m_axi4_in.rvalid,
    rready => m_axi4_out.rready,
    rdata => m_axi4_in.rdata,
    rresp => m_axi4_in.rresp,

    wrpc_host_i => wb_wrpc_host_in,
    wrpc_host_o => wb_wrpc_host_out,

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
    nbr_byte_align_i => (others => '0'),

    spi_cs_o => spi_cs_reg,
    spi_tx_o => spi_tx_reg,
    spi_tx_wr_o => spi_tx_wr,
    spi_rx_i => spi_rx_reg,

    wrpc_device_i => wb_wrpc_dev_in,
    wrpc_device_o => wb_wrpc_dev_out,
    wrpc_aux_i => wb_wrpc_aux_in,
    wrpc_aux_o => wb_wrpc_aux_out
  );
 
  nimo(2) <= clk_ref;
--  nimo(3) <= '0';

  nimo_inst : for i in 0 to 3 generate
      nimo_sig_inst : OBUFDS
      port map (
        O => LEMO_HP_OUT_p(i),
        OB => LEMO_HP_OUT_n(i),
        I => nimo(i)
      );
  end generate;

  led1_inst : OBUF
  port map (
    O => LED_FPGA_DS0,
    I => led_link_o
  );

  led2_inst : OBUF
  port map (
    O => LED_FPGA_DS1,
    I => led_act_o
  );

end top;
