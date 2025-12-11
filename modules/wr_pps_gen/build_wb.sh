#!/bin/bash
##-----------------------------------------------------------------------------
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
##-----------------------------------------------------------------------------

mkdir -p doc
wbgen2 -D ./doc/pps_gen.html -V pps_gen_wb.vhd -C pps_gen_regs.h --cstyle struct --lang vhdl -K ../../sim/pps_gen_regs.v pps_gen_wb.wb
