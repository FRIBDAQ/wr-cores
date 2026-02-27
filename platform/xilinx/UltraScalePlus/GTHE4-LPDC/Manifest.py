###############################################################################
## SPDX-FileCopyrightText: 2026 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
xilinx_ip_gthe4_lp = [
    "xilinx-ip/gtwizard_ultrascale_2_gtwizard_top.v",
    "xilinx-ip/gtwizard_ultrascale_2.xdc",
    "xilinx-ip/gtwizard_ultrascale_2_gtwizard_gthe4.v",
    "xilinx-ip/gtwizard_ultrascale_v1_7_gthe4_channel.v"
];

xilinx_ip_gthe4_lp_125 = [
    "xilinx-ip/phy_ref_clk_125/gtwizard_ultrascale_2.v",
    "xilinx-ip/phy_ref_clk_125/gtwizard_ultrascale_2_gthe4_channel_wrapper.v",
    "xilinx-ip/phy_ref_clk_125/gtwizard_ultrascale_2_ooc.xdc",
];

xilinx_ip_gthe4_lp_100 = [
    "xilinx-ip/phy_ref_clk_100/gtwizard_ultrascale_2.v",
    "xilinx-ip/phy_ref_clk_100/gtwizard_ultrascale_2_gthe4_channel_wrapper.v",
    "xilinx-ip/phy_ref_clk_100/gtwizard_ultrascale_2_ooc.xdc",
];

gthe4_lpdc_ip_common = [
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_bit_sync.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gte4_drp_arb.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gthe3_cal_freqcnt.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gthe3_cpll_cal.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gthe4_cal_freqcnt.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gthe4_cpll_cal.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gthe4_cpll_cal_rx.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gthe4_cpll_cal_tx.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gthe4_delay_powergood.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gtwiz_buffbypass_rx.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gtwiz_buffbypass_tx.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gtwiz_reset.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gtwiz_userclk_rx.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gtwiz_userclk_tx.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gtwiz_userdata_rx.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gtwiz_userdata_tx.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gtye4_cal_freqcnt.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gtye4_cpll_cal.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gtye4_cpll_cal_rx.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gtye4_cpll_cal_tx.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_gtye4_delay_powergood.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_reset_inv_sync.v",
    "../../common/GTHE-LPDC/gtwizard_ultrascale_v1_7_reset_sync.v",
];

if (syn_device[0:6].upper()=="XCAU10" or # Artix Ultrascale+ AU10P AU15P GTH
      syn_device[0:6].upper()=="XCAU15"):  # use Low Phase Drift implementation
    files= ["wr_gthe4_phy_family7_lp.vhd",
            "../../7Series/GTXE2-LPDC/gtx_comma_detect_lp.vhd",
            "../../common/gtp_bitslide.vhd",
            "../../common/lpdc_mdio_regs.vhd",
           ]
    files.extend(xilinx_ip_gthe4_lp);             # Note that gthe4 depend on Vivado version
    files.extend(gthe4_lpdc_ip_common);      # and instantiate its specific common files 
    # PHY reference clock defaults to 125 MHz; check if 100 MHz is defined
    try:
        if (phy_ref_clk=="100"):
            files.extend(xilinx_ip_gthe4_lp_100);
        else:
            files.extend(xilinx_ip_gthe4_lp_125); # if phy_clk_ref exists but is other than "100"
    except:
        files.extend(xilinx_ip_gthe4_lp_125);     # if phy_clk_ref does not exists
