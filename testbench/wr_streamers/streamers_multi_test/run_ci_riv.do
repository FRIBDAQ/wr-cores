###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
vsim -L unisim work.main +access +r -voptargs="+acc" -sv_seed random 
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
do wave_ci.do
run 20us
wave zoomfull
radix -hex
quit 


