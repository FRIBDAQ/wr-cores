###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
# Modelsim run script for continuous integration (with return code)
# execute: vsim -c -do "run_ci.do"
vsim -L unisim -t 10fs work.main +access +r
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
do wave_ci.do
radix -hexadecimal
run 200ms
wave zoomfull
radix -hexadecimal
quit 

