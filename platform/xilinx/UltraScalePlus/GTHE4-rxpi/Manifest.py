###############################################################################
## SPDX-FileCopyrightText: 2026 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################

if (syn_device[0:4].upper()=="XCZU" or  # Zynq Ultrascale GTH
      syn_device[0:5].upper()=="XCK26"):  # Kria K26
    files = [
        #"gthe4_sdm.vhd",
        "rxpi_gthe4_map.vhd",
        "xwrc_gthe4_rxpi.vhd",
    ]

