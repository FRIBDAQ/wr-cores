###############################################################################
## SPDX-FileCopyrightText: 2026 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
if (syn_device[0:4].upper()=="XC7V"): # Family 7 GTH (other Virtex7 devices)
    files = ["wr_gth_phy_family7.vhd",
             "whiterabbit_gthe2_channel_wrapper_gt.vhd",
             "whiterabbit_gthe2_channel_wrapper_gtrxreset_seq.vhd",
             "whiterabbit_gthe2_channel_wrapper_sync_block.vhd" 
             "../../common/gtp_bitslide.vhd"
            ]