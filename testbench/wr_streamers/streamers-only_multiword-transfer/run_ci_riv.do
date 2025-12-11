###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
null make -f Makefile > /dev/null 2>&1 
vsim -L unisim work.main +access +r 

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

#do wave.do
run 1ms
wave zoomfull
radix -hex


