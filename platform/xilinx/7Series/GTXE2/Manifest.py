###############################################################################
## SPDX-FileCopyrightText: 2026 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
if (syn_device[0:4].upper()=="XC7K" or # Family 7 GTX (Kintex7 and Virtex7 585, 2000, X485 and ZYNQ Z030,Z035 Z045)
    syn_device[0:7].upper()=="XC7V585" or
    syn_device[0:8].upper()=="XC7V2000" or
    syn_device[0:8].upper()=="XC7VX485" or
    syn_device[0:6].upper()=="XC7Z03" or
    syn_device[0:7].upper()=="XC7Z045"):
		files = ["wr_gtx_phy_family7.vhd",
                 "whiterabbit_gtxe2_channel_wrapper_gt.vhd",
                 "../../common/gtp_bitslide.vhd"
                ]
