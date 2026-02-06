###############################################################################
## SPDX-FileCopyrightText: 2026 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
if (syn_device[0:4].upper()=="XC6V"): # Virtex6
    files = ["wr_gtx_phy_virtex6.vhd",
             "whiterabbitgtx_wrapper_gtx.vhd",
             "gtp_phase_align_virtex6.vhd",
             "gtx_reset.vhd",
             "../../common/gtp_bitslide.vhd",
            ]

