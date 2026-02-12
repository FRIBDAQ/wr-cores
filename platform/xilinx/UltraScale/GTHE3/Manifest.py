###############################################################################
## SPDX-FileCopyrightText: 2026 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
xilinx_ip_gthe3 = [
    "xilinx-ip/gtwizard_ultrascale_v1_6_gthe3_channel.v",
    "xilinx-ip/wr_gth_wrapper_gthe3_channel_wrapper.v",
    "xilinx-ip/wr_gth_wrapper_example_wrapper.v",
    "xilinx-ip/wr_gth_wrapper_example_bit_sync.v",
    "xilinx-ip/wr_gth_wrapper_example_wrapper_functions.v",
    "xilinx-ip/wr_gth_wrapper.v",
    "xilinx-ip/wr_gth_wrapper_gtwizard_top.v",
    "xilinx-ip/wr_gth_wrapper_example_top.v",
    "xilinx-ip/wr_gth_wrapper_gtwizard_gthe3.v",
    "xilinx-ip/wr_gth_wrapper_example_reset_sync.v",
    "xilinx-ip/wr_gth_wrapper_example_gtwiz_userclk_tx.v",
    "xilinx-ip/wr_gth_wrapper_example_init.v",
    "xilinx-ip/wr_gth_wrapper_example_gtwiz_userclk_rx.v"
];

# Common files between gthe3 and gthe4
gthe_ip_common = [
    "../../common/GTHE/gtwizard_ultrascale_v1_7_bit_sync.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gthe4_cpll_cal_tx.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gthe4_cpll_cal_rx.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gtwiz_reset.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gte4_drp_arb.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_reset_inv_sync.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gthe3_cpll_cal.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gthe4_cal_freqcnt.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gthe4_delay_powergood.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gthe4_cpll_cal.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gtwiz_userclk_rx.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gtwiz_userclk_tx.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_reset_sync.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gtwiz_userdata_rx.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gtwiz_userdata_tx.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gtwiz_buffbypass_rx.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gtwiz_buffbypass_tx.v",
    "../../common/GTHE/gtwizard_ultrascale_v1_7_gthe3_cal_freqcnt.v"
];

if (syn_device[0:4].upper()=="XCKU"): # Kintex Ultrascale GTH
     files = ["wr_gthe3_phy_family7.vhd",
              "wr_gthe3_phy_family7_xilinx_ip.vhd",
              "wr_gthe3_reset.vhd",
              "wr_gthe3_rx_buffer_bypass.vhd",
              "wr_gthe3_tx_buffer_bypass.vhd",
              "wr_gthe3_wrapper.vhd",
              "gc_reset_synchronizer.vhd",
              "../../common/gtp_bitslide.vhd"
             ]
     files.extend(xilinx_ip_gthe3)
     files.extend(gthe_ip_common);

