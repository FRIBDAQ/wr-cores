//------------------------------------------------------------------------------
//  (c) Copyright 2013-2018 Xilinx, Inc. All rights reserved.
//
//  This file contains confidential and proprietary information
//  of Xilinx, Inc. and is protected under U.S. and
//  international copyright and other intellectual property
//  laws.
//
//  DISCLAIMER
//  This disclaimer is not a license and does not grant any
//  rights to the materials distributed herewith. Except as
//  otherwise provided in a valid license issued to you by
//  Xilinx, and to the maximum extent permitted by applicable
//  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//  (2) Xilinx shall not be liable (whether in contract or tort,
//  including negligence, or under any other theory of
//  liability) for any loss or damage of any kind or nature
//  related to, arising under or in connection with these
//  materials, including for any direct, or any indirect,
//  special, incidental, or consequential loss or damage
//  (including loss of data, profits, goodwill, or any type of
//  loss or damage suffered as a result of any action brought
//  by a third party) even if such damage or loss was
//  reasonably foreseeable or Xilinx had been advised of the
//  possibility of the same.
//
//  CRITICAL APPLICATIONS
//  Xilinx products are not designed or intended to be fail-
//  safe, or for use in any application requiring fail-safe
//  performance, such as life-support or safety devices or
//  systems, Class III medical devices, nuclear facilities,
//  applications related to the deployment of airbags, or any
//  other applications that could lead to death, personal
//  injury, or severe property or environmental damage
//  (individually and collectively, "Critical
//  Applications"). Customer assumes the sole risk and
//  liability of any use of Xilinx products in Critical
//  Applications, subject only to applicable laws and
//  regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//  PART OF THIS FILE AT ALL TIMES.
//------------------------------------------------------------------------------


