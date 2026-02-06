###############################################################################
## SPDX-FileCopyrightText: 2026 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
if (syn_device[0:4].upper()=="XC7A" or # Family 7 GTP (Artix7)
         syn_device.upper()=="XC7Z015"):
     files = ["wr_gtp_phy_family7.vhd",
              "whiterabbit_gtpe2_channel_wrapper.vhd",
              "whiterabbit_gtpe2_channel_wrapper_gt.vhd",
              "whiterabbit_gtpe2_channel_wrapper_gtrxreset_seq.vhd",
              "../../common/gtp_bitslide.vhd"
             ]
