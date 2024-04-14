-------------------------------------------------------------------------------
-- Title      : WhiteRabbit PTP Core
-- Project    : WhiteRabbit
-------------------------------------------------------------------------------
-- File       : wr_core.vhd
-- Author     : Grzegorz Daniluk <grzegorz.daniluk@cern.ch>
-- Company    : CERN (BE-CO-HT)
-- Created    : 2011-02-02
-- Last update: 2019-02-01
-- Platform   : FPGA-generics
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- WR PTP Core is a HDL module implementing a complete gigabit Ethernet
-- interface (MAC + PCS + PHY) with integrated PTP slave ordinary clock
-- compatible with White Rabbit protocol. It performs subnanosecond clock
-- synchronization via WR protocol and also acts as an Ethernet "gateway",
-- providing access to TX/RX interfaces of the built-in WR MAC.
--
-- Starting from version 2.0 all modules are interconnected with pipelined
-- wishbone interface (using wb crossbars). Separate pipelined wishbone bus is
-- used for passing packets between Endpoint, Mini-NIC and External
-- MAC interface.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2012 - 2017 CERN
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
-- Memory map:
--  0x00000000: I/D Memory
--  0x00020000: Peripheral interconnect
--      +0x000: Minic
--      +0x100: Endpoint
--      +0x200: Softpll
--      +0x300: PPS gen
--      +0x400: Syscon
--      +0x500: UART
--      +0x600: OneWire
--      +0x700: Auxillary space (Etherbone config, etc)
--      +0x800: WRPC diagnostics registers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wrcore_pkg.all;
use work.gencores_pkg.all;
use work.genram_pkg.all;
use work.wishbone_pkg.all;
use work.etherbone_pkg.all;
use work.endpoint_pkg.all;
use work.wr_fabric_pkg.all;
use work.sysc_wbgen2_pkg.all;
use work.softpll_pkg.all;

