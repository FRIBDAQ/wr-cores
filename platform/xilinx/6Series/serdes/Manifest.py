###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
if (syn_device[0:4].upper()=="XC6S"):    # Spartan6
	files = ["oserdes_8_to_1_spartan6.vhd", "oserdes_4_to_1_spartan6.vhd", "xoserdes_4_to_1_spartan6.vhd"]
