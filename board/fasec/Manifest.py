###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
files = [
    "wr_fasec_pkg.vhd",
    "xwrc_board_fasec.vhd",
    "wrc_board_fasec.vhd",
    "wrc_board_fasec_ip.xdc"
]

modules = {
    "local" : [
        "../common",
    ]
}
