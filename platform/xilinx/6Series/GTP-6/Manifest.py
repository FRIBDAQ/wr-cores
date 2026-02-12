###############################################################################
## SPDX-FileCopyrightText: 2026 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
if (syn_device[0:4].upper()=="XC6S"): # Spartan6
     files = ["wr_gtp_phy_spartan6.vhd",
              "whiterabbitgtp_wrapper_tile_spartan6.vhd",
              "../../common/gtp_phase_align.vhd",
              "../../common/gtp_bitslide.vhd"
             ]
