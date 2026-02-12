###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
if (syn_device[0:4].upper()=="XCZU"):  #Zynq Ultrascale+
  files = ["oserdes_8_to_1_ultrascale.vhd", "xoserdes_8_to_1_ultrascale.vhd"]
