###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
if (syn_device[0:4].upper()=="XC7K" or syn_device[0:4].upper()=="XC7A"):    # Kintex7, Artix7
  files = ["oserdes_8_to_1_7series.vhd", "xoserdes_8_to_1_7series.vhd"]
