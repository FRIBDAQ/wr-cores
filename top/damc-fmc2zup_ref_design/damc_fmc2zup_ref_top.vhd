-------------------------------------------------------------------------------
-- Copyright (c) 2020 Deutsches Elektronen-Synchrotron DESY
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

library unisim;
use unisim.vcomponents.all;

use work.wr_fabric_pkg.all;
use work.endpoint_pkg.t_txtsu_timestamp;
use work.wr_damc_fmc2zup_pkg.all;


entity damc_fmc2zup_ref_top is
  port (
    ---------------------------------------------------------------------------
    -- Clocks
    ---------------------------------------------------------------------------
    clk_20m_vcxo_i      : in  std_logic;
    clk_125m_pllref_p_i : in  std_logic;
    clk_125m_pllref_n_i : in  std_logic;
    clk_125m_gtp_n_i    : in  std_logic;
    clk_125m_gtp_p_i    : in  std_logic;

    -- Aux 200 MHz fixed clock
    clk_200_p           : in std_logic;
    clk_200_n           : in std_logic;

    ---------------------------------------------------------------------------
    -- Resets
    ---------------------------------------------------------------------------
    reset_mmc_n         : in std_logic;

    ---------------------------------------------------------------------------
    -- Shared SPI interface to DACs
    ---------------------------------------------------------------------------
    plldac_sclk_o       : out std_logic;
    plldac_din_o        : out std_logic;
    pll25dac_cs_n_o     : out std_logic;
    pll20dac_cs_n_o     : out std_logic;

    ---------------------------------------------------------------------------
    -- SFP I/O for transceiver and SFP management info
    ---------------------------------------------------------------------------
    sfp_txp_o           : out std_logic;
    sfp_txn_o           : out std_logic;
    sfp_rxp_i           : in  std_logic;
    sfp_rxn_i           : in  std_logic;

    ---------------------------------------------------------------------------
    -- I2C EEPROM
    ---------------------------------------------------------------------------
    eeprom_sda_io       : inout  std_logic;
    eeprom_scl_io       : inout  std_logic;

    ---------------------------------------------------------------------------
    -- FMC
    ---------------------------------------------------------------------------
    fmc2_la_p_io : inout std_logic_vector(33 downto 0);
    fmc2_la_n_io : inout std_logic_vector(33 downto 0);
    -- HA bank not used for this application

    ---------------------------------------------------------------------------
    -- Front Panel cable
    ---------------------------------------------------------------------------
    fplink_trig0_p      : out std_logic;
    fplink_trig0_n      : out std_logic;
    fplink_trig1_p      : out std_logic;
    fplink_trig1_n      : out std_logic;

    ---------------------------------------------------------------------------
    -- Front-panel LEDs
    ---------------------------------------------------------------------------
    led_fp              : out std_logic_vector(3 downto 0);
    led_fp_wr           : out std_logic_vector(1 downto 0)
  );
end entity;

