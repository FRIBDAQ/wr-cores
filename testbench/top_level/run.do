###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
vlog -sv main.sv +incdir+"." +incdir+gn4124_bfm +incdir+../../sim
make -f Makefile
vsim -t 1ps -L unisim work.main -voptargs="+acc"
set StdArithNoWarnings 1
set NumericStdNoWarnings 1
do wave.do
radix -hexadecimal
run 30us
wave zoomfull
radix -hexadecimal