entity wr_core is
  generic(
    --if set to 1, then blocks in PCS use smaller calibration counter to speed
    --up simulation
    g_simulation                : integer                        := 0;
    -- set to false to reduce the number of information printed during simulation
    g_verbose                   : boolean                        := true;
    g_with_external_clock_input : boolean                        := true;
    --
    g_board_name                : string                         := "NA  ";
    g_flash_secsz_kb            : integer                        := 256;        -- default for SVEC (M25P128)
    g_flash_sdbfs_baddr         : integer                        := 16#600000#; -- default for SVEC (M25P128)
    g_phys_uart                 : boolean                        := true;
    g_virtual_uart              : boolean                        := true;
    g_aux_clks                  : integer                        := 0;
    g_rx_buffer_size            : integer                        := 1024;
    g_tx_runt_padding           : boolean                        := true;
    g_dpram_initf               : string                         := "default";
    g_dpram_size                : integer                        := 131072/4;  --in 32-bit words
    g_interface_mode            : t_wishbone_interface_mode      := PIPELINED;
    g_address_granularity       : t_wishbone_address_granularity := BYTE;
    g_aux_sdb                   : t_sdb_device                   := c_wrc_periph3_sdb;
    g_aux1_sdb                  : t_sdb_device                   := c_wrc_periph3_sdb;
    g_etherbone_sdb             : t_sdb_device                   := c_etherbone_sdb;
    g_softpll_enable_debugger   : boolean                        := false;
    g_vuart_fifo_size           : integer                        := 1024;
    g_pcs_16bit                 : boolean                        := false;
    g_ref_clock_rate            : integer                        := 62500000;
    g_sys_clock_rate            : integer                        := 62500000;
    g_ref_clock_hz              : integer                        := 62500000;
    g_sys_clock_hz              : integer                        := 62500000;
    g_ext_clock_rate            : integer                        := 1000000;
    g_records_for_phy           : boolean                        := false;
    g_diag_id                   : integer                        := 0;
    g_diag_ver                  : integer                        := 0;
    g_diag_ro_size              : integer                        := 0;
    g_diag_rw_size              : integer                        := 0;
    g_num_phys                  : integer                        := 2;
    g_muxed_ports               : integer                        := 3;
    g_num_softpll_inputs        : integer                        := 2;
    g_with_10M_output           : boolean                        := true
);
  port(
    ---------------------------------------------------------------------------
    -- Clocks/resets
    ---------------------------------------------------------------------------

    -- system reference clock (any frequency <= f(clk_ref_i))
    clk_sys_i : in std_logic;

    -- DDMTD offset clock (125.x MHz)
    clk_dmtd_i : in std_logic;

    -- Timing reference (125 MHz)
    clk_ref_i : in std_logic;

    -- Aux clocks (i.e. the FMC clock), which can be disciplined by the WR Core
    clk_aux_i : in std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');

    clk_ext_mul_i : in std_logic := '0';
    clk_ext_mul_locked_i  : in  std_logic := '1';
    clk_ext_stopped_i     : in  std_logic := '0';
    clk_ext_rst_o         : out std_logic;

    -- External 10 MHz reference (cesium, GPSDO, etc.), used in Grandmaster mode
    clk_ext_i : in std_logic := '0';

    -- External PPS input (cesium, GPSDO, etc.), used in Grandmaster mode
    pps_ext_i : in std_logic := '0';
    ppsin_term_o : out std_logic;
    todin_term_o         : out std_logic;
    ext_tai_valid_p_i    : in std_logic := '0';
    ext_tai_i            : in std_logic_vector(39 downto 0) := (others => '0');
    ext_tai_ready_i      : in std_logic := '0';

    rst_n_i : in std_logic;

    -----------------------------------------
    --Timing system
    -----------------------------------------
    dac_hpll_load_p1_o : out std_logic;
    dac_hpll_data_o    : out std_logic_vector(15 downto 0);

    dac_dpll_load_p1_o : out std_logic;
    dac_dpll_data_o    : out std_logic_vector(15 downto 0);

    -- PHY I/f
    phy_ref_clk_i      : in std_logic:='0';

    phy_tx_data_o      : out std_logic_vector(f_pcs_data_width(g_pcs_16bit)-1 downto 0);
    phy_tx_k_o         : out std_logic_vector(f_pcs_k_width(g_pcs_16bit)-1 downto 0);
    phy_tx_disparity_i : in  std_logic:='0';
    phy_tx_enc_err_i   : in  std_logic:='0';

    phy_rx_data_i      : in std_logic_vector(f_pcs_data_width(g_pcs_16bit)-1 downto 0):=(others=>'0');
    phy_rx_rbclk_i     : in std_logic:='0';
    phy_rx_k_i         : in std_logic_vector(f_pcs_k_width(g_pcs_16bit)-1 downto 0):=(others=>'0');
    phy_rx_enc_err_i   : in std_logic:='0';
    phy_rx_bitslide_i  : in std_logic_vector(f_pcs_bts_width(g_pcs_16bit)-1 downto 0):=(others=>'0');

    phy_rst_o            : out std_logic;
    phy_rdy_i            : in  std_logic := '1';
    phy_loopen_o         : out std_logic;
    phy_loopen_vec_o     : out std_logic_vector(2 downto 0);
    phy_tx_prbs_sel_o    : out std_logic_vector(2 downto 0);
    phy_sfp_tx_fault_i   : in std_logic := '0';
    phy_sfp_los_i        : in std_logic := '0';
    phy_sfp_tx_disable_o : out std_logic;

    -- PHY I/F record-based
    phy8_o  : out t_phy_8bits_from_wrc_array(g_num_phys-1 downto 0);
    phy8_i  : in  t_phy_8bits_to_wrc_array(g_num_phys-1 downto 0):=(others=>c_dummy_phy8_to_wrc);
    phy16_o : out t_phy_16bits_from_wrc_array(g_num_phys-1 downto 0);
    phy16_i : in  t_phy_16bits_to_wrc_array(g_num_phys-1 downto 0):=(others=>c_dummy_phy16_to_wrc);

    -----------------------------------------
    --GPIO
    -----------------------------------------
    led_act_o  : out std_logic_vector(g_num_phys-1 downto 0);
    led_link_o : out std_logic_vector(g_num_phys-1 downto 0);
    scl_o      : out std_logic;
    scl_i      : in  std_logic := '1';
    sda_o      : out std_logic;
    sda_i      : in  std_logic := '1';
    sfp_scl_o  : out std_logic_vector(g_num_phys-1 downto 0);
    sfp_scl_i  : in  std_logic_vector(g_num_phys-1 downto 0):=(others=>'1');
    sfp_sda_o  : out std_logic_vector(g_num_phys-1 downto 0);
    sfp_sda_i  : in  std_logic_vector(g_num_phys-1 downto 0):=(others=>'1');
    sfp_det_i  : in  std_logic_vector(g_num_phys-1 downto 0):=(others=>'1');
    btn1_i     : in  std_logic := '1';
    btn2_i     : in  std_logic := '1';
    spi_sclk_o : out std_logic;
    spi_ncs_o  : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic := '0';

    -----------------------------------------
    --UART
    -----------------------------------------
    uart_rxd_i : in  std_logic := '1';
    uart_txd_o : out std_logic;

    -----------------------------------------
    -- 1-wire
    -----------------------------------------
    owr_pwren_o : out std_logic_vector(1 downto 0);
    owr_en_o    : out std_logic_vector(1 downto 0);
    owr_i       : in  std_logic_vector(1 downto 0) := (others => '1');

    -----------------------------------------
    -- MAIN PLL chip configuration
    -----------------------------------------
    pll_mosi_o    : out std_logic;
    pll_miso_i    : in  std_logic:='0';
    pll_sck_o     : out std_logic;
    pll_cs_n_o    : out std_logic;
    pll_sync_n_o  : out std_logic;
    pll_reset_n_o : out std_logic;
  
    -----------------------------------------
    -- EXT IN PLL chip configuration
    -----------------------------------------
    ext_pll_mosi_o    : out std_logic;
    ext_pll_miso_i    : in  std_logic:='0';
    ext_pll_sck_o     : out std_logic;
    ext_pll_cs_n_o    : out std_logic;
    ext_pll_sync_n_o  : out std_logic;
    ext_pll_reset_n_o : out std_logic;

    -----------------------------------------
    --External WB interface
    -----------------------------------------
    wb_adr_i   : in  std_logic_vector(c_wishbone_address_width-1 downto 0)   := (others => '0');
    wb_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0)      := (others => '0');
    wb_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);
    wb_sel_i   : in  std_logic_vector(c_wishbone_address_width/8-1 downto 0) := (others => '0');
    wb_we_i    : in  std_logic                                               := '0';
    wb_cyc_i   : in  std_logic                                               := '0';
    wb_stb_i   : in  std_logic                                               := '0';
    wb_ack_o   : out std_logic;
    wb_err_o   : out std_logic;
    wb_rty_o   : out std_logic;
    wb_stall_o : out std_logic;

    -----------------------------------------
    -- Auxillary WB master
    -----------------------------------------
    aux_adr_o   : out std_logic_vector(c_wishbone_address_width-1 downto 0);
    aux_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);
    aux_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0);
    aux_sel_o   : out std_logic_vector(c_wishbone_address_width/8-1 downto 0);
    aux_we_o    : out std_logic;
    aux_cyc_o   : out std_logic;
    aux_stb_o   : out std_logic;
    aux_ack_i   : in  std_logic := '1';
    aux_stall_i : in  std_logic := '0';

    -----------------------------------------
    -- Another Auxillary WB master (dds)
    -----------------------------------------
    aux1_adr_o   : out std_logic_vector(c_wishbone_address_width-1 downto 0);
    aux1_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);
    aux1_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0);
    aux1_sel_o   : out std_logic_vector(c_wishbone_address_width/8-1 downto 0);
    aux1_we_o    : out std_logic;
    aux1_cyc_o   : out std_logic;
    aux1_stb_o   : out std_logic;
    aux1_ack_i   : in  std_logic := '1';
    aux1_stall_i : in  std_logic := '0';

    -----------------------------------------
    -- Etherbone config master
    -----------------------------------------
    eb_cfg_adr_o   : out std_logic_vector(c_wishbone_address_width-1 downto 0);
    eb_cfg_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);
    eb_cfg_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0);
    eb_cfg_sel_o   : out std_logic_vector(c_wishbone_address_width/8-1 downto 0);
    eb_cfg_we_o    : out std_logic;
    eb_cfg_cyc_o   : out std_logic;
    eb_cfg_stb_o   : out std_logic;
    eb_cfg_ack_i   : in  std_logic := '1';
    eb_cfg_stall_i : in  std_logic := '0';

    -----------------------------------------
    -- Etherbone Fabric I/F
    -----------------------------------------
    eb_wrf_src_o : out t_wrf_source_out_array(g_num_phys-1 downto 0);
    eb_wrf_src_i : in  t_wrf_source_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_src_in);
    eb_wrf_snk_o : out t_wrf_sink_out_array(g_num_phys-1 downto 0);
    eb_wrf_snk_i : in  t_wrf_sink_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_snk_in);

    -----------------------------------------
    -- External Fabric I/F
    -----------------------------------------
    wrf_src_o : out t_wrf_source_out_array(g_num_phys-1 downto 0);
    wrf_src_i : in  t_wrf_source_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_src_in);
    wrf_snk_o : out t_wrf_sink_out_array(g_num_phys-1 downto 0);
    wrf_snk_i : in  t_wrf_sink_in_array(g_num_phys-1 downto 0):=(others=>c_dummy_snk_in);

    ------------------------------------------
    -- External TX Timestamp I/F
    ------------------------------------------
    timestamps_o         : out t_txtsu_timestamp_array(g_num_phys-1 downto 0);
    txtsu_ack_i          : in  std_logic_vector(g_num_phys-1 downto 0):=(others=>'1');

    -----------------------------------------
    -- Timestamp helper signals, used for Absolute Calibration
    -----------------------------------------
    abscal_txts_o        : out std_logic_vector(g_num_phys-1 downto 0);
    abscal_rxts_o        : out std_logic_vector(g_num_phys-1 downto 0);

    -----------------------------------------
    -- Pause Frame Control
    -----------------------------------------
    fc_tx_pause_req_i   : in  std_logic_vector(g_num_phys-1 downto 0):=(others=>'0');
    fc_tx_pause_delay_i : in  std_logic_vector(16*g_num_phys-1 downto 0):=(others=>'0');
    fc_tx_pause_ready_o : out std_logic_vector(g_num_phys-1 downto 0);

    -----------------------------------------
    -- Timecode/Servo Control
    -----------------------------------------

    tm_link_up_o         : out std_logic_vector(g_num_phys-1 downto 0);
    -- DAC Control
    tm_dac_value_o       : out std_logic_vector(23 downto 0);
    tm_dac_wr_o          : out std_logic_vector(g_aux_clks-1 downto 0);
    -- Aux clock lock enable
    tm_clk_aux_lock_en_i : in  std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');
    -- Aux clock locked flag
    tm_clk_aux_locked_o  : out std_logic_vector(g_aux_clks-1 downto 0);
    -- Timecode output
    tm_time_valid_o      : out std_logic;
    tm_tai_o             : out std_logic_vector(39 downto 0);
    tm_cycles_o          : out std_logic_vector(27 downto 0);
    -- 1PPS output
    pps_csync_o          : out std_logic;
    pps_valid_o          : out std_logic;
    pps_unmask_o         : out std_logic;
    pps_p_o              : out std_logic;
    pps_led_o            : out std_logic;
    -- clk output
    sync_clk_10m_o_p        : out std_logic;
    sync_clk_10m_o_n        : out std_logic;

    rst_aux_n_o : out std_logic;

    link_ok_o : out std_logic_vector(g_num_phys-1 downto 0);

    -------------------------------------
    -- DIAG to/from external modules
    -------------------------------------
    aux_diag_i : in  t_generic_word_array(g_diag_ro_size-1 downto 0) := (others=>(others=>'0'));
    aux_diag_o : out t_generic_word_array(g_diag_rw_size-1 downto 0)
    );
