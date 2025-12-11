###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
# Riviera run script
vsim -L unisim -L secureip work.main +access +r +access +w_nets -ieee_nowarn 

do ../wave_ci.do
run 40000us
wave zoomfull
radix -hexadecimal
