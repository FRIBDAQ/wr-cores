#!/bin/bash
##-----------------------------------------------------------------------------
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
##-----------------------------------------------------------------------------

wbgen2 -C softpll_regs.h -V spll_wb_slave.vhd -K ../../sim/softpll_regs_ng.vh --hstyle record --cstyle struct -p spll_wbgen2_pkg.vhd spll_wb_slave.wb