`timescale 1ps/1ps

// =====================================================================================================================
// This example design wrapper module instantiates the core and any helper blocks which the user chose to exclude from
// the core, connects them as appropriate, and maps enabled ports
// =====================================================================================================================

module gtwizard_ultrascale_qpll_example_wrapper (
  input  wire [0:0] gthrxn_in
 ,input  wire [0:0] gthrxp_in
 ,output wire [0:0] gthtxn_out
 ,output wire [0:0] gthtxp_out
 ,input  wire [0:0] gtwiz_userclk_tx_reset_in
 ,output wire [0:0] gtwiz_userclk_tx_srcclk_out
 ,output wire [0:0] gtwiz_userclk_tx_usrclk_out
 ,output wire [0:0] gtwiz_userclk_tx_usrclk2_out
 ,output wire [0:0] gtwiz_userclk_tx_active_out
 ,input  wire [0:0] gtwiz_userclk_rx_reset_in
 ,output wire [0:0] gtwiz_userclk_rx_srcclk_out
 ,output wire [0:0] gtwiz_userclk_rx_usrclk_out
 ,output wire [0:0] gtwiz_userclk_rx_usrclk2_out
 ,output wire [0:0] gtwiz_userclk_rx_active_out
 ,input  wire [0:0] gtwiz_buffbypass_tx_reset_in
 ,input  wire [0:0] gtwiz_buffbypass_tx_start_user_in
 ,output wire [0:0] gtwiz_buffbypass_tx_done_out
 ,output wire [0:0] gtwiz_buffbypass_tx_error_out
 ,input  wire [0:0] gtwiz_buffbypass_rx_reset_in
 ,input  wire [0:0] gtwiz_buffbypass_rx_start_user_in
 ,output wire [0:0] gtwiz_buffbypass_rx_done_out
 ,output wire [0:0] gtwiz_buffbypass_rx_error_out
 ,input  wire [0:0] gtwiz_reset_clk_freerun_in
 ,input  wire [0:0] gtwiz_reset_all_in
 ,input  wire [0:0] gtwiz_reset_tx_pll_and_datapath_in
 ,input  wire [0:0] gtwiz_reset_tx_datapath_in
 ,input  wire [0:0] gtwiz_reset_rx_pll_and_datapath_in
 ,input  wire [0:0] gtwiz_reset_rx_datapath_in
 ,output wire [0:0] gtwiz_reset_rx_cdr_stable_out
 ,output wire [0:0] gtwiz_reset_tx_done_out
 ,output wire [0:0] gtwiz_reset_rx_done_out
 ,input  wire [15:0] gtwiz_userdata_tx_in
 ,output wire [15:0] gtwiz_userdata_rx_out
 ,input  wire [0:0] gtrefclk00_in
 ,output wire [0:0] qpll0outclk_out
 ,output wire [0:0] qpll0outrefclk_out
 ,output wire [0:0] qpll1outclk_out
 ,output wire [0:0] qpll1outrefclk_out
 ,input  wire [0:0] rx8b10ben_in
 ,input  wire [0:0] rxcommadeten_in
 ,input  wire [0:0] rxmcommaalignen_in
 ,input  wire [0:0] rxpcommaalignen_in
 ,input  wire [0:0] rxslide_in
 ,input  wire [0:0] tx8b10ben_in
 ,input  wire [15:0] txctrl0_in
 ,input  wire [15:0] txctrl1_in
 ,input  wire [7:0] txctrl2_in
 ,output wire [0:0] gtpowergood_out
 ,output wire [0:0] rxbyteisaligned_out
 ,output wire [0:0] rxbyterealign_out
 ,output wire [0:0] rxcommadet_out
 ,output wire [15:0] rxctrl0_out
 ,output wire [15:0] rxctrl1_out
 ,output wire [7:0] rxctrl2_out
 ,output wire [7:0] rxctrl3_out
 ,output wire [0:0] rxpmaresetdone_out
 ,output wire [0:0] txpmaresetdone_out
 ,output wire [0:0] txprgdivresetdone_out
);


  // ===================================================================================================================
  // PARAMETERS AND FUNCTIONS
  // ===================================================================================================================

  // Declare and initialize local parameters and functions used for HDL generation
  localparam [191:0] P_CHANNEL_ENABLE = 192'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000;
  `include "gtwizard_ultrascale_qpll_example_wrapper_functions.v"
  localparam integer P_TX_MASTER_CH_PACKED_IDX = f_calc_pk_mc_idx(4);
  localparam integer P_RX_MASTER_CH_PACKED_IDX = f_calc_pk_mc_idx(4);


  // ===================================================================================================================
  // HELPER BLOCKS
  // ===================================================================================================================

  // Any helper blocks which the user chose to exclude from the core will appear below. In addition, some signal
  // assignments related to optionally-enabled ports may appear below.

  // -------------------------------------------------------------------------------------------------------------------
  // Transmitter user clocking network helper block
  // -------------------------------------------------------------------------------------------------------------------

  wire [0:0] txusrclk_int;
  wire [0:0] txusrclk2_int;
  wire [0:0] txoutclk_int;

  // Generate a single module instance which is driven by a clock source associated with the master transmitter channel,
  // and which drives TXUSRCLK and TXUSRCLK2 for all channels

  // The source clock is TXOUTCLK from the master transmitter channel
  assign gtwiz_userclk_tx_srcclk_out = txoutclk_int[P_TX_MASTER_CH_PACKED_IDX];

  // Instantiate a single instance of the transmitter user clocking network helper block
  gtwizard_ultrascale_qpll_example_gtwiz_userclk_tx gtwiz_userclk_tx_inst (
    .gtwiz_userclk_tx_srcclk_in   (gtwiz_userclk_tx_srcclk_out),
    .gtwiz_userclk_tx_reset_in    (gtwiz_userclk_tx_reset_in),
    .gtwiz_userclk_tx_usrclk_out  (gtwiz_userclk_tx_usrclk_out),
    .gtwiz_userclk_tx_usrclk2_out (gtwiz_userclk_tx_usrclk2_out),
    .gtwiz_userclk_tx_active_out  (gtwiz_userclk_tx_active_out)
  );

  // Drive TXUSRCLK and TXUSRCLK2 for all channels with the respective helper block outputs
  assign txusrclk_int  = {1{gtwiz_userclk_tx_usrclk_out}};
  assign txusrclk2_int = {1{gtwiz_userclk_tx_usrclk2_out}};

  // -------------------------------------------------------------------------------------------------------------------
  // Receiver user clocking network helper block
  // -------------------------------------------------------------------------------------------------------------------

  wire [0:0] rxusrclk_int;
  wire [0:0] rxusrclk2_int;
  wire [0:0] rxoutclk_int;

  // Generate a single module instance which is driven by a clock source associated with the master receiver channel,
  // and which drives RXUSRCLK and RXUSRCLK2 for all channels

  // The source clock is RXOUTCLK from the master receiver channel
  assign gtwiz_userclk_rx_srcclk_out = rxoutclk_int[P_RX_MASTER_CH_PACKED_IDX];

  // Instantiate a single instance of the receiver user clocking network helper block
  gtwizard_ultrascale_qpll_example_gtwiz_userclk_rx gtwiz_userclk_rx_inst (
    .gtwiz_userclk_rx_srcclk_in   (gtwiz_userclk_rx_srcclk_out),
    .gtwiz_userclk_rx_reset_in    (gtwiz_userclk_rx_reset_in),
    .gtwiz_userclk_rx_usrclk_out  (gtwiz_userclk_rx_usrclk_out),
    .gtwiz_userclk_rx_usrclk2_out (gtwiz_userclk_rx_usrclk2_out),
    .gtwiz_userclk_rx_active_out  (gtwiz_userclk_rx_active_out)
  );

  // Drive RXUSRCLK and RXUSRCLK2 for all channels with the respective helper block outputs
  assign rxusrclk_int  = {1{gtwiz_userclk_rx_usrclk_out}};
  assign rxusrclk2_int = {1{gtwiz_userclk_rx_usrclk2_out}};

  // -------------------------------------------------------------------------------------------------------------------
  // Reset controller helper block
  // -------------------------------------------------------------------------------------------------------------------

  // Generate a single module instance which controls all PLLs and all channels within the core

  // Depending on the number of user clocking network helper blocks, either use the single user clock active indicator
  // or a logical combination of per-channel user clock active indicators as the user clock active indicator for use in
  // this block
  wire gtwiz_reset_userclk_tx_active_int;
  wire gtwiz_reset_userclk_rx_active_int;

  assign gtwiz_reset_userclk_tx_active_int = gtwiz_userclk_tx_active_out;
  assign gtwiz_reset_userclk_rx_active_int = gtwiz_userclk_rx_active_out;

  // Combine the appropriate PLL lock signals such that the reset controller can sense when all PLLs which clock each
  // data direction are locked, regardless of what PLL source is used
  wire gtwiz_reset_plllock_tx_int;
  wire gtwiz_reset_plllock_rx_int;

  wire [0:0] qpll0lock_int;

  assign gtwiz_reset_plllock_tx_int = &qpll0lock_int;
  assign gtwiz_reset_plllock_rx_int = &qpll0lock_int;

  // Combine the power good, reset done, and CDR lock indicators across all channels, per data direction
  wire [0:0] gtpowergood_int;
  wire [0:0] rxcdrlock_int;
  wire [0:0] txresetdone_int;
  wire [0:0] rxresetdone_int;
  wire gtwiz_reset_gtpowergood_int;
  wire gtwiz_reset_rxcdrlock_int;
  wire gtwiz_reset_txresetdone_int;
  wire gtwiz_reset_rxresetdone_int;

  assign gtwiz_reset_gtpowergood_int = &gtpowergood_int;
  assign gtwiz_reset_rxcdrlock_int   = &rxcdrlock_int;

  wire [0:0] txresetdone_sync;
  wire [0:0] rxresetdone_sync;
  genvar gi_ch_xrd;
  generate for (gi_ch_xrd = 0; gi_ch_xrd < 1; gi_ch_xrd = gi_ch_xrd + 1) begin : gen_ch_xrd
    (* DONT_TOUCH = "TRUE" *)
    gtwizard_ultrascale_qpll_example_bit_synchronizer bit_synchronizer_txresetdone_inst (
      .clk_in (gtwiz_reset_clk_freerun_in),
      .i_in   (txresetdone_int[gi_ch_xrd]),
      .o_out  (txresetdone_sync[gi_ch_xrd])
    );
    (* DONT_TOUCH = "TRUE" *)
    gtwizard_ultrascale_qpll_example_bit_synchronizer bit_synchronizer_rxresetdone_inst (
      .clk_in (gtwiz_reset_clk_freerun_in),
      .i_in   (rxresetdone_int[gi_ch_xrd]),
      .o_out  (rxresetdone_sync[gi_ch_xrd])
    );
  end
  endgenerate
  assign gtwiz_reset_txresetdone_int = &txresetdone_sync;
  assign gtwiz_reset_rxresetdone_int = &rxresetdone_sync;

  wire gtwiz_reset_pllreset_tx_int;
  wire gtwiz_reset_txprogdivreset_int;
  wire gtwiz_reset_gttxreset_int;
  wire gtwiz_reset_txuserrdy_int;
  wire gtwiz_reset_pllreset_rx_int;
  wire gtwiz_reset_rxprogdivreset_int;
  wire gtwiz_reset_gtrxreset_int;
  wire gtwiz_reset_rxuserrdy_int;

  // Instantiate the single reset controller
  (* DONT_TOUCH = "TRUE" *)
  gtwizard_ultrascale_qpll_example_gtwiz_reset gtwiz_reset_inst (
    .gtwiz_reset_clk_freerun_in         (gtwiz_reset_clk_freerun_in),
    .gtwiz_reset_all_in                 (gtwiz_reset_all_in),
    .gtwiz_reset_tx_pll_and_datapath_in (gtwiz_reset_tx_pll_and_datapath_in),
    .gtwiz_reset_tx_datapath_in         (gtwiz_reset_tx_datapath_in),
    .gtwiz_reset_rx_pll_and_datapath_in (gtwiz_reset_rx_pll_and_datapath_in),
    .gtwiz_reset_rx_datapath_in         (gtwiz_reset_rx_datapath_in),
    .gtwiz_reset_rx_cdr_stable_out      (gtwiz_reset_rx_cdr_stable_out),
    .gtwiz_reset_tx_done_out            (gtwiz_reset_tx_done_out),
    .gtwiz_reset_rx_done_out            (gtwiz_reset_rx_done_out),
    .gtwiz_reset_userclk_tx_active_in   (gtwiz_reset_userclk_tx_active_int),
    .gtwiz_reset_userclk_rx_active_in   (gtwiz_reset_userclk_rx_active_int),
    .gtpowergood_in                     (gtwiz_reset_gtpowergood_int),
    .txusrclk2_in                       (gtwiz_userclk_tx_usrclk2_out),
    .plllock_tx_in                      (gtwiz_reset_plllock_tx_int),
    .txresetdone_in                     (gtwiz_reset_txresetdone_int),
    .rxusrclk2_in                       (gtwiz_userclk_rx_usrclk2_out),
    .plllock_rx_in                      (gtwiz_reset_plllock_rx_int),
    .rxcdrlock_in                       (gtwiz_reset_rxcdrlock_int),
    .rxresetdone_in                     (gtwiz_reset_rxresetdone_int),
    .pllreset_tx_out                    (gtwiz_reset_pllreset_tx_int),
    .txprogdivreset_out                 (gtwiz_reset_txprogdivreset_int),
    .gttxreset_out                      (gtwiz_reset_gttxreset_int),
    .txuserrdy_out                      (gtwiz_reset_txuserrdy_int),
    .pllreset_rx_out                    (gtwiz_reset_pllreset_rx_int),
    .rxprogdivreset_out                 (gtwiz_reset_rxprogdivreset_int),
    .gtrxreset_out                      (gtwiz_reset_gtrxreset_int),
    .rxuserrdy_out                      (gtwiz_reset_rxuserrdy_int),
    .tx_enabled_tie_in                  (1'b1),
    .rx_enabled_tie_in                  (1'b1),
    .shared_pll_tie_in                  (1'b1)
  );

  // Drive the internal PLL reset inputs with the appropriate PLL reset signals produced by the reset controller. The
  // single reset controller instance generates independent transmit PLL reset and receive PLL reset outputs, which are
  // used across all such PLLs in the core.
  wire [0:0] qpll0reset_int;

  assign qpll0reset_int = {1{gtwiz_reset_pllreset_tx_int || gtwiz_reset_pllreset_rx_int}};

  // Fan out appropriate reset controller outputs to all transceiver channels
  wire [0:0] txprogdivreset_int;
  wire [0:0] gttxreset_int;
  wire [0:0] txuserrdy_int;
  wire [0:0] rxprogdivreset_int;
  wire [0:0] gtrxreset_int;
  wire [0:0] rxuserrdy_int;

  assign txprogdivreset_int  = {1{gtwiz_reset_txprogdivreset_int}};
  assign gttxreset_int       = {1{gtwiz_reset_gttxreset_int}};
  assign txuserrdy_int       = {1{gtwiz_reset_txuserrdy_int}};
  assign rxprogdivreset_int  = {1{gtwiz_reset_rxprogdivreset_int}};
  assign gtrxreset_int       = {1{gtwiz_reset_gtrxreset_int}};
  assign rxuserrdy_int       = {1{gtwiz_reset_rxuserrdy_int}};

  // Required assignment to expose the GTPOWERGOOD port per user request
  assign gtpowergood_out = gtpowergood_int;

  // ----------------------------------------------------------------------------------------------------------------
  // Assignments to expose data ports, or data control ports, per configuration requirement or user request
  // ----------------------------------------------------------------------------------------------------------------

  wire [15:0] txctrl0_int;

  // Required assignment to expose the TXCTRL0 port per configuration requirement or user request
  assign txctrl0_int = txctrl0_in;
  wire [15:0] txctrl1_int;

  // Required assignment to expose the TXCTRL1 port per configuration requirement or user request
  assign txctrl1_int = txctrl1_in;
  wire [15:0] rxctrl0_int;

  // Required assignment to expose the RXCTRL0 port per configuration requirement or user request
  assign rxctrl0_out = rxctrl0_int;
  wire [15:0] rxctrl1_int;

  // Required assignment to expose the RXCTRL1 port per configuration requirement or user request
  assign rxctrl1_out = rxctrl1_int;

  // ===================================================================================================================
  // TRANSCEIVER COMMON BLOCK
  // ===================================================================================================================

  wire [0:0] gtrefclk00_int;
  wire [0:0] qpll0clk_int;
  wire [0:0] qpll0refclk_int;

  // When QPLL0 is used, the following assignments support the use of the transceiver COMMON block in the example design
  assign gtrefclk00_int = gtrefclk00_in;
  genvar gi_ch_to_cm0;
  generate for (gi_ch_to_cm0 = 0; gi_ch_to_cm0 < 1; gi_ch_to_cm0 = gi_ch_to_cm0 + 1) begin : gen_ch_to_cm0
    assign qpll0clk_int    [gi_ch_to_cm0] = qpll0outclk_out    [f_idx_cm(gi_ch_to_cm0)];
    assign qpll0refclk_int [gi_ch_to_cm0] = qpll0outrefclk_out [f_idx_cm(gi_ch_to_cm0)];
  end
  endgenerate

  wire [0:0] gtrefclk01_int;
  wire [0:0] qpll1clk_int;
  wire [0:0] qpll1refclk_int;
  wire [0:0] qpll1reset_int;
  wire [0:0] qpll1lock_int;

  // When QPLL1 is not used, the following assignments tie off QPLL1-related inputs as appropriate
  assign gtrefclk01_int  = {1{1'b0}};
  assign qpll1clk_int    = {1{1'b0}};
  assign qpll1refclk_int = {1{1'b0}};
  assign qpll1reset_int  = {1{1'b1}};

  localparam [47:0] P_COMMON_ENABLE = f_pop_cm_en(0);

  // The following HDL generate loop iterates across each possible transceiver quad, instantiating only the enabled
  // transceiver COMMON blocks, each within a configuration-specific parameterization wrapper
  genvar cm;
  generate for (cm = 0; cm < 48; cm = cm + 1) begin : gen_common_container
    if (P_COMMON_ENABLE[cm] == 1'b1) begin : gen_enabled_common

      gtwizard_ultrascale_qpll_gthe4_common_wrapper gthe4_common_wrapper_inst (
        .GTHE4_COMMON_BGBYPASSB         (1'b1),
        .GTHE4_COMMON_BGMONITORENB      (1'b1),
        .GTHE4_COMMON_BGPDB             (1'b1),
        .GTHE4_COMMON_BGRCALOVRD        (5'b11111),
        .GTHE4_COMMON_BGRCALOVRDENB     (1'b1),
        .GTHE4_COMMON_DRPADDR           (16'b0000000000000000),
        .GTHE4_COMMON_DRPCLK            (1'b0),
        .GTHE4_COMMON_DRPDI             (16'b0000000000000000),
        .GTHE4_COMMON_DRPEN             (1'b0),
        .GTHE4_COMMON_DRPWE             (1'b0),
        .GTHE4_COMMON_GTGREFCLK0        (1'b0),
        .GTHE4_COMMON_GTGREFCLK1        (1'b0),
        .GTHE4_COMMON_GTNORTHREFCLK00   (1'b0),
        .GTHE4_COMMON_GTNORTHREFCLK01   (1'b0),
        .GTHE4_COMMON_GTNORTHREFCLK10   (1'b0),
        .GTHE4_COMMON_GTNORTHREFCLK11   (1'b0),
        .GTHE4_COMMON_GTREFCLK00        (gtrefclk00_int [f_ub_cm( 1,(4*cm)+3) : f_lb_cm( 1,4*cm)]),
        .GTHE4_COMMON_GTREFCLK01        (gtrefclk01_int [f_ub_cm( 1,(4*cm)+3) : f_lb_cm( 1,4*cm)]),
        .GTHE4_COMMON_GTREFCLK10        (1'b0),
        .GTHE4_COMMON_GTREFCLK11        (1'b0),
        .GTHE4_COMMON_GTSOUTHREFCLK00   (1'b0),
        .GTHE4_COMMON_GTSOUTHREFCLK01   (1'b0),
        .GTHE4_COMMON_GTSOUTHREFCLK10   (1'b0),
        .GTHE4_COMMON_GTSOUTHREFCLK11   (1'b0),
        .GTHE4_COMMON_PCIERATEQPLL0     (3'b000),
        .GTHE4_COMMON_PCIERATEQPLL1     (3'b000),
        .GTHE4_COMMON_PMARSVD0          (8'b00000000),
        .GTHE4_COMMON_PMARSVD1          (8'b00000000),
        .GTHE4_COMMON_QPLL0CLKRSVD0     (1'b0),
        .GTHE4_COMMON_QPLL0CLKRSVD1     (1'b0),
        .GTHE4_COMMON_QPLL0FBDIV        (8'b00000000),
        .GTHE4_COMMON_QPLL0LOCKDETCLK   (1'b0),
        .GTHE4_COMMON_QPLL0LOCKEN       (1'b1),
        .GTHE4_COMMON_QPLL0PD           (1'b0),
        .GTHE4_COMMON_QPLL0REFCLKSEL    (3'b001),
        .GTHE4_COMMON_QPLL0RESET        (qpll0reset_int [f_ub_cm( 1,(4*cm)+3) : f_lb_cm( 1,4*cm)]),
        .GTHE4_COMMON_QPLL1CLKRSVD0     (1'b0),
        .GTHE4_COMMON_QPLL1CLKRSVD1     (1'b0),
        .GTHE4_COMMON_QPLL1FBDIV        (8'b00000000),
        .GTHE4_COMMON_QPLL1LOCKDETCLK   (1'b0),
        .GTHE4_COMMON_QPLL1LOCKEN       (1'b1),
        .GTHE4_COMMON_QPLL1PD           (1'b0),
        .GTHE4_COMMON_QPLL1REFCLKSEL    (3'b001),
        .GTHE4_COMMON_QPLL1RESET        (qpll1reset_int [f_ub_cm( 1,(4*cm)+3) : f_lb_cm( 1,4*cm)]),
        .GTHE4_COMMON_QPLLRSVD1         (8'b00000000),
        .GTHE4_COMMON_QPLLRSVD2         (5'b00000),
        .GTHE4_COMMON_QPLLRSVD3         (5'b00000),
        .GTHE4_COMMON_QPLLRSVD4         (8'b00000000),
        .GTHE4_COMMON_RCALENB           (1'b1),
        .GTHE4_COMMON_SDM0DATA          (25'b0101011100001110101001110),
        .GTHE4_COMMON_SDM0RESET         (1'b0),
        .GTHE4_COMMON_SDM0TOGGLE        (1'b0),
        .GTHE4_COMMON_SDM0WIDTH         (2'b00),
        .GTHE4_COMMON_SDM1DATA          (25'b0000000000000000000000000),
        .GTHE4_COMMON_SDM1RESET         (1'b0),
        .GTHE4_COMMON_SDM1TOGGLE        (1'b0),
        .GTHE4_COMMON_SDM1WIDTH         (2'b00),
        .GTHE4_COMMON_TCONGPI           (10'b0000000000),
        .GTHE4_COMMON_TCONPOWERUP       (1'b0),
        .GTHE4_COMMON_TCONRESET         (2'b00),
        .GTHE4_COMMON_TCONRSVDIN1       (2'b00),
        .GTHE4_COMMON_DRPDO             (),
        .GTHE4_COMMON_DRPRDY            (),
        .GTHE4_COMMON_PMARSVDOUT0       (),
        .GTHE4_COMMON_PMARSVDOUT1       (),
        .GTHE4_COMMON_QPLL0FBCLKLOST    (),
        .GTHE4_COMMON_QPLL0LOCK         (qpll0lock_int      [f_ub_cm( 1,(4*cm)+3) : f_lb_cm( 1,4*cm)]),
        .GTHE4_COMMON_QPLL0OUTCLK       (qpll0outclk_out    [f_ub_cm( 1,(4*cm)+3) : f_lb_cm( 1,4*cm)]),
        .GTHE4_COMMON_QPLL0OUTREFCLK    (qpll0outrefclk_out [f_ub_cm( 1,(4*cm)+3) : f_lb_cm( 1,4*cm)]),
        .GTHE4_COMMON_QPLL0REFCLKLOST   (),
        .GTHE4_COMMON_QPLL1FBCLKLOST    (),
        .GTHE4_COMMON_QPLL1LOCK         (qpll1lock_int      [f_ub_cm( 1,(4*cm)+3) : f_lb_cm( 1,4*cm)]),
        .GTHE4_COMMON_QPLL1OUTCLK       (qpll1outclk_out    [f_ub_cm( 1,(4*cm)+3) : f_lb_cm( 1,4*cm)]),
        .GTHE4_COMMON_QPLL1OUTREFCLK    (qpll1outrefclk_out [f_ub_cm( 1,(4*cm)+3) : f_lb_cm( 1,4*cm)]),
        .GTHE4_COMMON_QPLL1REFCLKLOST   (),
        .GTHE4_COMMON_QPLLDMONITOR0     (),
        .GTHE4_COMMON_QPLLDMONITOR1     (),
        .GTHE4_COMMON_REFCLKOUTMONITOR0 (),
        .GTHE4_COMMON_REFCLKOUTMONITOR1 (),
        .GTHE4_COMMON_RXRECCLK0SEL      (),
        .GTHE4_COMMON_RXRECCLK1SEL      (),
        .GTHE4_COMMON_SDM0FINALOUT      (),
        .GTHE4_COMMON_SDM0TESTDATA      (),
        .GTHE4_COMMON_SDM1FINALOUT      (),
        .GTHE4_COMMON_SDM1TESTDATA      (),
        .GTHE4_COMMON_TCONGPO           (),
        .GTHE4_COMMON_TCONRSVDOUT0      ()
      );

    end
  end
  endgenerate


  // ===================================================================================================================
  // CORE INSTANCE
  // ===================================================================================================================

  // Instantiate the core, mapping its enabled ports to example design ports and helper blocks as appropriate
  gtwizard_ultrascale_qpll gtwizard_ultrascale_qpll_inst (
    .gthrxn_in                               (gthrxn_in)
   ,.gthrxp_in                               (gthrxp_in)
   ,.gthtxn_out                              (gthtxn_out)
   ,.gthtxp_out                              (gthtxp_out)
   ,.gtwiz_userclk_tx_active_in              (gtwiz_userclk_tx_active_out)
   ,.gtwiz_userclk_rx_active_in              (gtwiz_userclk_rx_active_out)
   ,.gtwiz_buffbypass_tx_reset_in            (gtwiz_buffbypass_tx_reset_in)
   ,.gtwiz_buffbypass_tx_start_user_in       (gtwiz_buffbypass_tx_start_user_in)
   ,.gtwiz_buffbypass_tx_done_out            (gtwiz_buffbypass_tx_done_out)
   ,.gtwiz_buffbypass_tx_error_out           (gtwiz_buffbypass_tx_error_out)
   ,.gtwiz_buffbypass_rx_reset_in            (gtwiz_buffbypass_rx_reset_in)
   ,.gtwiz_buffbypass_rx_start_user_in       (gtwiz_buffbypass_rx_start_user_in)
   ,.gtwiz_buffbypass_rx_done_out            (gtwiz_buffbypass_rx_done_out)
   ,.gtwiz_buffbypass_rx_error_out           (gtwiz_buffbypass_rx_error_out)
   ,.gtwiz_reset_tx_done_in                  (gtwiz_reset_tx_done_out)
   ,.gtwiz_reset_rx_done_in                  (gtwiz_reset_rx_done_out)
   ,.gtwiz_userdata_tx_in                    (gtwiz_userdata_tx_in)
   ,.gtwiz_userdata_rx_out                   (gtwiz_userdata_rx_out)
   ,.gtrxreset_in                            (gtrxreset_int)
   ,.gttxreset_in                            (gttxreset_int)
   ,.qpll0clk_in                             (qpll0clk_int)
   ,.qpll0refclk_in                          (qpll0refclk_int)
   ,.qpll1clk_in                             (qpll1clk_int)
   ,.qpll1refclk_in                          (qpll1refclk_int)
   ,.rx8b10ben_in                            (rx8b10ben_in)
   ,.rxcommadeten_in                         (rxcommadeten_in)
   ,.rxmcommaalignen_in                      (rxmcommaalignen_in)
   ,.rxpcommaalignen_in                      (rxpcommaalignen_in)
   ,.rxprogdivreset_in                       (rxprogdivreset_int)
   ,.rxslide_in                              (rxslide_in)
   ,.rxuserrdy_in                            (rxuserrdy_int)
   ,.rxusrclk_in                             (rxusrclk_int)
   ,.rxusrclk2_in                            (rxusrclk2_int)
   ,.tx8b10ben_in                            (tx8b10ben_in)
   ,.txctrl0_in                              (txctrl0_int)
   ,.txctrl1_in                              (txctrl1_int)
   ,.txctrl2_in                              (txctrl2_in)
   ,.txprogdivreset_in                       (txprogdivreset_int)
   ,.txuserrdy_in                            (txuserrdy_int)
   ,.txusrclk_in                             (txusrclk_int)
   ,.txusrclk2_in                            (txusrclk2_int)
   ,.gtpowergood_out                         (gtpowergood_int)
   ,.rxbyteisaligned_out                     (rxbyteisaligned_out)
   ,.rxbyterealign_out                       (rxbyterealign_out)
   ,.rxcdrlock_out                           (rxcdrlock_int)
   ,.rxcommadet_out                          (rxcommadet_out)
   ,.rxctrl0_out                             (rxctrl0_int)
   ,.rxctrl1_out                             (rxctrl1_int)
   ,.rxctrl2_out                             (rxctrl2_out)
   ,.rxctrl3_out                             (rxctrl3_out)
   ,.rxoutclk_out                            (rxoutclk_int)
   ,.rxpmaresetdone_out                      (rxpmaresetdone_out)
   ,.rxresetdone_out                         (rxresetdone_int)
   ,.txoutclk_out                            (txoutclk_int)
   ,.txpmaresetdone_out                      (txpmaresetdone_out)
   ,.txprgdivresetdone_out                   (txprgdivresetdone_out)
   ,.txresetdone_out                         (txresetdone_int)
);

endmodule
