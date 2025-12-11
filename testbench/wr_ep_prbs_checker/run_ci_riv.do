###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
vsim -L unisim -t 10fs work.main -voptargs="+acc"
set StdArithNoWarnings 1
set NumericStdNoWarnings 1


radix -hexadecimal
run 1ms
wave zoomfull
radix -hexadecimal
