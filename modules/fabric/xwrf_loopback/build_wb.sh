#!/bin/bash
##-----------------------------------------------------------------------------
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
##-----------------------------------------------------------------------------

mkdir -p doc
wbgen2 -D ./doc/xwrf_loopback.html -C lbk_regs.h -p lbk_pkg.vhd -H record -V lbk_wishbone_controller.vhd  --cstyle struct --lang vhdl -K ../../sim/lbk_regs.v lbk_wishbone.wb
