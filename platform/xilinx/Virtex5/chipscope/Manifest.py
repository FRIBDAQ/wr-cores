###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
if (syn_device[0:4].upper()=="XC5V"): # Virtex5
	files = [("chipscope_virtex5_icon.ngc", "chipscope_virtex5_icon"),
	          ("chipscope_virtex5_ila.ngc", "chipscope_virtex5_ila"),
	        ]
