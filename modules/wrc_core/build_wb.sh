#!/bin/bash
##-----------------------------------------------------------------------------
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
##-----------------------------------------------------------------------------

mkdir -p doc
wbgen2 -D ./doc/wrc_syscon.html -p wrc_syscon_pkg.vhd -H record -V wrc_syscon_wb.vhd -C wrc_syscon_regs.h --cstyle struct --lang vhdl -K ../../sim/wrc_syscon_regs.vh wrc_syscon_wb.wb
