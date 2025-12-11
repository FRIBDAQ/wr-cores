###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
action= "simulation"
target= "xilinx"
syn_device="xc6slx45t"
#sim_tool="modelsim"
sim_tool="riviera"
top_module="main"
vcom_opt="-packagevhdlsv"
fetchto="../../../ip_cores"

include_dirs=["../../../sim"]

modules = { "local" : ["../../..",
                       "../../../modules/wr_streamers",
                       "../../../ip_cores/general-cores"]}
					  
files = ["main.sv"]

