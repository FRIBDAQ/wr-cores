###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################

# make -f Makefile > /dev/null 2>&1
vsim -L unisim work.main  

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do wave_ci.do
run 10us
wave zoomfull
radix -hex


