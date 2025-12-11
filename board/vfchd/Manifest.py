###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
files = [
    "wr_vfchd_pkg.vhd",
    "xwrc_board_vfchd.vhd",
    "wrc_board_vfchd.vhd",
    "sfp_i2c_adapter.vhd",
]

modules = {
    "local" : [
        "../common",
    ]
}
