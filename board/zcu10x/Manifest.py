###############################################################################
## SPDX-FileCopyrightText: 2026 Missing Link Electronics(missinglinkelectronics.com)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
files = [
    "xwrc_board_zcu10x.vhd",
    "board_zcu10x_bus_wb.vhd",
    "../../platform/xilinx/wr_gtp_phy/xilinx-ip/gthe4/create-gth-sdm-eth.tcl",
    "../../platform/xilinx/wr_gtp_phy/xilinx-ip/gthe4/create-gth-sdm-dmtd.tcl",
]

modules = {
    "local" : [
        "../common",
    ]
}
