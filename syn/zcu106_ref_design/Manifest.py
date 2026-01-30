###############################################################################
## SPDX-FileCopyrightText: 2026 Missing Link Electronics(missinglinkelectronics.com)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
board  = "zcu10x"
target = "xilinx"
action = "synthesis"

syn_device = "xczu7ev"
syn_grade = "-2-e"
syn_package = "-ffvc1156"

syn_top = "zcu10x_ref_top"
syn_project = "zcu10x_ref_top"
syn_tool = "vivado"

files = [
    "zcu106_ref_design.xdc",
]

modules = {
    "local" : [
        "../../top/zcu10x_ref_design/",
    ],
}

