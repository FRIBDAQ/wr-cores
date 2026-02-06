###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
files = [
        # "gtp_bitslide.vhd",
        ];


xilinx_ip_gthe4 = [
    "xilinx-ip/gthe4/gtwizard_ultrascale_2.v",
    "xilinx-ip/gthe4/gtwizard_ultrascale_2_gtwizard_top.v",
    "xilinx-ip/gthe4/gtwizard_ultrascale_2.xdc",
    "xilinx-ip/gthe4/gtwizard_ultrascale_2_gthe4_channel_wrapper.v",
    "xilinx-ip/gthe4/gtwizard_ultrascale_2_gtwizard_gthe4.v",
    "xilinx-ip/gthe4/gtwizard_ultrascale_2_ooc.xdc",
    "xilinx-ip/gthe4/gtwizard_ultrascale_v1_7_gthe4_channel.v"
];


xilinx_ip_gthe4_lp = [
    "xilinx-ip/gthe4_lp/gtwizard_ultrascale_2_gtwizard_top.v",
    "xilinx-ip/gthe4_lp/gtwizard_ultrascale_2.xdc",
    "xilinx-ip/gthe4_lp/gtwizard_ultrascale_2_gtwizard_gthe4.v",
    "xilinx-ip/gthe4_lp/gtwizard_ultrascale_v1_7_gthe4_channel.v"
];

xilinx_ip_gthe4_lp_125 = [
    "xilinx-ip/gthe4_lp/phy_ref_clk_125/gtwizard_ultrascale_2.v",
    "xilinx-ip/gthe4_lp/phy_ref_clk_125/gtwizard_ultrascale_2_gthe4_channel_wrapper.v",
    "xilinx-ip/gthe4_lp/phy_ref_clk_125/gtwizard_ultrascale_2_ooc.xdc",
];

xilinx_ip_gthe4_lp_100 = [
    "xilinx-ip/gthe4_lp/phy_ref_clk_100/gtwizard_ultrascale_2.v",
    "xilinx-ip/gthe4_lp/phy_ref_clk_100/gtwizard_ultrascale_2_gthe4_channel_wrapper.v",
    "xilinx-ip/gthe4_lp/phy_ref_clk_100/gtwizard_ultrascale_2_ooc.xdc",
];

xilinx_ip_gthe4_common_lp = [
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_bit_sync.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gte4_drp_arb.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gthe3_cal_freqcnt.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gthe3_cpll_cal.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gthe4_cal_freqcnt.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gthe4_cpll_cal.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gthe4_cpll_cal_rx.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gthe4_cpll_cal_tx.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gthe4_delay_powergood.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gtwiz_buffbypass_rx.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gtwiz_buffbypass_tx.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gtwiz_reset.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gtwiz_userclk_rx.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gtwiz_userclk_tx.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gtwiz_userdata_rx.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gtwiz_userdata_tx.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gtye4_cal_freqcnt.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gtye4_cpll_cal.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gtye4_cpll_cal_rx.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gtye4_cpll_cal_tx.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_gtye4_delay_powergood.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_reset_inv_sync.v",
    "xilinx-ip/gthe4_lp/common/gtwizard_ultrascale_v1_7_reset_sync.v",
];

if globals().get('wrcore_platform') is False:
    # No platform (avoid inclusion of xdc files)
    pass
elif (syn_device[0:4].upper()=="XCZU" or  # Zynq Ultrascale GTH
      syn_device[0:5].upper()=="XCK26"):  # Kria K26
    files.extend([
        "family7-gthe4/wr_gthe4_phy_family7_xilinx_ip.vhd",
        ]);
    files.extend( xilinx_ip_gthe4 );
    files.extend( xilinx_ip_common );
elif (syn_device[0:6].upper()=="XCAU10" or # Artix Ultrascale+ AU10P AU15P GTH
      syn_device[0:6].upper()=="XCAU15"):  # use Low Phase Drift implementation
    files.extend([
        "family7-gthe4-lp/wr_gthe4_phy_family7_lp.vhd",
        "family7-gtx-lp/gtx_comma_detect_lp.vhd",
        "common/lpdc_mdio_regs.vhd",
        ]);
    files.extend( xilinx_ip_gthe4_lp );             # Note that gthe4 depend on Vivado version
    files.extend( xilinx_ip_gthe4_common_lp );      # and instantiate its specific common files 
    # PHY reference clock defaults to 125 MHz; check if 100 MHz is defined
    try:
        if (phy_ref_clk=="100"):
            files.extend( xilinx_ip_gthe4_lp_100 );
        else:
            files.extend( xilinx_ip_gthe4_lp_125 ); # if phy_clk_ref exists but is other than "100"
    except:
        files.extend( xilinx_ip_gthe4_lp_125 );     # if phy_clk_ref does not exists
