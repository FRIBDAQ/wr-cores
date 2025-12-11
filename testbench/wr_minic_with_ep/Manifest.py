###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
action = "simulation"
files = "main.sv"
#fetchto = "../../ip_cores"

vlog_opt="+incdir+../../sim"

modules ={"local" : ["../../ip_cores/general-cores",
                     "../../modules/wr_endpoint", 
                     "../../modules/wr_mini_nic" ] };