architecture arch of damc_fmc2zup_ref_top is

  ---------------------------------------------------------------------------
  -- Clocks/resets
  ---------------------------------------------------------------------------

  -- 62.5MHz sys clock output
  signal clk_sys_62m5             : std_logic;
  -- 125MHz ref clock output
  signal clk_ref_125m             : std_logic;
  signal clk_125m_pci             : std_logic;
  -- active low reset outputs, synchronous to 62m5 and 125m clocks
  signal rst_sys_62m5_n           : std_logic;
  signal rst_ref_125m_n           : std_logic;

  signal clk_125m_gth_bufds       : std_logic;
  signal clk_125m_gth             : std_logic;

  signal reset_wr_n               : std_logic;

  ---------------------------------------------------------------------------
  -- I2C EEPROM
  ---------------------------------------------------------------------------
  signal eeprom_sda_i             : std_logic;
  signal eeprom_sda_o             : std_logic;
  signal eeprom_sda_t             : std_logic;
  signal eeprom_scl_i             : std_logic;
  signal eeprom_scl_o             : std_logic;
  signal eeprom_scl_t             : std_logic;

  ---------------------------------------------------------------------------
  -- UART
  ---------------------------------------------------------------------------
  signal uart_rxd                 : std_logic;
  signal uart_txd                 : std_logic;

  ---------------------------------------------------------------------------
  -- SFP connections
  ---------------------------------------------------------------------------
  alias sfp_scl_io : std_logic is fmc2_la_p_io(24);
  alias sfp_sda_io : std_logic is fmc2_la_n_io(24);
  alias sfp_det_i : std_logic is fmc2_la_n_io(6);
  alias sfp_tx_fault_i : std_logic is fmc2_la_n_io(2);
  alias sfp_los_i : std_logic is fmc2_la_n_io(4);
  alias sfp_tx_disable_o : std_logic is fmc2_la_n_io(8);
  alias sfp_rate_select_o : std_logic is fmc2_la_n_io(10);
  signal sfp_sda_i                : std_logic;
  signal sfp_sda_o                : std_logic;
  signal sfp_sda_t                : std_logic;
  signal sfp_scl_i                : std_logic;
  signal sfp_scl_o                : std_logic;
  signal sfp_scl_t                : std_logic;

  ---------------------------------------------------------------------------
  -- External WB interface
  ---------------------------------------------------------------------------
  -- signal aux_master_o             : t_wishbone_master_out;
  -- signal aux_master_i             : t_wishbone_master_in := cc_dummy_master_in;

  ------------------------------------------
  -- Axi Slave Bus Interface S00_AXI
  ------------------------------------------
  -- aclk provided by this IP, wire to master!
  signal s00_axi_aclk_o           : std_logic;
  signal s00_axi_aresetn          : std_logic;
  signal s00_axi_awaddr           : std_logic_vector(31 downto 0);
  signal s00_axi_awprot           : std_logic_vector(2 downto 0);
  signal s00_axi_awvalid          : std_logic;
  signal s00_axi_awready          : std_logic;
  signal s00_axi_wdata            : std_logic_vector(31 downto 0);
  signal s00_axi_wstrb            : std_logic_vector(3 downto 0);
  signal s00_axi_wvalid           : std_logic;
  signal s00_axi_wready           : std_logic;
  signal s00_axi_bresp            : std_logic_vector(1 downto 0);
  signal s00_axi_bvalid           : std_logic;
  signal s00_axi_bready           : std_logic;
  signal s00_axi_araddr           : std_logic_vector(31 downto 0);
  signal s00_axi_arprot           : std_logic_vector(2 downto 0);
  signal s00_axi_arvalid          : std_logic;
  signal s00_axi_arready          : std_logic;
  signal s00_axi_rdata            : std_logic_vector(31 downto 0);
  signal s00_axi_rresp            : std_logic_vector(1 downto 0);
  signal s00_axi_rvalid           : std_logic;
  signal s00_axi_rready           : std_logic;
  signal s00_axi_rlast            : std_logic := '0';
  signal axi_int_o                : std_logic;  -- axi interrupt signal

  ---------------------------------------------------------------------------
  -- WR fabric interface (when g_fabric_iface = "plainfbrc")
  ---------------------------------------------------------------------------
  signal wrf_src_o                : t_wrf_source_out;
  signal wrf_src_i                : t_wrf_source_in := c_dummy_src_in;
  signal wrf_snk_o                : t_wrf_sink_out;
  signal wrf_snk_i                : t_wrf_sink_in   := c_dummy_snk_in;

  ---------------------------------------------------------------------------
  -- WR streamers (when g_fabric_iface = "streamers")
  ---------------------------------------------------------------------------
  -- wrs_tx_data_i                   : std_logic_vector(g_tx_streamer_params.data_width-1 downto 0) := (others => '0');
  -- wrs_tx_valid_i                  : std_logic                                        := '0';
  -- wrs_tx_dreq_o                   : std_logic;
  -- wrs_tx_last_i                   : std_logic                                        := '1';
  -- wrs_tx_flush_i                  : std_logic                                        := '0';
  -- wrs_tx_cfg_i                    : t_tx_streamer_cfg                                := c_tx_streamer_cfg_default;
  -- wrs_rx_first_o                  : std_logic;
  -- wrs_rx_last_o                   : std_logic;
  -- wrs_rx_data_o                   : std_logic_vector(g_rx_streamer_params.data_width-1 downto 0);
  -- wrs_rx_valid_o                  : std_logic;
  -- wrs_rx_dreq_i                   : std_logic                                        := '0';
  -- wrs_rx_cfg_i                    : t_rx_streamer_cfg                                 := c_rx_streamer_cfg_default;

  ---------------------------------------------------------------------------
  -- Etherbone WB master interface (when g_fabric_iface = "etherbone")
  ---------------------------------------------------------------------------
  -- wb_eth_master_o : out t_wishbone_master_out;
  -- wb_eth_master_i : in  t_wishbone_master_in := cc_dummy_master_in;

  ---------------------------------------------------------------------------
  -- Generic diagnostics interface (access from WRPC via SNMP or uart console
  ---------------------------------------------------------------------------
  -- aux_diag_i : in  t_generic_word_array(g_diag_ro_size-1 downto 0) := (others => (others => '0'));
  -- aux_diag_o : out t_generic_word_array(g_diag_rw_size-1 downto 0);

  ---------------------------------------------------------------------------
  -- Aux clocks control
  ---------------------------------------------------------------------------
  -- tm_dac_value_o       : out std_logic_vector(23 downto 0);
  -- tm_dac_wr_o          : out std_logic_vector(g_aux_clks-1 downto 0);
  -- tm_clk_aux_lock_en_i : in  std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');
  -- tm_clk_aux_locked_o  : out std_logic_vector(g_aux_clks-1 downto 0);

  ---------------------------------------------------------------------------
  -- External Tx Timestamping I/F
  ---------------------------------------------------------------------------
  signal timestamps               : t_txtsu_timestamp;
  signal timestamps_ack           : std_logic := '1';

  -----------------------------------------
  -- Timestamp helper signals, used for Absolute Calibration
  -----------------------------------------
  signal abscal_txts_o            : std_logic;
  signal abscal_rxts_o            : std_logic;

  ---------------------------------------------------------------------------
  -- Pause Frame Control
  ---------------------------------------------------------------------------
  signal fc_tx_pause_req_i        : std_logic                     := '0';
  signal fc_tx_pause_delay_i      : std_logic_vector(15 downto 0) := x"0000";
  signal fc_tx_pause_ready_o      : std_logic;

  ---------------------------------------------------------------------------
  -- Timecode I/F
  ---------------------------------------------------------------------------
  signal tm_link_up_o             : std_logic;
  signal tm_time_valid_o          : std_logic;
  signal tm_tai_o                 : std_logic_vector(39 downto 0);
  signal tm_cycles_o              : std_logic_vector(27 downto 0);

  ---------------------------------------------------------------------------
  -- Buttons, LEDs and PPS output
  ---------------------------------------------------------------------------
  signal led_act_o                : std_logic;
  signal led_link_o               : std_logic;
  signal btn1_i                   : std_logic := '1';
  signal btn2_i                   : std_logic := '1';
  -- 1PPS output
  signal pps_p_o                  : std_logic;
  signal pps_led_o                : std_logic;
  -- Link ok indication
  signal link_ok_o                : std_logic;

  ---------------------------------------------------------------------------
  signal clk_200_bufds, clk_200 : std_logic;
  signal cntr_200 : unsigned(15 downto 0);
  signal cntr_125 : unsigned(7 downto 0);

  attribute MARK_DEBUG : string;
  attribute MARK_DEBUG of clk_200 : signal is "true";
  attribute MARK_DEBUG of cntr_200 : signal is "true";
  attribute MARK_DEBUG of cntr_125 : signal is "true";

begin

  -- DEBUG
  proc_cntr_200: process (clk_200)
  begin
    if rising_edge(clk_200) then
      cntr_200 <= cntr_200 + 1;
    end if;
  end process;

  proc_cntr_125: process (clk_125m_gth)
  begin
    if rising_edge(clk_125m_gth) then
      cntr_125 <= cntr_125 + 1;
    end if;
  end process;

  cmp_ibufds_clk_200 : IBUFDS
  port map (
    O => clk_200_bufds,
    I => clk_200_p,
    IB => clk_200_n
  );

  cmp_bufg_clk_200: BUFG
  port map (
    I => clk_200_bufds,
    O => clk_200
  );

  cmp_system: entity work.system_wrapper
  port map (
    M00_AXI_0_araddr(31 downto 0) => s00_axi_araddr,
    M00_AXI_0_araddr(39 downto 32) => open,
    M00_AXI_0_arprot => s00_axi_arprot,
    M00_AXI_0_arready => s00_axi_arready,
    M00_AXI_0_arvalid => s00_axi_arvalid,
    M00_AXI_0_awaddr(31 downto 0) => s00_axi_awaddr,
    M00_AXI_0_awaddr(39 downto 32) => open,
    M00_AXI_0_awprot => s00_axi_awprot,
    M00_AXI_0_awready => s00_axi_awready,
    M00_AXI_0_awvalid => s00_axi_awvalid,
    M00_AXI_0_bready => s00_axi_bready,
    M00_AXI_0_bresp => s00_axi_bresp,
    M00_AXI_0_bvalid => s00_axi_bvalid,
    M00_AXI_0_rdata => s00_axi_rdata,
    M00_AXI_0_rready => s00_axi_rready,
    M00_AXI_0_rresp => s00_axi_rresp,
    M00_AXI_0_rvalid => s00_axi_rvalid,
    M00_AXI_0_wdata => s00_axi_wdata,
    M00_AXI_0_wready => s00_axi_wready,
    M00_AXI_0_wstrb => s00_axi_wstrb,
    M00_AXI_0_wvalid => s00_axi_wvalid,
    UART_1_rxd => uart_txd,
    UART_1_txd => uart_rxd,
    clk_wr_axi => s00_axi_aclk_o,
    reset_wr_axi_n(0) => s00_axi_aresetn,
    reset_wr_n(0) => reset_wr_n
  );

   cmp_ibufds_gte4 : IBUFDS_GTE4
   generic map (
      REFCLK_EN_TX_PATH => '0',   -- Refer to Transceiver User Guide
      REFCLK_HROW_CK_SEL => "00", -- Refer to Transceiver User Guide
      REFCLK_ICNTL_RX => "00"     -- Refer to Transceiver User Guide
   )
   port map (
      O => open,         -- 1-bit output: Refer to Transceiver User Guide
      ODIV2 => clk_125m_gth_bufds, -- 1-bit output: Refer to Transceiver User Guide
      CEB => '0',     -- 1-bit input: Refer to Transceiver User Guide
      I => clk_125m_gtp_p_i,         -- 1-bit input: Refer to Transceiver User Guide
      IB => clk_125m_gtp_n_i        -- 1-bit input: Refer to Transceiver User Guide
   );

   cmp_bufg_gt : BUFG_GT
   port map (
      O => clk_125m_gth,             -- 1-bit output: Buffer
      CE => '1',           -- 1-bit input: Buffer enable
      CEMASK => '0',   -- 1-bit input: CE Mask
      CLR => '0',         -- 1-bit input: Asynchronous clear
      CLRMASK => '0', -- 1-bit input: CLR Mask
      DIV => "000",         -- 3-bit input: Dynamic divide Value
      I => clk_125m_gth_bufds              -- 1-bit input: Buffer
   );

  cmp_xwrc_board_damc_fmc2zup: xwrc_board_damc_fmc2zup
  generic map (
    -- g_dpram_initf => "../../../../bin/wrpc/wrc_phy16_direct_dmtd.bram"
    g_dpram_initf => "../../../../bin/wrpc/wrc_phy16.bram"
  )
  port map (
    ------------------------------------------------------------------------
    -- Clocks/resets
    ------------------------------------------------------------------------
    areset_n_i              => reset_wr_n,

    -- Clock inputs from the board
    clk_20m_vcxo_i          => clk_20m_vcxo_i,
    clk_125m_pllref_p_i     => clk_125m_pllref_p_i,
    clk_125m_pllref_n_i     => clk_125m_pllref_n_i,
    clk_125m_gtp_n_i        => '0',
    clk_125m_gtp_p_i        => '0',
    clk_125m_pci_i          => clk_125m_gth,
    -- 62.5MHz sys clock output
    clk_sys_62m5_o          => clk_sys_62m5,
    -- 125MHz ref clock output
    clk_ref_125m_o          => clk_ref_125m,
    -- active low reset outputs, synchronous to 62m5 and 125m clocks
    rst_sys_62m5_n_o        => rst_sys_62m5_n,
    rst_ref_125m_n_o        => rst_ref_125m_n,

    ------------------------------------------------------------------------
    -- Shared SPI interface to DACs
    ------------------------------------------------------------------------
    plldac_sclk_o           => plldac_sclk_o,
    plldac_din_o            => plldac_din_o,
    pll25dac_cs_n_o         => pll25dac_cs_n_o,
    pll20dac_cs_n_o         => pll20dac_cs_n_o,

    ---------------------------------------------------------------------------
    -- SFP I/O for transceiver and SFP management info
    ---------------------------------------------------------------------------
    sfp_txp_o               => sfp_txp_o,
    sfp_txn_o               => sfp_txn_o,
    sfp_rxp_i               => sfp_rxp_i,
    sfp_rxn_i               => sfp_rxn_i,
    sfp_det_i               => sfp_det_i,
    sfp_sda_i               => sfp_sda_i,
    sfp_sda_o               => sfp_sda_o,
    sfp_sda_t               => sfp_sda_t,
    sfp_scl_i               => sfp_scl_i,
    sfp_scl_o               => sfp_scl_o,
    sfp_scl_t               => sfp_scl_t,
    sfp_rate_select_o       => sfp_rate_select_o,
    sfp_tx_fault_i          => sfp_tx_fault_i,
    sfp_tx_disable_o        => sfp_tx_disable_o,
    sfp_los_i               => sfp_los_i,

    ---------------------------------------------------------------------------
    -- I2C EEPROM
    ---------------------------------------------------------------------------
    eeprom_sda_i            => eeprom_sda_i,
    eeprom_sda_o            => eeprom_sda_o,
    eeprom_sda_t            => eeprom_sda_t,
    eeprom_scl_i            => eeprom_scl_i,
    eeprom_scl_o            => eeprom_scl_o,
    eeprom_scl_t            => eeprom_scl_t,

    ---------------------------------------------------------------------------
    -- I2C EEPROM
    ---------------------------------------------------------------------------
    uart_rxd_i              => uart_rxd,
    uart_txd_o              => uart_txd,
    ---------------------------------------------------------------------------
    -- External Tx Timestamping I/F
    ---------------------------------------------------------------------------
    timestamps_o            => timestamps,
    timestamps_ack_i        => timestamps_ack,

    s00_axi_aclk_o          => s00_axi_aclk_o,
    s00_axi_aresetn         => s00_axi_aresetn,
    s00_axi_awaddr          => s00_axi_awaddr,
    s00_axi_awprot          => s00_axi_awprot,
    s00_axi_awvalid         => s00_axi_awvalid,
    s00_axi_awready         => s00_axi_awready,
    s00_axi_wdata           => s00_axi_wdata,
    s00_axi_wstrb           => s00_axi_wstrb,
    s00_axi_wvalid          => s00_axi_wvalid,
    s00_axi_wready          => s00_axi_wready,
    s00_axi_bresp           => s00_axi_bresp,
    s00_axi_bvalid          => s00_axi_bvalid,
    s00_axi_bready          => s00_axi_bready,
    s00_axi_araddr          => s00_axi_araddr,
    s00_axi_arprot          => s00_axi_arprot,
    s00_axi_arvalid         => s00_axi_arvalid,
    s00_axi_arready         => s00_axi_arready,
    s00_axi_rdata           => s00_axi_rdata,
    s00_axi_rresp           => s00_axi_rresp,
    s00_axi_rvalid          => s00_axi_rvalid,
    s00_axi_rready          => s00_axi_rready,
    s00_axi_rlast           => s00_axi_rlast,
    axi_int_o               => open,

    ---------------------------------------------------------------------------
    -- Buttons, LEDs and PPS output
    ---------------------------------------------------------------------------
    led_act_o               => led_fp_wr(0),
    led_link_o              => led_fp_wr(1),
    pps_led_o               => led_fp(0),
    pps_p_o                 => pps_p_o,
    link_ok_o               => led_fp(1)
  );

  eeprom_sda_i <= eeprom_sda_io;
  eeprom_sda_io <= eeprom_sda_o when eeprom_sda_t = '0' else 'Z';
  eeprom_scl_i <= eeprom_scl_io;
  eeprom_scl_io <= eeprom_scl_o when eeprom_scl_t = '0' else 'Z';

  sfp_sda_i <= sfp_sda_io;
  sfp_sda_io <= sfp_sda_o when sfp_sda_t = '0' else 'Z';
  sfp_scl_i <= sfp_scl_io;
  sfp_scl_io <= sfp_scl_o when sfp_scl_t = '0' else 'Z';

  fplink_trig0_p <= pps_p_o;
  fplink_trig0_n <= '0';
  fplink_trig1_p <= '0';
  fplink_trig1_n <= '0';

end architecture;
