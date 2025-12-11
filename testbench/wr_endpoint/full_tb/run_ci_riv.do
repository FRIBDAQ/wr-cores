###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################

null make -f Makefile
vsim -L unisim -t 10fs work.main +access +r
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
do wave.do
radix -hexadecimal
run 250us
wave zoomfull
radix -hexadecimal

