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
// This example design top module instantiates the example design wrapper; slices vectored ports for per-channel
// assignment; and instantiates example resources such as buffers, pattern generators, and pattern checkers for core
// demonstration purposes
// =====================================================================================================================

module gtwizard_ultrascale_qpll_example_top
 (

  // GT reference clock
  input wire  gt_refclk0_i,
  input wire  gt_refclk1_i,

  // Serial data ports for transceiver channel 0
  input wire  pad_rxn_i,
  input wire  pad_rxp_i,
  output wire pad_txn_o,
  output wire pad_txp_o,

  // User-provided ports for reset helper block(s)
  input wire  hb_gtwiz_reset_clk_freerun_in,
  input wire  hb_gtwiz_reset_all_in,

  output wire serdes_ready_out,
  output      reset_all_o,

  output      userclk_tx_reset_o,
  output      userclk_tx_active_o,
  output      userclk_rx_reset_o,
  output      userclk_rx_active_o,
  output      buffbypass_tx_reset_o,
  output      buffbypass_tx_done_o,
  output      buffbypass_tx_error_o,
  output      buffbypass_rx_reset_o,
  output      buffbypass_rx_done_o,
  output      buffbypass_rx_error_o,

  output      reset_tx_pll_and_datapath_o,
  output      reset_tx_datapath_o,
  output      reset_rx_pll_and_datapath_o,
  output      reset_rx_datapath_o,
  output      reset_rx_cdr_stable_o,
  output      reset_tx_done_o,
  output      reset_rx_done_o,

  output      rx_pma_reset_done_o,
  output      tx_pma_reset_done_o,
  output      tx_prgdiv_reset_done_o,
  output      gt_powergood_o,
  output      qpll0_lock_o,
  output      qpll1_lock_o
);


  // ===================================================================================================================
  // PER-CHANNEL SIGNAL ASSIGNMENTS
  // ===================================================================================================================

  // The core and example design wrapper vectorize ports across all enabled transceiver channel and common instances for
  // simplicity and compactness. This example design top module assigns slices of each vector to individual, per-channel
  // signal vectors for use if desired. Signals which connect to helper blocks are prefixed "hb#", signals which connect
  // to transceiver common primitives are prefixed "cm#", and signals which connect to transceiver channel primitives
  // are prefixed "ch#", where "#" is the sequential resource number.

  //--------------------------------------------------------------------------------------------------------------------
  wire [0:0] gtwiz_userclk_tx_srcclk_int;
  wire [0:0] gtwiz_userclk_tx_usrclk_int;
  wire [0:0] gtwiz_userclk_tx_usrclk2_int;
  wire [0:0] gtwiz_userclk_tx_active_out;
  wire [0:0] gtwiz_userclk_rx_reset_int;
  wire [0:0] gtwiz_userclk_rx_srcclk_int;
  wire [0:0] gtwiz_userclk_rx_usrclk_int;
  wire [0:0] gtwiz_userclk_rx_usrclk2_int;
  wire [0:0] gtwiz_userclk_rx_active_out;
  wire [0:0] gtwiz_buffbypass_tx_reset_int;
  wire [0:0] gtwiz_buffbypass_tx_start_user_int = 1'b0;
  wire [0:0] gtwiz_buffbypass_tx_done_out;
  wire [0:0] gtwiz_buffbypass_tx_error_int;
  wire [0:0] gtwiz_buffbypass_rx_reset_int;
  wire [0:0] gtwiz_buffbypass_rx_start_user_int;
  wire [0:0] gtwiz_buffbypass_rx_done_int;
  wire [0:0] gtwiz_buffbypass_rx_error_int; // unused
  wire [0:0] gtwiz_reset_tx_pll_and_datapath_int = 1'b0;
  wire [0:0] gtwiz_reset_tx_datapath_int = 1'b0;
  wire [0:0] gtwiz_reset_rx_cdr_stable_int; // unused
  wire [0:0] gtwiz_reset_tx_done_int;
  wire [0:0] gtwiz_reset_rx_done_int;

  wire [15:0] gtwiz_userdata_tx_int; // Data
  wire [15:0] gtwiz_userdata_rx_int; // Data

   wire       qpll0reset_int = 1'b0;
   wire       qpll1reset_int = 1'b0;
   wire       qpll0lock_int;
   wire       qpll1lock_int;
   wire       qpll0outclk_int;
   wire       qpll1outclk_int;
   wire       qpll0outrefclk_int;
   wire       qpll1outrefclk_int;

  wire [0:0] rx8b10ben_int = 1'b1;
  wire [0:0] rxcommadeten_int = 1'b1;
  wire [0:0] rxmcommaalignen_int = 1'b1;
  wire [0:0] rxpcommaalignen_int = 1'b1;
  wire [0:0] rxslide_int = 1'b0;
  wire [0:0] tx8b10ben_int = 1'b1;

  wire [15:0] txctrl0_int;
  wire [15:0] txctrl1_int;
  wire [7:0] txctrl2_int;

  wire [0:0] gtpowergood_int; // unused
  wire [0:0] rxbyteisaligned_int; // unused
  wire [0:0] rxbyterealign_int; // unused
  wire [0:0] rxcommadet_int; // unused

  wire [15:0] rxctrl0_int;
  wire [15:0] rxctrl1_int;
  wire [7:0] rxctrl2_int;
  wire [7:0] rxctrl3_int;

  wire [0:0] rxpmaresetdone_int;
  wire [0:0] txpmaresetdone_int;
  wire [0:0] txprgdivresetdone_int;


   wire      gtwiz_buffbypass_tx_reset_pre = ~gtwiz_userclk_tx_active_out;

  // The TX buffer bypass controller helper block should be held in reset until the TX user clocking network helper
  // block which drives it is active
  (* DONT_TOUCH = "TRUE" *)
  gtwizard_ultrascale_qpll_example_reset_synchronizer reset_synchronizer_gtwiz_buffbypass_tx_reset_inst (
    .clk_in  (gtwiz_userclk_tx_usrclk2_int),
    .rst_in  (gtwiz_buffbypass_tx_reset_pre),
    .rst_out (gtwiz_buffbypass_tx_reset_int)
  );

   wire      gtwiz_buffbypass_rx_reset_pre = ~gtwiz_userclk_rx_active_out || ~gtwiz_buffbypass_tx_done_out;

  // The RX buffer bypass controller helper block should be held in reset until the RX user clocking network helper
  // block which drives it is active and the TX buffer bypass sequence has completed for this loopback configuration
  (* DONT_TOUCH = "TRUE" *)
  gtwizard_ultrascale_qpll_example_reset_synchronizer reset_synchronizer_gtwiz_buffbypass_rx_reset_inst (
    .clk_in  (gtwiz_userclk_rx_usrclk2_int),
    .rst_in  (gtwiz_buffbypass_rx_reset_pre),
    .rst_out (gtwiz_buffbypass_rx_reset_int)
  );

   assign hb_gtwiz_reset_all_int = hb_gtwiz_reset_all_in;


   // The TX user clocking helper block should be held in reset until the clock source of that block is known to be
  // stable. The following assignment is an example of how that stability can be determined, based on the selected TX
  // user clock source. Replace the assignment with the appropriate signal or logic to achieve that behavior as needed.
   wire gtwiz_userclk_tx_reset_int;
  assign gtwiz_userclk_tx_reset_int = ~(&txprgdivresetdone_int && &txpmaresetdone_int);

  // The RX user clocking helper block should be held in reset until the clock source of that block is known to be
  // stable. The following assignment is an example of how that stability can be determined, based on the selected RX
  // user clock source. Replace the assignment with the appropriate signal or logic to achieve that behavior as needed.
  assign gtwiz_userclk_rx_reset_int = ~(&rxpmaresetdone_int);


  // ===================================================================================================================
  // USER CLOCKING RESETS
  // ===================================================================================================================


  // ===================================================================================================================
  // BUFFER BYPASS CONTROLLER RESETS
  // ===================================================================================================================


   wire serdes_ready_a;

   assign serdes_ready_a = !(hb_gtwiz_reset_all_int || ~gtwiz_reset_rx_done_int || ~gtwiz_buffbypass_rx_done_int || ~gtwiz_buffbypass_tx_done_out);
		
   assign serdes_ready_out = serdes_ready_a;

   assign reset_all_o = hb_gtwiz_reset_all_int;

   assign userclk_tx_reset_o = gtwiz_userclk_tx_reset_int;
   assign userclk_tx_active_o = gtwiz_userclk_tx_active_out;
   assign userclk_rx_reset_o = gtwiz_userclk_rx_reset_int;
   assign userclk_rx_active_o = gtwiz_userclk_rx_active_out;
   assign buffbypass_tx_reset_o = gtwiz_buffbypass_tx_reset_int;
   assign buffbypass_tx_done_o = gtwiz_buffbypass_tx_done_out;
   assign buffbypass_tx_error_o = gtwiz_buffbypass_tx_error_int;
   assign buffbypass_rx_reset_o = gtwiz_buffbypass_rx_reset_int;
   assign buffbypass_rx_done_o = gtwiz_buffbypass_rx_done_int;
   assign buffbypass_rx_error_o = gtwiz_buffbypass_rx_error_int;

   assign reset_tx_pll_and_datapath_o = gtwiz_reset_tx_pll_and_datapath_int;
   assign reset_tx_datapath_o = gtwiz_reset_tx_datapath_int;
   assign reset_rx_pll_and_datapath_o = hb_gtwiz_reset_rx_pll_and_datapath_int;
   assign reset_rx_datapath_o = hb_gtwiz_reset_rx_datapath_int;
   assign reset_rx_cdr_stable_o = gtwiz_reset_rx_cdr_stable_int;
   assign reset_tx_done_o = gtwiz_reset_tx_done_int;
   assign reset_rx_done_o = gtwiz_reset_rx_done_int;

   assign rx_pma_reset_done_o = rxpmaresetdone_int;
   assign tx_pma_reset_done_o = txpmaresetdone_int;
   assign tx_prgdiv_reset_done_o = txprgdivresetdone_int;
   assign gt_powergood_o = gtpowergood_int;

   assign qpll0_lock_o = qpll0lock_int;
   assign qpll1_lock_o = qpll1lock_int;

  // ===================================================================================================================
  // INITIALIZATION
  // ===================================================================================================================

  // Declare the receiver reset signals that interface to the reset controller helper block. For this configuration,
  // which uses the same PLL type for transmitter and receiver, the "reset RX PLL and datapath" feature is not used.
  wire hb_gtwiz_reset_rx_pll_and_datapath_int = 1'b0;
   wire hb_gtwiz_reset_rx_datapath_int = 1'b0;


  // ===================================================================================================================
  // EXAMPLE WRAPPER INSTANCE
  // ===================================================================================================================

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
     .GTHE4_COMMON_GTREFCLK00        (gt_refclk0_i),
     .GTHE4_COMMON_GTREFCLK01        (gt_refclk1_i),
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
     .GTHE4_COMMON_QPLL0RESET        (qpll0reset_int),
     .GTHE4_COMMON_QPLL1CLKRSVD0     (1'b0),
     .GTHE4_COMMON_QPLL1CLKRSVD1     (1'b0),
     .GTHE4_COMMON_QPLL1FBDIV        (8'b00000000),
     .GTHE4_COMMON_QPLL1LOCKDETCLK   (1'b0),
     .GTHE4_COMMON_QPLL1LOCKEN       (1'b1),
     .GTHE4_COMMON_QPLL1PD           (1'b0),
     .GTHE4_COMMON_QPLL1REFCLKSEL    (3'b001),
     .GTHE4_COMMON_QPLL1RESET        (qpll1reset_int),
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
     .GTHE4_COMMON_QPLL0LOCK         (qpll0lock_int),
     .GTHE4_COMMON_QPLL0OUTCLK       (qpll0outclk_int),
     .GTHE4_COMMON_QPLL0OUTREFCLK    (qpll0outrefclk_int),
     .GTHE4_COMMON_QPLL0REFCLKLOST   (),
     .GTHE4_COMMON_QPLL1FBCLKLOST    (),
     .GTHE4_COMMON_QPLL1LOCK         (qpll1lock_int),
     .GTHE4_COMMON_QPLL1OUTCLK       (qpll1outclk_int),
     .GTHE4_COMMON_QPLL1OUTREFCLK    (qpll1outrefclk_int),
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

  // Instantiate the example design wrapper, mapping its enabled ports to per-channel internal signals and example
  // resources as appropriate
  gtwizard_ultrascale_qpll_example_wrapper example_wrapper_inst (
    .gthrxn_in                               (pad_rxn_i)
   ,.gthrxp_in                               (pad_rxp_i)
   ,.gthtxn_out                              (pad_txn_o)
   ,.gthtxp_out                              (pad_txp_o)
   ,.gtwiz_userclk_tx_reset_in               (gtwiz_userclk_tx_reset_int)
   ,.gtwiz_userclk_tx_srcclk_out             (gtwiz_userclk_tx_srcclk_int)
   ,.gtwiz_userclk_tx_usrclk_out             (gtwiz_userclk_tx_usrclk_int)
   ,.gtwiz_userclk_tx_usrclk2_out            (gtwiz_userclk_tx_usrclk2_int)
   ,.gtwiz_userclk_tx_active_out             (gtwiz_userclk_tx_active_out)
   ,.gtwiz_userclk_rx_reset_in               (gtwiz_userclk_rx_reset_int)
   ,.gtwiz_userclk_rx_srcclk_out             (gtwiz_userclk_rx_srcclk_int)
   ,.gtwiz_userclk_rx_usrclk_out             (gtwiz_userclk_rx_usrclk_int)
   ,.gtwiz_userclk_rx_usrclk2_out            (gtwiz_userclk_rx_usrclk2_int)
   ,.gtwiz_userclk_rx_active_out             (gtwiz_userclk_rx_active_out)
   ,.gtwiz_buffbypass_tx_reset_in            (gtwiz_buffbypass_tx_reset_int)
   ,.gtwiz_buffbypass_tx_start_user_in       (gtwiz_buffbypass_tx_start_user_int)
   ,.gtwiz_buffbypass_tx_done_out            (gtwiz_buffbypass_tx_done_out)
   ,.gtwiz_buffbypass_tx_error_out           (gtwiz_buffbypass_tx_error_int)
   ,.gtwiz_buffbypass_rx_reset_in            (gtwiz_buffbypass_rx_reset_int)
   ,.gtwiz_buffbypass_rx_start_user_in       (gtwiz_buffbypass_rx_start_user_int)
   ,.gtwiz_buffbypass_rx_done_out            (gtwiz_buffbypass_rx_done_int)
   ,.gtwiz_buffbypass_rx_error_out           (gtwiz_buffbypass_rx_error_int)
   ,.gtwiz_reset_clk_freerun_in              (hb_gtwiz_reset_clk_freerun_in)
   ,.gtwiz_reset_all_in                      ({1{hb_gtwiz_reset_all_int}})
   ,.gtwiz_reset_tx_pll_and_datapath_in      (gtwiz_reset_tx_pll_and_datapath_int)
   ,.gtwiz_reset_tx_datapath_in              (gtwiz_reset_tx_datapath_int)
   ,.gtwiz_reset_rx_pll_and_datapath_in      (hb_gtwiz_reset_rx_pll_and_datapath_int)
   ,.gtwiz_reset_rx_datapath_in              (hb_gtwiz_reset_rx_datapath_int)
   ,.gtwiz_reset_rx_cdr_stable_out           (gtwiz_reset_rx_cdr_stable_int)
   ,.gtwiz_reset_tx_done_out                 (gtwiz_reset_tx_done_int)
   ,.gtwiz_reset_rx_done_out                 (gtwiz_reset_rx_done_int)
   ,.gtwiz_userdata_tx_in                    (gtwiz_userdata_tx_int)
   ,.gtwiz_userdata_rx_out                   (gtwiz_userdata_rx_int)
   ,.qpll0outclk_in                         (qpll0outclk_int)
   ,.qpll0outrefclk_in                      (qpll0outrefclk_int)
   ,.qpll0lock_in (qpll0lock_int)
   ,.qpll1outclk_in                         (qpll1outclk_int)
   ,.qpll1outrefclk_in                      (qpll1outrefclk_int)
   ,.qpll1lock_in (qpll1lock_int)
   ,.rx8b10ben_in                            (rx8b10ben_int)
   ,.rxcommadeten_in                         (rxcommadeten_int)
   ,.rxmcommaalignen_in                      (rxmcommaalignen_int)
   ,.rxpcommaalignen_in                      (rxpcommaalignen_int)
   ,.rxslide_in                              (rxslide_int)
   ,.tx8b10ben_in                            (tx8b10ben_int)
   ,.txctrl0_in                              (txctrl0_int)
   ,.txctrl1_in                              (txctrl1_int)
   ,.txctrl2_in                              (txctrl2_int)
   ,.gtpowergood_out                         (gtpowergood_int)
   ,.rxbyteisaligned_out                     (rxbyteisaligned_int)
   ,.rxbyterealign_out                       (rxbyterealign_int)
   ,.rxcommadet_out                          (rxcommadet_int)
   ,.rxctrl0_out                             (rxctrl0_int)
   ,.rxctrl1_out                             (rxctrl1_int)
   ,.rxctrl2_out                             (rxctrl2_int)
   ,.rxctrl3_out                             (rxctrl3_int)
   ,.rxpmaresetdone_out                      (rxpmaresetdone_int)
   ,.txpmaresetdone_out                      (txpmaresetdone_int)
   ,.txprgdivresetdone_out                   (txprgdivresetdone_int)
);


endmodule
