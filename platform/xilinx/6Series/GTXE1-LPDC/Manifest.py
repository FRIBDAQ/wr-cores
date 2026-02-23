###############################################################################
## SPDX-FileCopyrightText: 2026 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
if (syn_device[0:4].upper()=="XC6V"): # Virtex6
    files = ["../../common/lpdc_mdio_regs.vhd",
             "gtx_comma_detect_lp.vhd",
             "gtx_tx_reset_lp.vhd",
             "whiterabbitgtx_wrapper_gtx_lp.vhd",
             "wr_gtx_phy_virtex6_lp.vhd"
            ]

