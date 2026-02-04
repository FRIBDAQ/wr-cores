###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
if (syn_device[0:4].upper()=="XC6S"):    # Spartan6
	files = ["chipscope_spartan6_icon.ngc", "chipscope_spartan6_ila.ngc"]
