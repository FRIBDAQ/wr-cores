###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
action= "simulation"
target= "xilinx"
syn_device="xc6slx45t"
sim_tool="riviera"
top_module="main"

vcom_opt="-relax -packagevhdlsv"

include_dirs = [ "../" ]

modules = {
    "local" : [ "../" ]
}

files = [ "main.sv" ]
