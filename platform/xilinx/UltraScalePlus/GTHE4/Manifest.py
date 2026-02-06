###############################################################################
## SPDX-FileCopyrightText: 2026 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
xilinx_ip_gthe4 = [
    "xilinx-ip/gtwizard_ultrascale_2.v",
    "xilinx-ip/gtwizard_ultrascale_2_gtwizard_top.v",
    "xilinx-ip/gtwizard_ultrascale_2.xdc",
    "xilinx-ip/gtwizard_ultrascale_2_gthe4_channel_wrapper.v",
    "xilinx-ip/gtwizard_ultrascale_2_gtwizard_gthe4.v",
    "xilinx-ip/gtwizard_ultrascale_2_ooc.xdc",
    "xilinx-ip/gtwizard_ultrascale_v1_7_gthe4_channel.v"
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

if (syn_device[0:4].upper()=="XCZU" or  # Zynq Ultrascale GTH
      syn_device[0:5].upper()=="XCK26"):  # Kria K26
    files = ["wr_gthe4_phy_family7_xilinx_ip.vhd",
             "../../common/gtp_bitslide.vhd"
            ]
    files.extend(xilinx_ip_gthe4);
    files.extend(gthe_ip_common);