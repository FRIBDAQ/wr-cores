###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
action = "simulation"
target = "xilinx"
syn_device = "xc6slx45t"
syn_grade = "-3"
syn_package = "fgg484"
#sim_tool = "modelsim"
sim_tool = "riviera"
top_module = "main"

include_dirs = [ "../../sim" ]

files = [ "main.sv" ]

modules = { "local" : [ "../../",
                     "../../ip_cores/general-cores"
                     ]};
