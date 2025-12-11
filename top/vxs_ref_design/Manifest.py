###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
fetchto = "../../ip_cores"

files = [
    "vxs_wr_ref_top.vhd",
    "vxs_wr_ref_top.ucf"
]

modules = {
    "local" : [
        "../../",
        "../../board/vxs",
    ],
    "git" : [
        "git://gitlab.com/ohwr/hdl-core-lib/general-cores.git",
        "git://gitlab.com/ohwr/hdl-core-lib/gn4124-core.git",
        "git://gitlab.com/ohwr/hdl-core-lib/etherbone-core.git",
    ],
}
