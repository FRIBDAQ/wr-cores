###############################################################################
## SPDX-FileCopyrightText: 2026 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
if (syn_device[0:4].upper()=="XC5V"): # Virtex5
     files = ["wr_gtp_phy_virtex5.vhd",
              "whiterabbit_gtp_wrapper_tile_virtex5.vhd",
              "v5_gtp_align_detect.vhd",
              "v5_gtp_comma_detect.vhd",
              "../../common/gtp_phase_align.vhd",
              "../../common/gtp_bitslide.vhd"
            ]
