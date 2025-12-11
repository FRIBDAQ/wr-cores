###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
files = [
    "wr_pxie_fmc_pkg.vhd",
    "wrc_board_pxie_fmc.vhd",
    "xwrc_board_pxie_fmc.vhd",
]

modules = {
    "local" : [
        "../common",
    ]
}
