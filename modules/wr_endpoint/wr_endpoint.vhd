-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2010 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : 1000base-X MAC/Endpoint
-- Project    : White Rabbit
-------------------------------------------------------------------------------
-- File       : wr_endpoint.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN BE-CO-HT
-- Created    : 2010-04-26
-- Last update: 2023-03-21
-- Platform   : FPGA-generics
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description: Module implements the top level for the White Rabbit Endpoint
-- It's basically an extended Ethernet MAC providing extra timing/switch-specific
-- features such as:
-- - VLANs: inserting/removing tags (for ACCESS/TRUNK port support)
-- - RX/TX precise timestaping
-- - full PCS for optical Gigabit Ethernet
-- - decodes MAC addresses, VIDs and priorities and passes them to the RTU.
-- Refer to the manual for more details.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

use work.gencores_pkg.all;
use work.endpoint_private_pkg.all;
use work.endpoint_pkg.all;
use work.ep_wbgen2_pkg.all;
use work.wr_fabric_pkg.all;
use work.wishbone_pkg.all;

entity wr_endpoint is

  generic (
    g_interface_mode        : t_wishbone_interface_mode      := CLASSIC;
    g_address_granularity   : t_wishbone_address_granularity := WORD;
    g_tx_force_gap_length   : integer                        := 0;
    g_tx_runt_padding       : boolean                        := true;
    g_simulation            : boolean                        := false;
    g_pcs_16bit             : boolean                        := true;
    g_rx_buffer_size        : integer                        := 1024;
    g_with_rx_buffer        : boolean                        := true;
    g_with_flow_control     : boolean                        := true;
    g_with_timestamper      : boolean                        := true;
    g_with_dpi_classifier   : boolean                        := false;
    g_with_vlans            : boolean                        := true;
    g_with_rtu              : boolean                        := true;
    g_with_leds             : boolean                        := true;
    g_with_packet_injection : boolean                        := false;
    g_use_new_rxcrc         : boolean                        := false;
    g_use_new_txcrc         : boolean                        := false;
    g_with_stop_traffic     : boolean                        := false;
    g_phy_lpcalib           : boolean                        := false;
    g_ep_idx                : integer                        := 0
    );
  port (

-------------------------------------------------------------------------------
-- Clocks
-------------------------------------------------------------------------------

-- Endpoint transmit reference clock. Must be 125 MHz +- 100 ppm
    clk_ref_i : in std_logic;

-- reference clock / 2 (62.5 MHz, in-phase with refclk)
    clk_sys_i : in std_logic;

-- resets for various clock domains
    rst_sys_n_i   : in std_logic;
    rst_ref_n_i   : in std_logic;
    rst_txclk_n_i : in std_logic;
    rst_rxclk_n_i : in std_logic;

-- PPS input (1 clk_ref_i cycle HI) for synchronizing timestamp counter
    pps_csync_p1_i : in std_logic;

-- PPS valid input (clk_ref_i domain), when 1, the external PPS generator/servo
-- is not adjusting the time scale, so we can safely timestamp.
    pps_valid_i : in std_logic := '1';

-------------------------------------------------------------------------------
-- PHY Interace (8/16 bit PCS)
-------------------------------------------------------------------------------

    phy_rst_o            : out std_logic;
    phy_loopen_o         : out std_logic;
    phy_loopen_vec_o     : out std_logic_vector(2 downto 0);
    phy_tx_prbs_sel_o    : out std_logic_vector(2 downto 0);
    phy_sfp_tx_fault_i   : in  std_logic;
    phy_sfp_los_i        : in  std_logic;
    phy_sfp_tx_disable_o : out std_logic;
    phy_rdy_i            : in  std_logic;

    -- clk_sys_i domain!
    phy_mdio_master_cyc_o : out std_logic;
    phy_mdio_master_stb_o : out std_logic;
    phy_mdio_master_we_o : out std_logic;
    phy_mdio_master_dat_o : out std_logic_vector(31 downto 0);
    phy_mdio_master_sel_o : out std_logic_vector(3 downto 0) := "0000";
    phy_mdio_master_adr_o : out std_logic_vector(31 downto 0);
    phy_mdio_master_ack_i : in std_logic := '0';
    phy_mdio_master_stall_i : in std_logic := '0';
    phy_mdio_master_dat_i : in std_logic_vector(31 downto 0) := x"00000000";

    phy_ref_clk_i      : in  std_logic;
    phy_tx_data_o      : out std_logic_vector(f_pcs_data_width(g_pcs_16bit)-1 downto 0);
    phy_tx_k_o         : out std_logic_vector(f_pcs_k_width(g_pcs_16bit)-1 downto 0);
    phy_tx_disparity_i : in  std_logic;
    phy_tx_enc_err_i   : in  std_logic;

    phy_rx_data_i     : in std_logic_vector(f_pcs_data_width(g_pcs_16bit)-1 downto 0);
    phy_rx_clk_i      : in std_logic;
    phy_rx_k_i        : in std_logic_vector(f_pcs_k_width(g_pcs_16bit)-1 downto 0);
    phy_rx_enc_err_i  : in std_logic;
    phy_rx_bitslide_i : in std_logic_vector(f_pcs_bts_width(g_pcs_16bit)-1 downto 0);

    ---------------------------------------------------------------------------
    -- Wishbone I/O
    ---------------------------------------------------------------------------

    src_dat_o   : out std_logic_vector(15 downto 0);
    src_adr_o   : out std_logic_vector(1 downto 0);
    src_sel_o   : out std_logic_vector(1 downto 0);
    src_cyc_o   : out std_logic;
    src_stb_o   : out std_logic;
    src_we_o    : out std_logic;
    src_stall_i : in  std_logic;
    src_ack_i   : in  std_logic;
    src_err_i   : in  std_logic;

    snk_dat_i   : in  std_logic_vector(15 downto 0);
    snk_adr_i   : in  std_logic_vector(1 downto 0);
    snk_sel_i   : in  std_logic_vector(1 downto 0);
    snk_cyc_i   : in  std_logic;
    snk_stb_i   : in  std_logic;
    snk_we_i    : in  std_logic;
    snk_stall_o : out std_logic;
    snk_ack_o   : out std_logic;
    snk_err_o   : out std_logic;
    snk_rty_o   : out std_logic;

-------------------------------------------------------------------------------
-- TX timestamping unit interface
-------------------------------------------------------------------------------

-- Port ID value
    txtsu_port_id_o  : out std_logic_vector(4 downto 0);
-- Frame ID value
    txtsu_frame_id_o : out std_logic_vector(16 -1 downto 0);

-- TX Timestamp and correctness info
    txtsu_ts_value_o     : out std_logic_vector(28 + 4 - 1 downto 0);
    txtsu_ts_incorrect_o : out std_logic;

-- TX timestamp strobe: HI tells the TX timestamping unit that a timestamp is
-- available on txtsu_ts_value_o, txtsu_fid_o andd txtsu_port_id_o. The correctness
-- of the timestamping is indiacted on txtsu_ts_incorrect_o. Line remains HI
-- until assertion of txtsu_ack_i.
    txtsu_stb_o : out std_logic;

-- TX timestamp acknowledge: HI indicates that TXTSU has successfully received
-- the timestamp
    txtsu_ack_i : in std_logic;

-------------------------------------------------------------------------------
-- RTU interface
-------------------------------------------------------------------------------

-- 1 indicates that coresponding RTU port is full.
    rtu_full_i : in std_logic;

-- 1 indicates that coresponding RTU port is almost full.
    rtu_almost_full_i : in std_logic;

-- request strobe, single HI pulse begins evaluation of the request.
    rtu_rq_strobe_p1_o : out std_logic;

    rtu_rq_abort_o : out std_logic;

-- source and destination MAC addresses extracted from the packet header
    rtu_rq_smac_o : out std_logic_vector(48 - 1 downto 0);
    rtu_rq_dmac_o : out std_logic_vector(48 - 1 downto 0);

-- VLAN id (extracted from the header for TRUNK ports and assigned by the port
-- for ACCESS ports)
    rtu_rq_vid_o : out std_logic_vector(12 - 1 downto 0);

-- HI means that packet has valid assigned a valid VID (low - packet is untagged)
    rtu_rq_has_vid_o : out std_logic;

-- packet priority (either extracted from the header or assigned per port).
    rtu_rq_prio_o : out std_logic_vector(3 - 1 downto 0);

-- HI indicates that packet has assigned priority.
    rtu_rq_has_prio_o : out std_logic;

-------------------------------------------------------------------------------
-- Wishbone bus
-------------------------------------------------------------------------------

    wb_cyc_i   : in  std_logic;
    wb_stb_i   : in  std_logic;
    wb_we_i    : in  std_logic;
    wb_sel_i   : in  std_logic_vector(3 downto 0);
    wb_adr_i   : in  std_logic_vector(7 downto 0);
    wb_dat_i   : in  std_logic_vector(31 downto 0);
    wb_dat_o   : out std_logic_vector(31 downto 0);
    wb_ack_o   : out std_logic;
    wb_stall_o : out std_logic;

-------------------------------------------------------------------------------
-- direct output of packet filter  (for TRU/HW-RSTP)
-------------------------------------------------------------------------------

   pfilter_pclass_o : out std_logic_vector(7 downto 0);
   pfilter_drop_o   : out std_logic;
   pfilter_done_o   : out std_logic;

-------------------------------------------------------------------------------
-- control of PAUSE sending (ML: not used and not tested... TRU uses packet injection) --
-------------------------------------------------------------------------------

   fc_tx_pause_req_i   : in  std_logic                     := '0';
   fc_tx_pause_delay_i : in  std_logic_vector(15 downto 0) := x"0000";
   fc_tx_pause_ready_o : out std_logic;

-------------------------------------------------------------------------------
-- information about received PAUSE (for SWcore)
-------------------------------------------------------------------------------

   fc_rx_pause_start_p_o   : out std_logic;
   fc_rx_pause_quanta_o    : out std_logic_vector(15 downto 0);
   fc_rx_pause_prio_mask_o : out std_logic_vector(7 downto 0);
   fc_rx_buffer_occupation_o : out std_logic_vector(7 downto 0);
-------------------------------------------------------------------------------
-- Packet Injection Interface (for TRU/HW-RSTP)
-------------------------------------------------------------------------------

-- injection request: triggers transmission of the packet to be injected,
-- allowed when inject_ready = 1
    inject_req_i : in std_logic := '0';

-- injection ready flag: when true, user application can request asynchronous
-- injection of a predefined packet
    inject_ready_o : out std_logic;

-- injection template selection (8 available)
    inject_packet_sel_i : in std_logic_vector(2 downto 0) := "000";

-- user-defined value to be embedded in the injected packet at a predefined
-- location
    inject_user_value_i : in std_logic_vector(15 downto 0) := x"0000";

-------------------------------------------------------------------------------
-- Misc stuff
-------------------------------------------------------------------------------
    rmon_events_o : out std_logic_vector(c_epevents_sz-1 downto 0);

    txts_o     : out std_logic; 		                -- 2013-Nov-28 peterj added for debugging/calibration
    rxts_o     : out std_logic; 		                -- 2013-Nov-28 peterj added for debugging/calibration

    led_link_o : out std_logic;
    led_act_o  : out std_logic;

-- HI physically kills the link (turn of laser)
    link_kill_i : in std_logic := '0';

-- HI indicates that link is up (so cable connected), LOW indicates that link is faulty
-- (e.g.: cable disconnected)
    link_up_o : out std_logic;

    stop_traffic_i : in std_logic := '0';

    --  Set by sw.
    my_mac_addr_o             : out std_logic_vector(47 downto 0);

    dbg_tx_pcs_wr_count_o     : out std_logic_vector(5+4 downto 0);
    dbg_tx_pcs_rd_count_o     : out std_logic_vector(5+4 downto 0);
    nice_dbg_o                : out t_dbg_ep
    );

