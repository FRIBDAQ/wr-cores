###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
action= "simulation"
target= "xilinx"
syn_device="xc6slx45t"
sim_tool="modelsim"
top_module="main"

vcom_opt="-mixedsvvh"

include_dirs = [ "../" ]

modules = {
    "local" : [ "../" ]
}

files = [ "main.sv" ]
