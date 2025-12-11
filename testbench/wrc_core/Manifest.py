###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
fetchto = "../../ip_cores"
vlog_opt = "+incdir+../../sim"

files = [ "main.sv" ]

include_dirs = [ "../../sim",
        "../../ip_cores/general-cores/modules/wishbone/wb_lm32/src" ]

modules = { "local" : [ "../../",
			"../../modules/fabric",
			"../../ip_cores/general-cores",
			"../../ip_cores/etherbone-core",
                        "../../ip_cores/urv-core",
			"../../ip_cores/gn4124-core" ]}