end wr_endpoint;

architecture syn of wr_endpoint is
  signal wb_in  : t_wishbone_slave_in;
  signal wb_out : t_wishbone_slave_out;
begin
  U_Slave_adapter : entity work.wb_slave_adapter
    generic map (
      g_master_use_struct  => true,
      g_master_mode        => CLASSIC,
      g_master_granularity => BYTE,
      g_slave_use_struct   => false,
      g_slave_mode         => g_interface_mode,
      g_slave_granularity  => g_address_granularity)
    port map (
      clk_sys_i  => clk_sys_i,
      rst_n_i    => rst_sys_n_i,
      sl_adr_i(7 downto 0) => wb_adr_i,
      sl_adr_i(31 downto 8) => (others => '0'),
      sl_dat_i   => wb_dat_i,
      sl_sel_i   => wb_sel_i,
      sl_cyc_i   => wb_cyc_i,
      sl_stb_i   => wb_stb_i,
      sl_we_i    => wb_we_i,
      sl_dat_o   => wb_dat_o,
      sl_ack_o   => wb_ack_o,
      sl_stall_o => wb_stall_o,
      sl_err_o   => open,
      sl_rty_o   => open,
      master_i   => wb_out,
      master_o   => wb_in);

  U_Wrapped_Endpoint : entity work.xwr_endpoint
    generic map (
      g_interface_mode      => g_interface_mode,
      g_address_granularity => g_address_granularity,
      g_tx_force_gap_length => g_tx_force_gap_length,
      g_tx_runt_padding     => g_tx_runt_padding,
      g_simulation            => g_simulation,
      g_pcs_16bit             => g_pcs_16bit,
      g_rx_buffer_size        => g_rx_buffer_size,
      g_with_rx_buffer        => g_with_rx_buffer,
      g_with_flow_control     => g_with_flow_control,
      g_with_timestamper      => g_with_timestamper,
      g_with_dpi_classifier   => g_with_dpi_classifier,
      g_with_vlans            => g_with_vlans,
      g_with_rtu              => g_with_rtu,
      g_with_leds             => g_with_leds,
      g_with_packet_injection => g_with_packet_injection,
      g_use_new_rxcrc         => g_use_new_rxcrc,
      g_use_new_txcrc         => g_use_new_txcrc,
      g_with_stop_traffic     => g_with_stop_traffic,
      g_phy_lpcalib           => g_phy_lpcalib,
      g_ep_idx                => g_ep_idx)
    port map (
      clk_ref_i            => clk_ref_i,
      clk_sys_i            => clk_sys_i,
      rst_sys_n_i          => rst_sys_n_i,
      rst_ref_n_i          => rst_ref_n_i,
      rst_txclk_n_i        => rst_txclk_n_i,
      rst_rxclk_n_i        => rst_rxclk_n_i,
      pps_csync_p1_i       => pps_csync_p1_i,
      pps_valid_i          => pps_valid_i,

      phy_rst_o            => phy_rst_o,
      phy_loopen_o         => phy_loopen_o,
      phy_loopen_vec_o     => phy_loopen_vec_o,
      phy_tx_prbs_sel_o    => phy_tx_prbs_sel_o,
      phy_rdy_i            => phy_rdy_i,

      phy_mdio_master_o.cyc     => phy_mdio_master_cyc_o,
      phy_mdio_master_o.stb     => phy_mdio_master_stb_o,
      phy_mdio_master_o.we      => phy_mdio_master_we_o,
      phy_mdio_master_o.sel     => phy_mdio_master_sel_o,
      phy_mdio_master_o.adr     => phy_mdio_master_adr_o,
      phy_mdio_master_o.dat     => phy_mdio_master_dat_o,
      phy_mdio_master_i.dat     => phy_mdio_master_dat_i,
      phy_mdio_master_i.stall   => phy_mdio_master_stall_i,
      phy_mdio_master_i.ack     => phy_mdio_master_ack_i,
      phy_mdio_master_i.rty     => '0',
      phy_mdio_master_i.err     => '0',

      phy_sfp_tx_fault_i   => phy_sfp_tx_fault_i,
      phy_sfp_los_i        => phy_sfp_los_i,
      phy_sfp_tx_disable_o => phy_sfp_tx_disable_o,

      phy_ref_clk_i        => phy_ref_clk_i,
      phy_tx_data_o        => phy_tx_data_o,
      phy_tx_k_o           => phy_tx_k_o,
      phy_tx_disparity_i   => phy_tx_disparity_i,
      phy_tx_enc_err_i     => phy_tx_enc_err_i,
      phy_rx_data_i        => phy_rx_data_i,
      phy_rx_clk_i         => phy_rx_clk_i,
      phy_rx_k_i           => phy_rx_k_i,
      phy_rx_enc_err_i     => phy_rx_enc_err_i,
      phy_rx_bitslide_i    => phy_rx_bitslide_i,

      src_o.dat            => src_dat_o,
      src_o.adr            => src_adr_o,
      src_o.sel            => src_sel_o,
      src_o.cyc            => src_cyc_o,
      src_o.stb            => src_stb_o,
      src_o.we             => src_we_o,
      src_i.stall          => src_stall_i,
      src_i.ack            => src_ack_i,
      src_i.err            => src_err_i,
      src_i.rty            => '0',
      snk_i.dat            => snk_dat_i,
      snk_i.adr            => snk_adr_i,
      snk_i.sel            => snk_sel_i,
      snk_i.cyc            => snk_cyc_i,
      snk_i.stb            => snk_stb_i,
      snk_i.we             => snk_we_i,
      snk_o.stall          => snk_stall_o,
      snk_o.ack            => snk_ack_o,
      snk_o.err            => snk_err_o,
      snk_o.rty            => snk_rty_o,
      txtsu_port_id_o      => txtsu_port_id_o,
      txtsu_frame_id_o     => txtsu_frame_id_o,
      txtsu_ts_value_o     => txtsu_ts_value_o,
      txtsu_ts_incorrect_o => txtsu_ts_incorrect_o,
      txtsu_stb_o          => txtsu_stb_o,
      txtsu_ack_i          => txtsu_ack_i,
      rtu_full_i           => rtu_full_i,
      rtu_almost_full_i    => rtu_almost_full_i,
      rtu_rq_strobe_p1_o   => rtu_rq_strobe_p1_o,
      rtu_rq_abort_o       => rtu_rq_abort_o,
      rtu_rq_smac_o        => rtu_rq_smac_o,
      rtu_rq_dmac_o        => rtu_rq_dmac_o,
      rtu_rq_vid_o         => rtu_rq_vid_o,
      rtu_rq_has_vid_o     => rtu_rq_has_vid_o,
      rtu_rq_prio_o        => rtu_rq_prio_o,
      rtu_rq_has_prio_o    => rtu_rq_has_prio_o,
      wb_i                 => wb_in,
      wb_o                 => wb_out,
      rmon_events_o        => rmon_events_o,
      txts_o               => txts_o, 		-- 2013-Nov-28 peterj added for debugging/calibration
      rxts_o               => rxts_o, 		-- 2013-Nov-28 peterj added for debugging/calibration
      led_link_o           => led_link_o,
      led_act_o            => led_act_o,
      link_up_o            => link_up_o,
      link_kill_i          => link_kill_i,
      pfilter_pclass_o     => pfilter_pclass_o,
      pfilter_drop_o       => pfilter_drop_o,
      pfilter_done_o       => pfilter_done_o,
      fc_tx_pause_req_i    => fc_tx_pause_req_i,
      fc_tx_pause_delay_i  => fc_tx_pause_delay_i,
      fc_tx_pause_ready_o  => fc_tx_pause_ready_o,
      fc_rx_pause_start_p_o   => fc_rx_pause_start_p_o,
      fc_rx_pause_quanta_o    => fc_rx_pause_quanta_o,
      fc_rx_pause_prio_mask_o => fc_rx_pause_prio_mask_o,
      fc_rx_buffer_occupation_o =>fc_rx_buffer_occupation_o,
      inject_req_i         => inject_req_i,
      inject_user_value_i  => inject_user_value_i,
      inject_packet_sel_i  => inject_packet_sel_i,
      inject_ready_o       => inject_ready_o,
      stop_traffic_i       => stop_traffic_i,
      my_mac_addr_o        => my_mac_addr_o,
      dbg_tx_pcs_wr_count_o=>dbg_tx_pcs_wr_count_o,
      dbg_tx_pcs_rd_count_o=>dbg_tx_pcs_rd_count_o,
      nice_dbg_o           => nice_dbg_o);
end syn;