end wr_core;

architecture struct of wr_core is

  function f_choose_lm32_firmware_file return string is
  begin
    if(g_dpram_initf = "default") then
      if(g_simulation /= 0) then
        if g_verbose then
          report "[WR Core] Using simulation LM32 firmware." severity note;
        end if;
        return "wrc-simulation.ram";
      else
        if g_verbose then
          report "[WR Core] Using release LM32 firmware." severity note;
        end if;
        return "wrc-release.ram";
      end if;
    else
      if g_verbose then
        report "[WR Core] Using user-provided LM32 firmware." severity note;
      end if;
      return g_dpram_initf;
    end if;
  end function;

  function f_check_if_lm32_firmware_necessary return boolean is
  begin
    if(g_dpram_initf /= "") then
      return true;
    else
      return false;
    end if;
  end function;

  function f_num_ext_clks return integer is
  begin
    if g_with_external_clock_input then
      return 1;
    else
      return 0;
    end if;
  end function;

  -----------------------------------------------------------------------------
  --Local resets for peripheral
  -----------------------------------------------------------------------------
  signal rst_wrc_n : std_logic;
  signal rst_net_n : std_logic;

  -----------------------------------------------------------------------------
  --Local resets (resynced)
  -----------------------------------------------------------------------------
  signal rst_net_resync_ref_n   : std_logic;
  signal rst_net_resync_ext_n   : std_logic;
  signal rst_net_resync_dmtd_n  : std_logic;
  signal rst_net_resync_rxclk_n : std_logic_vector(g_num_phys-1 downto 0);
  signal rst_net_resync_txclk_n : std_logic_vector(g_num_phys-1 downto 0);

  -----------------------------------------------------------------------------
  --PPS generator
  -----------------------------------------------------------------------------
  signal s_pps_csync : std_logic;
  signal pps_valid   : std_logic;
  signal ppsg_link_ok: std_logic;

  signal ppsg_wb_in  : t_wishbone_slave_in;
  signal ppsg_wb_out : t_wishbone_slave_out;

  -----------------------------------------------------------------------------
  --Timing system
  -----------------------------------------------------------------------------
  signal phy_rx_clk  : std_logic_vector(g_num_phys-1 downto 0);
  signal phy_tx_clk  : std_logic_vector(g_num_phys-1 downto 0);
  signal clk_ref     : std_logic_vector(2*g_num_phys-1 downto 0);
  signal spll_wb_in  : t_wishbone_slave_in;
  signal spll_wb_out : t_wishbone_slave_out;

  -----------------------------------------------------------------------------
  --Endpoint x g_num_phys
  -----------------------------------------------------------------------------
  signal ep_txtsu_port_id           : std_logic_vector(5*g_num_phys-1 downto 0);
  signal ep_txtsu_frame_id          : std_logic_vector(16*g_num_phys-1 downto 0);
  signal ep_txtsu_ts_value          : std_logic_vector(32*g_num_phys-1 downto 0);
  signal ep_txtsu_ts_incorrect      : std_logic_vector(g_num_phys-1 downto 0);
  signal ep_txtsu_stb, ep_txtsu_ack : std_logic_vector(g_num_phys-1 downto 0);
  signal ep_led_link                : std_logic_vector(g_num_phys-1 downto 0);

  signal phy_rst : std_logic_vector(g_num_phys-1 downto 0);

  constant c_mnic_memsize_log2 : integer := f_log2_size(g_dpram_size);

  -----------------------------------------------------------------------------
  --Mini-NIC
  -----------------------------------------------------------------------------
  signal mnic_mem_data_o : std_logic_vector(32*g_num_phys-1 downto 0);
  signal mnic_mem_addr_o : std_logic_vector(c_mnic_memsize_log2*g_num_phys-1 downto 0);
  signal mnic_mem_wr_o   : std_logic_vector(g_num_phys-1 downto 0);
  signal mnic_txtsu_ack  : std_logic_vector(g_num_phys-1 downto 0);
  signal mnic_txtsu_stb  : std_logic_vector(g_num_phys-1 downto 0);

  -----------------------------------------------------------------------------
  --Dual-port RAM
  -----------------------------------------------------------------------------
  signal dpram_wbb_i : t_wishbone_slave_in;

  -----------------------------------------------------------------------------
  --WB Peripherials
  -----------------------------------------------------------------------------
  signal periph_slave_i : t_wishbone_slave_in_array(0 to 3);
  signal periph_slave_o : t_wishbone_slave_out_array(0 to 3);
  signal sysc_in_regs   : t_sysc_in_registers;
  signal sysc_out_regs  : t_sysc_out_registers;

  -----------------------------------------------------------------------------
  --WB Secondary Crossbar
  -----------------------------------------------------------------------------
  constant c_secbar_slaves : integer := 15;
  constant c_secbar_layout : t_sdb_record_array(c_secbar_slaves-1 downto 0) :=
    (0 => f_sdb_embed_device(c_xwr_mini_nic_sdb, x"00000000"),
     1 => f_sdb_embed_device(c_xwr_endpoint_sdb, x"00000100"),
     2 => f_sdb_embed_device(c_xwr_softpll_ng_sdb, x"00000200"),
     3 => f_sdb_embed_device(c_xwr_pps_gen_sdb, x"00000300"),
     4 => f_sdb_embed_device(c_wrc_periph0_sdb, x"00000400"),  -- Syscon
     5 => f_sdb_embed_device(c_wrc_periph1_sdb, x"00000500"),  -- UART
     6 => f_sdb_embed_device(c_wrc_periph2_sdb, x"00000600"),  -- 1-Wire
     7 => f_sdb_embed_device(g_aux_sdb,         x"00000700"),  -- aux WB bus
     8 => f_sdb_embed_device(c_wrc_periph4_sdb, x"00000800"),  -- WRPC diag registers
     9 => f_sdb_embed_device(c_xwb_spi_sdb,      x"00000900"), -- SPI for ext in PLL chip
     10=> f_sdb_embed_device(c_xwr_gen_10mhz,    x"00000a00"), -- Generate 10MHz output
     11=> f_sdb_embed_device(c_xwr_mini_nic_sdb, x"00000b00"), -- GT1 MINI-NIC. Added.
     12=> f_sdb_embed_device(c_xwr_endpoint_sdb, x"00000c00"), -- GT1 ENDPOINT Added.
     13=> f_sdb_embed_device(g_aux1_sdb, x"00000d00"),         -- Another aux WB bus
     14=> f_sdb_embed_device(g_etherbone_sdb, x"00000e00")   -- etherbone
     );

  constant c_secbar_sdb_address : t_wishbone_address := x"00001000";
  constant c_secbar_bridge_sdb  : t_sdb_bridge       :=
    f_xwb_bridge_layout_sdb(true, c_secbar_layout, c_secbar_sdb_address);

  signal secbar_master_i : t_wishbone_master_in_array(c_secbar_slaves-1 downto 0);
  signal secbar_master_o : t_wishbone_master_out_array(c_secbar_slaves-1 downto 0);

  -----------------------------------------------------------------------------
  --WB intercon
  -----------------------------------------------------------------------------
  constant c_layout : t_sdb_record_array(1 downto 0) :=
    (0 => f_sdb_embed_device(f_xwb_dpram(g_dpram_size), x"00000000"),
     1 => f_sdb_embed_bridge(c_secbar_bridge_sdb, x"00020000"));
  constant c_sdb_address : t_wishbone_address := x"00030000";

  signal cbar_slave_i  : t_wishbone_slave_in_array (2 downto 0);
  signal cbar_slave_o  : t_wishbone_slave_out_array(2 downto 0);
  signal cbar_master_i : t_wishbone_master_in_array(1 downto 0);
  signal cbar_master_o : t_wishbone_master_out_array(1 downto 0);

  -----------------------------------------------------------------------------
  --External WB interface
  -----------------------------------------------------------------------------
  signal ext_wb_in  : t_wishbone_slave_in;
  signal ext_wb_out : t_wishbone_slave_out;

  -----------------------------------------------------------------------------
  -- External Tx TSU interface
  -----------------------------------------------------------------------------

  --===========================--
  --         For SPEC          --
  --===========================--

  signal hpll_auxout  : std_logic_vector(2 downto 0);
  signal dmpll_auxout : std_logic_vector(2 downto 0);

  signal clk_ref_slv : std_logic_vector(0 downto 0);
  signal clk_rx_slv  : std_logic_vector(0 downto 0);

  signal s_dummy_addr : std_logic_vector(31 downto 0);

  signal softpll_irq : std_logic;

  signal lm32_irq_slv : std_logic_vector(31 downto 0);

  signal ep_wb_in  : t_wishbone_slave_in_array(g_num_phys-1 downto 0);
  signal ep_wb_out : t_wishbone_slave_out_array(g_num_phys-1 downto 0);

  signal minic_wb_in  : t_wishbone_slave_in_array(g_num_phys-1 downto 0);
  signal minic_wb_out : t_wishbone_slave_out_array(g_num_phys-1 downto 0);

  signal ep_src_out : t_wrf_source_out_array(g_num_phys-1 downto 0);
  signal ep_src_in  : t_wrf_source_in_array(g_num_phys-1 downto 0);
  signal ep_snk_out : t_wrf_sink_out_array(g_num_phys-1 downto 0);
  signal ep_snk_in  : t_wrf_sink_in_array(g_num_phys-1 downto 0);

  signal mux_src_out : t_wrf_source_out_array(g_muxed_ports*g_num_phys-1 downto 0);
  signal mux_src_in  : t_wrf_source_in_array(g_muxed_ports*g_num_phys-1 downto 0);
  signal mux_snk_out : t_wrf_sink_out_array(g_muxed_ports*g_num_phys-1 downto 0);
  signal mux_snk_in  : t_wrf_sink_in_array(g_muxed_ports*g_num_phys-1 downto 0);
  signal mux_class   : t_wrf_mux_class(g_muxed_ports-1 downto 0);

  signal spll_out_locked : std_logic_vector(g_aux_clks downto 0);

  signal dac_dpll_data    : std_logic_vector(15 downto 0);
  signal dac_dpll_sel     : std_logic_vector(3 downto 0);
  signal dac_dpll_load_p1 : std_logic;

  signal clk_fb     : std_logic_vector(g_aux_clks downto 0);
  signal out_enable : std_logic_vector(g_aux_clks downto 0);

  signal sfp_scl_out : std_logic_vector(3 downto 0);
  signal sfp_sda_out : std_logic_vector(3 downto 0);
  signal sfp_scl_in  : std_logic_vector(3 downto 0):=(others=>'0');
  signal sfp_sda_in  : std_logic_vector(3 downto 0):=(others=>'0');
  signal sfp_det_in  : std_logic_vector(3 downto 0):=(others=>'0');

