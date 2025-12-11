###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
# Modelsim run script
vsim -L unisim -L secureip work.main -voptargs="+acc" 
set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do ../wave.do
run 40000us
wave zoomfull
radix -hex