begin

  -----------------------------------------------------------------------------
  -- PHY TX/RX clock selection based on generics
  -----------------------------------------------------------------------------

  GEN_16BIT_PHY_IF: if g_pcs_16bit and g_records_for_phy generate
    gen_clk: for i in 0 to g_num_phys-1 generate
      phy_rx_clk(i) <= phy16_i(i).rx_clk;
      phy_tx_clk(i) <= phy16_i(i).ref_clk;
    end generate;
  end generate;

  GEN_8BIT_PHY_IF: if not g_pcs_16bit and g_records_for_phy generate
    gen_clk: for i in 0 to g_num_phys-1 generate
      phy_rx_clk(i) <= phy8_i(i).rx_clk;
      phy_tx_clk(i) <= phy8_i(i).ref_clk;
    end generate;
  end generate;

  GEN_STD_PHY_IF: if not g_records_for_phy generate
    phy_rx_clk(0) <= phy_rx_rbclk_i;
    phy_tx_clk(0) <= phy_ref_clk_i;
  end generate;

  -----------------------------------------------------------------------------
  -- Reset resync and distribution
  -----------------------------------------------------------------------------

  rst_aux_n_o <= rst_net_n;

  U_Sync_reset_refclk : gc_sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_ref_i,
      rst_n_i  => '1',
      data_i   => rst_net_n,
      synced_o => rst_net_resync_ref_n);

  U_sync_reset_dmtd : gc_sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_dmtd_i,
      rst_n_i  => '1',
      data_i   => rst_net_n,
      synced_o => rst_net_resync_dmtd_n);

  U_sync_reset_ext : gc_sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_ext_i,
      rst_n_i  => '1',
      data_i   => rst_net_n,
      synced_o => rst_net_resync_ext_n);

  gen_sync_reset_rxclk :  for i in 0 to g_num_phys-1 generate

    U_sync_reset_rxclk : gc_sync_ffs
      generic map (
        g_sync_edge => "positive")
      port map (
        clk_i    => phy_rx_clk(i),
        rst_n_i  => '1',
        data_i   => rst_net_n,
        synced_o => rst_net_resync_rxclk_n(i));

    U_sync_reset_txclk : gc_sync_ffs
      generic map (
        g_sync_edge => "positive")
      port map (
        clk_i    => phy_tx_clk(i),
        rst_n_i  => '1',
        data_i   => rst_net_n,
        synced_o => rst_net_resync_txclk_n(i));

  end generate;

  -----------------------------------------------------------------------------
  -- PPS generator
  -----------------------------------------------------------------------------
  PPS_GEN : xwr_pps_gen
    generic map(
      g_interface_mode       => PIPELINED,
      g_address_granularity  => BYTE,
      g_ref_clock_rate       => g_ref_clock_rate,
      g_ext_clock_rate       => g_ext_clock_rate,
      g_with_ext_clock_input => g_with_external_clock_input)
    port map(
      clk_ref_i => clk_ref_i,
      clk_sys_i => clk_sys_i,

      rst_sys_n_i => rst_net_n,
      rst_ref_n_i => rst_net_resync_ref_n,

      slave_i => ppsg_wb_in,
      slave_o => ppsg_wb_out,

      -- used for fast masking of PPS output when link goes down
      --link_ok_i => ppsg_link_ok,
      -- keep PPS generation 
      link_ok_i => '1',

      -- Single-pulse PPS output for synchronizing endpoint to
      pps_in_i    => pps_ext_i,
      ppsin_term_o => ppsin_term_o,
      pps_csync_o => s_pps_csync,
      pps_valid_int_o => pps_valid,
      pps_out_o   => pps_p_o,
      pps_led_o   => pps_led_o,
      pps_valid_o  => pps_valid_o,
      pps_unmask_o => pps_unmask_o,

      todin_term_o       => todin_term_o,
      ext_tai_valid_p_i  => ext_tai_valid_p_i,
      ext_tai_i          => ext_tai_i,
      ext_tai_ready_i    => ext_tai_ready_i,

      tm_utc_o        => tm_tai_o,
      tm_cycles_o     => tm_cycles_o,
      tm_time_valid_o => tm_time_valid_o
      );
  ppsg_link_ok <= not phy_rst(0);
  pps_csync_o  <= s_pps_csync;


  -----------------------------------------------------------------------------
  -- Software PLL
  -----------------------------------------------------------------------------
  U_SOFTPLL : xwr_softpll_ng
    generic map(
      g_reverse_dmtds        => false,
      g_divide_input_by_2    => not g_pcs_16bit,
      g_with_debug_fifo      => g_softpll_enable_debugger,
      g_tag_bits             => 22,
      g_interface_mode       => PIPELINED,
      g_address_granularity  => BYTE,
      g_num_ref_inputs       => g_num_softpll_inputs,
      g_num_outputs          => 1 + g_aux_clks,
      g_num_exts             => f_num_ext_clks,
      g_ref_clock_rate       => g_ref_clock_rate,
      g_ext_clock_rate       => g_ext_clock_rate)
    port map(
      clk_sys_i    => clk_sys_i,
      rst_sys_n_i  => rst_net_n,
      rst_ref_n_i  => rst_net_resync_ref_n,
      rst_ext_n_i  => rst_net_resync_ext_n,
      rst_dmtd_n_i => rst_net_resync_dmtd_n,

      -- Reference inputs (i.e. the RX clocks recovered by the PHYs)
      clk_ref_i    => clk_ref(g_num_softpll_inputs-1 downto 0),
      -- Feedback clocks (i.e. the outputs of the main or aux oscillator)
      clk_fb_i     => clk_fb,
      -- DMTD Offset clock
      clk_dmtd_i   => clk_dmtd_i,

      clk_ext_i            => clk_ext_i,
      clk_ext_mul_i(0)     => clk_ext_mul_i,
      clk_ext_mul_locked_i => clk_ext_mul_locked_i,
      clk_ext_stopped_i    => clk_ext_stopped_i,
      clk_ext_rst_o        => clk_ext_rst_o,

      pps_csync_p1_i => s_pps_csync,
      pps_ext_a_i => pps_ext_i,

      -- DMTD oscillator drive
      dac_dmtd_data_o => dac_hpll_data_o,
      dac_dmtd_load_o => dac_hpll_load_p1_o,

      -- Output channel DAC value
      dac_out_data_o => dac_dpll_data,  --: out std_logic_vector(15 downto 0);
      -- Output channel select (0 = channel 0, etc. )
      dac_out_sel_o  => dac_dpll_sel,   --for now use only one output
      dac_out_load_o => dac_dpll_load_p1,

      out_enable_i => out_enable,

      out_locked_o => spll_out_locked,

      slave_i => spll_wb_in,
      slave_o => spll_wb_out,

      int_o => softpll_irq,

      debug_o => open);

  softpll_clk_ref: for i in 0 to g_num_phys-1 generate
    clk_ref(2*i+1 downto 2*i)     <= phy_tx_clk(i) & phy_rx_clk(i);
  end generate softpll_clk_ref;
  clk_fb(0)                       <= clk_ref_i;
  clk_fb(g_aux_clks downto 1)     <= clk_aux_i;
  out_enable(0)                   <= '1';
  out_enable(g_aux_clks downto 1) <= tm_clk_aux_lock_en_i;

  dac_dpll_data_o    <= dac_dpll_data;
  dac_dpll_load_p1_o <= '1' when (dac_dpll_load_p1 = '1' and dac_dpll_sel = x"0") else '0';

  tm_dac_value_o <= x"00" & dac_dpll_data;

  p_decode_dac_writes : process(dac_dpll_load_p1, dac_dpll_sel)
  begin
    for i in 0 to g_aux_clks-1 loop
      if dac_dpll_sel = std_logic_vector(to_unsigned(i+1, 4)) then
        tm_dac_wr_o(i) <= dac_dpll_load_p1;
      else
        tm_dac_wr_o(i) <= '0';
      end if;
    end loop;  -- i
  end process;

  locked_spll : if g_aux_clks > 0 generate
    tm_clk_aux_locked_o <= spll_out_locked(g_aux_clks downto 1);
  end generate;

  -----------------------------------------------------------------------------
  -- Endpoint
  -----------------------------------------------------------------------------
  U_GT0_Endpoint : xwr_endpoint
    generic map (
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE,
      g_simulation          => f_int2bool(g_simulation),
      g_tx_runt_padding     => g_tx_runt_padding,
      g_pcs_16bit           => g_pcs_16bit,
      g_ref_clock_rate      => g_ref_clock_rate,
      g_records_for_phy     => g_records_for_phy,
      g_rx_buffer_size      => g_rx_buffer_size,
      g_with_rx_buffer      => true,
      g_with_flow_control   => false,
      g_with_timestamper    => true,
      g_with_dpi_classifier => true,
      g_with_vlans          => false,
      g_with_rtu            => false,
      g_with_leds           => true,
      g_with_packet_injection => false,
      g_use_new_rxcrc       => true,
      g_use_new_txcrc       => false)
    port map (
      clk_ref_i             => clk_ref_i,
      clk_sys_i             => clk_sys_i,
      clk_dmtd_i            => clk_dmtd_i,
      rst_sys_n_i           => rst_net_n,
      rst_ref_n_i           => rst_net_resync_ref_n,
      rst_dmtd_n_i          => rst_net_resync_dmtd_n,
      rst_txclk_n_i         => rst_net_resync_txclk_n(0),
      rst_rxclk_n_i         => rst_net_resync_rxclk_n(0),
      pps_csync_p1_i        => s_pps_csync,
      pps_valid_i           => pps_valid,
      phy_rst_o             => phy_rst(0),
      phy8_o                => phy8_o(0),
      phy8_i                => phy8_i(0),
      phy16_o               => phy16_o(0),
      phy16_i               => phy16_i(0),
      src_o                 => ep_src_out(0),
      src_i                 => ep_src_in(0),
      snk_o                 => ep_snk_out(0),
      snk_i                 => ep_snk_in(0),
      txtsu_port_id_o       => ep_txtsu_port_id(5-1 downto 0),
      txtsu_frame_id_o      => ep_txtsu_frame_id(16-1 downto 0),
      txtsu_ts_value_o      => ep_txtsu_ts_value(32-1 downto 0),
      txtsu_ts_incorrect_o  => ep_txtsu_ts_incorrect(0),
      txtsu_stb_o           => ep_txtsu_stb(0),
      txtsu_ack_i           => ep_txtsu_ack(0),
      wb_i                  => ep_wb_in(0),
      wb_o                  => ep_wb_out(0),
      rmon_events_o         => open,
      txts_o                => abscal_txts_o(0),
      rxts_o                => abscal_rxts_o(0),
      fc_tx_pause_req_i     => fc_tx_pause_req_i(0),
      fc_tx_pause_delay_i   => fc_tx_pause_delay_i(16-1 downto 0),
      fc_tx_pause_ready_o   => fc_tx_pause_ready_o(0),
      led_link_o            => ep_led_link(0),
      led_act_o             => led_act_o(0)
    );

  led_link_o(0)   <= ep_led_link(0);
  link_ok_o(0)    <= ep_led_link(0);

  tm_link_up_o(0) <= ep_led_link(0);

  secbar_master_i(1) <= ep_wb_out(0);
  ep_wb_in(0)        <= secbar_master_o(1);
  
  gen_endpoint: for i in 1 to g_num_phys-1 generate

    U_Endpoint : xwr_endpoint
      generic map (
        g_interface_mode      => PIPELINED,
        g_address_granularity => BYTE,
        g_simulation          => f_int2bool(g_simulation),
        g_tx_runt_padding     => g_tx_runt_padding,
        g_pcs_16bit           => g_pcs_16bit,
        g_ref_clock_rate      => g_ref_clock_rate,
        g_records_for_phy     => g_records_for_phy,
        g_rx_buffer_size      => g_rx_buffer_size,
        g_with_rx_buffer      => true,
        g_with_flow_control   => false,
        g_with_timestamper    => true,
        g_with_dpi_classifier => true,
        g_with_vlans          => false,
        g_with_rtu            => false,
        g_with_leds           => true,
        g_with_packet_injection => false,
        g_use_new_rxcrc       => true,
        g_use_new_txcrc       => false)
      port map (
        clk_ref_i             => clk_ref_i,
        clk_sys_i             => clk_sys_i,
        clk_dmtd_i            => clk_dmtd_i,
        rst_sys_n_i           => rst_net_n,
        rst_ref_n_i           => rst_net_resync_ref_n,
        rst_dmtd_n_i          => rst_net_resync_dmtd_n,
        rst_txclk_n_i         => rst_net_resync_txclk_n(i),
        rst_rxclk_n_i         => rst_net_resync_rxclk_n(i),
        pps_csync_p1_i        => s_pps_csync,
        pps_valid_i           => pps_valid,
        phy_rst_o             => phy_rst(i),
        phy8_o                => phy8_o(i),
        phy8_i                => phy8_i(i),
        phy16_o               => phy16_o(i),
        phy16_i               => phy16_i(i),
        src_o                 => ep_src_out(i),
        src_i                 => ep_src_in(i),
        snk_o                 => ep_snk_out(i),
        snk_i                 => ep_snk_in(i),
        txtsu_port_id_o       => ep_txtsu_port_id((i+1)*5-1 downto i*5),
        txtsu_frame_id_o      => ep_txtsu_frame_id((i+1)*16-1 downto i*16),
        txtsu_ts_value_o      => ep_txtsu_ts_value((i+1)*32-1 downto i*32),
        txtsu_ts_incorrect_o  => ep_txtsu_ts_incorrect(i),
        txtsu_stb_o           => ep_txtsu_stb(i),
        txtsu_ack_i           => ep_txtsu_ack(i),
        wb_i                  => ep_wb_in(i),
        wb_o                  => ep_wb_out(i),
        rmon_events_o         => open,
        txts_o                => abscal_txts_o(i),
        rxts_o                => abscal_rxts_o(i),
        fc_tx_pause_req_i     => fc_tx_pause_req_i(i),
        fc_tx_pause_delay_i   => fc_tx_pause_delay_i((i+1)*16-1 downto i*16),
        fc_tx_pause_ready_o   => fc_tx_pause_ready_o(i),
        led_link_o            => ep_led_link(i),
        led_act_o             => led_act_o(i)
      );

    led_link_o(i)   <= ep_led_link(i);
    link_ok_o(i)    <= ep_led_link(i);

    tm_link_up_o(i) <= ep_led_link(i);

    secbar_master_i(10+2*i) <= ep_wb_out(i);
    ep_wb_in(i)        <= secbar_master_o(10+2*i);

  end generate gen_endpoint;

  phy_rst_o <= phy_rst(0);

  -----------------------------------------------------------------------------
  -- Mini-NIC
  -----------------------------------------------------------------------------
  U_GT0_MINI_NIC : xwr_mini_nic
    generic map (
      g_interface_mode       => PIPELINED,
      g_address_granularity  => BYTE,
      g_tx_fifo_size         => 1024,
      g_rx_fifo_size         => 2048,
      g_buffer_little_endian => false)
    port map (
      clk_sys_i => clk_sys_i,
      rst_n_i   => rst_net_n,

      src_o => mux_snk_in(0),
      src_i => mux_snk_out(0),
      snk_o => mux_src_in(0),
      snk_i => mux_src_out(0),

      txtsu_port_id_i     => ep_txtsu_port_id(5-1 downto 0),
      txtsu_frame_id_i    => ep_txtsu_frame_id(16-1 downto 0),
      txtsu_tsval_i       => ep_txtsu_ts_value(32-1 downto 0),
      txtsu_tsincorrect_i => ep_txtsu_ts_incorrect(0),
      txtsu_stb_i         => mnic_txtsu_stb(0),
      txtsu_ack_o         => mnic_txtsu_ack(0),

      wb_i => minic_wb_in(0),
      wb_o => minic_wb_out(0)
      );

  secbar_master_i(0) <= minic_wb_out(0);
  minic_wb_in(0)     <= secbar_master_o(0);

  GEN_MINI_NIC: for i in 1 to g_num_phys-1 generate
    
    MINI_NIC : xwr_mini_nic
      generic map (
        g_interface_mode       => PIPELINED,
        g_address_granularity  => BYTE,
        g_tx_fifo_size         => 1024,
        g_rx_fifo_size         => 2048,
        g_buffer_little_endian => false)
      port map (
        clk_sys_i => clk_sys_i,
        rst_n_i   => rst_net_n,

        src_o => mux_snk_in(g_muxed_ports*i),
        src_i => mux_snk_out(g_muxed_ports*i),
        snk_o => mux_src_in(g_muxed_ports*i),
        snk_i => mux_src_out(g_muxed_ports*i),

        txtsu_port_id_i     => ep_txtsu_port_id((i+1)*5-1 downto i*5),
        txtsu_frame_id_i    => ep_txtsu_frame_id((i+1)*16-1 downto i*16),
        txtsu_tsval_i       => ep_txtsu_ts_value((i+1)*32-1 downto i*32),
        txtsu_tsincorrect_i => ep_txtsu_ts_incorrect(i),
        txtsu_stb_i         => mnic_txtsu_stb(i),
        txtsu_ack_o         => mnic_txtsu_ack(i),

        wb_i => minic_wb_in(i),
        wb_o => minic_wb_out(i)
        );

    secbar_master_i(9+2*i) <= minic_wb_out(i);
    minic_wb_in(i)     <= secbar_master_o(9+2*i);

  end generate gen_mini_nic;

  lm32_irq_slv(31 downto 1) <= (others => '0');
  lm32_irq_slv(0)           <= softpll_irq;  -- according to the doc, it's active low.

  -----------------------------------------------------------------------------
  -- LM32
  -----------------------------------------------------------------------------
  LM32_CORE : xwb_lm32
    generic map(g_profile => "medium_icache")
    port map(
      clk_sys_i => clk_sys_i,
      rst_n_i   => rst_wrc_n,
      irq_i     => lm32_irq_slv,

      dwb_o => cbar_slave_i(0),
      dwb_i => cbar_slave_o(0),
      iwb_o => cbar_slave_i(1),
      iwb_i => cbar_slave_o(1)
      );

  -----------------------------------------------------------------------------
  -- Dual-port RAM
  -----------------------------------------------------------------------------
  DPRAM : xwb_dpram
    generic map(
      g_size                  => g_dpram_size,
      g_init_file             => f_choose_lm32_firmware_file,
      g_must_have_init_file   => f_check_if_lm32_firmware_necessary,
      g_slave1_interface_mode => PIPELINED,
      g_slave2_interface_mode => PIPELINED,
      g_slave1_granularity    => BYTE,
      g_slave2_granularity    => WORD)
    port map(
      clk_sys_i => clk_sys_i,
      rst_n_i   => rst_n_i,

      slave1_i => cbar_master_o(0),
      slave1_o => cbar_master_i(0),
      slave2_i => dpram_wbb_i,
      slave2_o => open
      );

  dpram_wbb_i.cyc <= '0';
  dpram_wbb_i.stb <= '0';
  dpram_wbb_i.adr <= (others=>'0');
  dpram_wbb_i.sel <= "1111";
  dpram_wbb_i.we  <= '0'; --mnic_mem_wr_o;
  dpram_wbb_i.dat <= (others=>'0'); --mnic_mem_data_o;

  -----------------------------------------------------------------------------
  -- WB Peripherials
  -----------------------------------------------------------------------------
  sfp_scl_o   <= sfp_scl_out(g_num_phys-1 downto 0);
  sfp_sda_o   <= sfp_sda_out(g_num_phys-1 downto 0);
  sfp_scl_in(g_num_phys-1 downto 0) <=  sfp_scl_i;
  sfp_sda_in(g_num_phys-1 downto 0) <=  sfp_sda_i;
  sfp_det_in(g_num_phys-1 downto 0) <=  sfp_det_i;

  PERIPH : wrc_periph
    generic map(
      g_board_name      => g_board_name,
      g_flash_secsz_kb  => g_flash_secsz_kb,
      g_flash_sdbfs_baddr => g_flash_sdbfs_baddr,
      g_phys_uart       => g_phys_uart,
      g_virtual_uart    => g_virtual_uart,
      g_cntr_period     => g_sys_clock_hz/1000,
      g_mem_words       => g_dpram_size,
      g_vuart_fifo_size => g_vuart_fifo_size,
      g_diag_id         => g_diag_id,
      g_diag_ver        => g_diag_ver,
      g_diag_ro_size    => g_diag_ro_size,
      g_diag_rw_size    => g_diag_rw_size)
    port map(
      clk_sys_i   => clk_sys_i,
      rst_n_i     => rst_n_i,
      rst_net_n_o => rst_net_n,
      rst_wrc_n_o => rst_wrc_n,

      scl_o       => scl_o,
      scl_i       => scl_i,
      sda_o       => sda_o,
      sda_i       => sda_i,
      sfp_scl_o   => sfp_scl_out,
      sfp_scl_i   => sfp_scl_in,
      sfp_sda_o   => sfp_sda_out,
      sfp_sda_i   => sfp_sda_in,
      sfp_det_i   => sfp_det_in,
      memsize_i   => "0000",
      btn1_i      => btn1_i,
      btn2_i      => btn2_i,
      spi_sclk_o  => spi_sclk_o,
      spi_ncs_o   => spi_ncs_o,
      spi_mosi_o  => spi_mosi_o,
      spi_miso_i  => spi_miso_i,

      slave_i => periph_slave_i,
      slave_o => periph_slave_o,

      uart_rxd_i => uart_rxd_i,
      uart_txd_o => uart_txd_o,

      owr_pwren_o => owr_pwren_o,
      owr_en_o    => owr_en_o,
      owr_i       => owr_i,

      diag_array_in  => aux_diag_i,
      diag_array_out => aux_diag_o
      );

  U_Adapter : wb_slave_adapter
    generic map(
      g_master_use_struct  => true,
      g_master_mode        => PIPELINED,
      g_master_granularity => BYTE,
      g_slave_use_struct   => false,
      g_slave_mode         => g_interface_mode,
      g_slave_granularity  => g_address_granularity)
    port map (
      clk_sys_i  => clk_sys_i,
      rst_n_i    => rst_n_i,
      master_i   => ext_wb_out,
      master_o   => ext_wb_in,
      sl_adr_i   => wb_adr_i,
      sl_dat_i   => wb_dat_i,
      sl_sel_i   => wb_sel_i,
      sl_cyc_i   => wb_cyc_i,
      sl_stb_i   => wb_stb_i,
      sl_we_i    => wb_we_i,
      sl_dat_o   => wb_dat_o,
      sl_ack_o   => wb_ack_o,
      sl_err_o   => wb_err_o,
      sl_rty_o   => wb_rty_o,
      sl_stall_o => wb_stall_o);

  GEN_10MHZ_OUTPUT: if g_with_10M_output generate

    U_XWR_GEN_10MHz : xwr_gen_10mhz
      generic map (
        g_interface_mode      => PIPELINED,
        g_address_granularity => BYTE)
      port map(
        clk_sys_i         => clk_sys_i,
        rst_n_i           => rst_n_i,
        pps_i             => s_pps_csync,
        pps_valid_i       => pps_valid,
        sync_clk_10m_o_p  => sync_clk_10m_o_p,
        sync_clk_10m_o_n  => sync_clk_10m_o_n,
        slave_i           => secbar_master_o(10),
        slave_o           => secbar_master_i(10));

  end generate;

  -----------------------------------------------------------------------------
  -- SPI control for PLL chip
  -----------------------------------------------------------------------------
  U_SPI_Master_ext_in_PLL : xwb_spi
    generic map (
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE,
      g_divider_len         => 8,
      g_max_char_len        => 24,
      g_num_slaves          => 1)
    port map (
      clk_sys_i            => clk_sys_i,
      rst_n_i              => rst_n_i,
      slave_i              => secbar_master_o(9),
      slave_o              => secbar_master_i(9),
      desc_o               => open,
      pad_cs_o(0)          => ext_pll_cs_n_o,
      pad_sclk_o           => ext_pll_sck_o,
      pad_mosi_o           => ext_pll_mosi_o,
      pad_miso_i           => ext_pll_miso_i);
      ext_pll_sync_n_o     <= '1';
      ext_pll_reset_n_o    <= rst_n_i;

  -----------------------------------------------------------------------------
  -- WB intercon
  -----------------------------------------------------------------------------
  WB_CON : xwb_sdb_crossbar
    generic map(
      g_verbose     => g_verbose,
      g_num_masters => 3,
      g_num_slaves  => 2,
      g_registered  => true,
      g_wraparound  => true,
      g_layout      => c_layout,
      g_sdb_addr    => c_sdb_address
      )
    port map(
      clk_sys_i => clk_sys_i,
      rst_n_i   => rst_n_i,
      -- Master connections (INTERCON is a slave)
      slave_i   => cbar_slave_i,
      slave_o   => cbar_slave_o,
      -- Slave connections (INTERCON is a master)
      master_i  => cbar_master_i,
      master_o  => cbar_master_o
      );

  cbar_slave_i(2) <= ext_wb_in;
  ext_wb_out      <= cbar_slave_o(2);

  -----------------------------------------------------------------------------
  -- WB Secondary Crossbar
  -----------------------------------------------------------------------------
  WB_SECONDARY_CON : xwb_sdb_crossbar
    generic map(
      g_verbose     => g_verbose,
      g_num_masters => 1,
      g_num_slaves  => c_secbar_slaves,
      g_registered  => true,
      g_wraparound  => true,
      g_layout      => c_secbar_layout,
      g_sdb_addr    => c_secbar_sdb_address
      )
    port map(
      clk_sys_i  => clk_sys_i,
      rst_n_i    => rst_n_i,
      -- Master connections (INTERCON is a slave)
      slave_i(0) => cbar_master_o(1),
      slave_o(0) => cbar_master_i(1),
      -- Slave connections (INTERCON is a master)
      master_i   => secbar_master_i,
      master_o   => secbar_master_o
      );

  secbar_master_i(2) <= spll_wb_out;
  spll_wb_in         <= secbar_master_o(2);
  secbar_master_i(3) <= ppsg_wb_out;
  ppsg_wb_in         <= secbar_master_o(3);
  --peripherials
  secbar_master_i(4) <= periph_slave_o(0);
  secbar_master_i(5) <= periph_slave_o(1);
  secbar_master_i(6) <= periph_slave_o(2);
  secbar_master_i(8) <= periph_slave_o(3);
  periph_slave_i(0)  <= secbar_master_o(4);
  periph_slave_i(1)  <= secbar_master_o(5);
  periph_slave_i(2)  <= secbar_master_o(6);
  periph_slave_i(3)  <= secbar_master_o(8);

  aux_adr_o <= secbar_master_o(7).adr;
  aux_dat_o <= secbar_master_o(7).dat;
  aux_sel_o <= secbar_master_o(7).sel;
  aux_cyc_o <= secbar_master_o(7).cyc;
  aux_stb_o <= secbar_master_o(7).stb;
  aux_we_o  <= secbar_master_o(7).we;

  secbar_master_i(7).dat   <= aux_dat_i;
  secbar_master_i(7).ack   <= aux_ack_i;
  secbar_master_i(7).stall <= aux_stall_i;
  secbar_master_i(7).err   <= '0';
  secbar_master_i(7).rty   <= '0';

  aux1_adr_o <= secbar_master_o(13).adr;
  aux1_dat_o <= secbar_master_o(13).dat;
  aux1_sel_o <= secbar_master_o(13).sel;
  aux1_cyc_o <= secbar_master_o(13).cyc;
  aux1_stb_o <= secbar_master_o(13).stb;
  aux1_we_o  <= secbar_master_o(13).we;

  secbar_master_i(13).dat   <= aux1_dat_i;
  secbar_master_i(13).ack   <= aux1_ack_i;
  secbar_master_i(13).stall <= aux1_stall_i;
  secbar_master_i(13).err   <= '0';
  secbar_master_i(13).rty   <= '0';

  eb_cfg_adr_o <= secbar_master_o(14).adr;
  eb_cfg_dat_o <= secbar_master_o(14).dat;
  eb_cfg_sel_o <= secbar_master_o(14).sel;
  eb_cfg_cyc_o <= secbar_master_o(14).cyc;
  eb_cfg_stb_o <= secbar_master_o(14).stb;
  eb_cfg_we_o  <= secbar_master_o(14).we;

  secbar_master_i(14).dat   <= eb_cfg_dat_i;
  secbar_master_i(14).ack   <= eb_cfg_ack_i;
  secbar_master_i(14).stall <= eb_cfg_stall_i;
  secbar_master_i(14).err   <= '0';
  secbar_master_i(14).rty   <= '0';

  -----------------------------------------------------------------------------
  -- WBP MUX
  -----------------------------------------------------------------------------
  gen_WBP_MUX: for i in 0 to g_num_phys-1 generate
    
    U_WBP_Mux : xwrf_mux
      generic map(
        g_muxed_ports => g_muxed_ports)
      port map (
        clk_sys_i   => clk_sys_i,
        rst_n_i     => rst_net_n,
        ep_src_o    => ep_snk_in(i),
        ep_src_i    => ep_snk_out(i),
        ep_snk_o    => ep_src_in(i),
        ep_snk_i    => ep_src_out(i),
        mux_src_o   => mux_src_out((i+1)*g_muxed_ports-1 downto i*g_muxed_ports),
        mux_src_i   => mux_src_in((i+1)*g_muxed_ports-1 downto i*g_muxed_ports),
        mux_snk_o   => mux_snk_out((i+1)*g_muxed_ports-1 downto i*g_muxed_ports),
        mux_snk_i   => mux_snk_in((i+1)*g_muxed_ports-1 downto i*g_muxed_ports),
        mux_class_i => mux_class);
        
      wrf_src_o(i).adr <= mux_src_out((i+1)*g_muxed_ports-1).adr;
      wrf_src_o(i).dat <= mux_src_out((i+1)*g_muxed_ports-1).dat;
      wrf_src_o(i).stb <= mux_src_out((i+1)*g_muxed_ports-1).stb;
      wrf_src_o(i).cyc <= mux_src_out((i+1)*g_muxed_ports-1).cyc;
      wrf_src_o(i).sel <= mux_src_out((i+1)*g_muxed_ports-1).sel;
      wrf_src_o(i).we  <= '1';
      mux_src_in((i+1)*g_muxed_ports-1).ack   <= wrf_src_i(i).ack;
      mux_src_in((i+1)*g_muxed_ports-1).stall <= wrf_src_i(i).stall;
      mux_src_in((i+1)*g_muxed_ports-1).err   <= wrf_src_i(i).err;
      mux_src_in((i+1)*g_muxed_ports-1).rty   <= '0';
        
      mux_snk_in((i+1)*g_muxed_ports-1).adr <= wrf_snk_i(i).adr;
      mux_snk_in((i+1)*g_muxed_ports-1).dat <= wrf_snk_i(i).dat;
      mux_snk_in((i+1)*g_muxed_ports-1).stb <= wrf_snk_i(i).stb;
      mux_snk_in((i+1)*g_muxed_ports-1).cyc <= wrf_snk_i(i).cyc;
      mux_snk_in((i+1)*g_muxed_ports-1).sel <= wrf_snk_i(i).sel;
      mux_snk_in((i+1)*g_muxed_ports-1).we  <= wrf_snk_i(i).we;
      wrf_snk_o(i).ack   <= mux_snk_out((i+1)*g_muxed_ports-1).ack;
      wrf_snk_o(i).err   <= mux_snk_out((i+1)*g_muxed_ports-1).err;
      wrf_snk_o(i).stall <= mux_snk_out((i+1)*g_muxed_ports-1).stall;
      wrf_snk_o(i).rty   <= '0';

      eb_wrf_src_o(i).adr <= mux_src_out((i+1)*g_muxed_ports-2).adr;
      eb_wrf_src_o(i).dat <= mux_src_out((i+1)*g_muxed_ports-2).dat;
      eb_wrf_src_o(i).stb <= mux_src_out((i+1)*g_muxed_ports-2).stb;
      eb_wrf_src_o(i).cyc <= mux_src_out((i+1)*g_muxed_ports-2).cyc;
      eb_wrf_src_o(i).sel <= mux_src_out((i+1)*g_muxed_ports-2).sel;
      eb_wrf_src_o(i).we  <= '1';
      mux_src_in((i+1)*g_muxed_ports-2).ack   <= eb_wrf_src_i(i).ack;
      mux_src_in((i+1)*g_muxed_ports-2).stall <= eb_wrf_src_i(i).stall;
      mux_src_in((i+1)*g_muxed_ports-2).err   <= eb_wrf_src_i(i).err;
      mux_src_in((i+1)*g_muxed_ports-2).rty   <= '0';
        
      mux_snk_in((i+1)*g_muxed_ports-2).adr <= eb_wrf_snk_i(i).adr;
      mux_snk_in((i+1)*g_muxed_ports-2).dat <= eb_wrf_snk_i(i).dat;
      mux_snk_in((i+1)*g_muxed_ports-2).stb <= eb_wrf_snk_i(i).stb;
      mux_snk_in((i+1)*g_muxed_ports-2).cyc <= eb_wrf_snk_i(i).cyc;
      mux_snk_in((i+1)*g_muxed_ports-2).sel <= eb_wrf_snk_i(i).sel;
      mux_snk_in((i+1)*g_muxed_ports-2).we  <= eb_wrf_snk_i(i).we;
      eb_wrf_snk_o(i).ack   <= mux_snk_out((i+1)*g_muxed_ports-2).ack;
      eb_wrf_snk_o(i).err   <= mux_snk_out((i+1)*g_muxed_ports-2).err;
      eb_wrf_snk_o(i).stall <= mux_snk_out((i+1)*g_muxed_ports-2).stall;
      eb_wrf_snk_o(i).rty   <= '0';
      
  end generate gen_WBP_MUX;

  mux_class(0)  <= x"0f"; -- to lm32
  mux_class(1)  <= x"30"; -- to eb_wrf, other local module
  mux_class(2)  <= x"c0"; -- to wrf, to another port

  -----------------------------------------------------------------------------
  -- External Tx Timestamping I/F
  -----------------------------------------------------------------------------
  GEN_EXT_TX_TIMESTAMP: for i in 0 to g_num_phys-1 generate

    timestamps_o(i).port_id(4 downto 0) <= ep_txtsu_port_id((i+1)*5-1 downto i*5);
    timestamps_o(i).port_id(5) <= '0';
    timestamps_o(i).frame_id   <= ep_txtsu_frame_id((i+1)*16-1 downto i*16);
    timestamps_o(i).tsval      <= ep_txtsu_ts_value((i+1)*32-1 downto i*32);
    timestamps_o(i).incorrect  <= ep_txtsu_ts_incorrect(i);

    -- ts goes to external I/F
    timestamps_o(i).stb   <= '1' when (ep_txtsu_stb(i) = '1' and (ep_txtsu_frame_id((i+1)*16-1 downto i*16) /= x"0000")) else
                            '0';
    -- ts goes to minic
    mnic_txtsu_stb(i)     <=  '1' when (ep_txtsu_stb(i) = '1' and (ep_txtsu_frame_id((i+1)*16-1 downto i*16)  = x"0000")) else
                            '0';

    ep_txtsu_ack(i) <= txtsu_ack_i(i) or mnic_txtsu_ack(i);

  end generate gen_ext_tx_timestamp;

end struct;
