#!/bin/bash
##-----------------------------------------------------------------------------
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
##-----------------------------------------------------------------------------


cheby -i lpdc_mdio_regs.cheby --gen-hdl lpdc_mdio_regs.vhd
cheby -i lpdc_mdio_regs.cheby --consts-style sv --gen-consts ../../../../sim/regs/lpdc_mdio_regs.sv
cheby -i lpdc_mdio_regs.cheby --gen-c lpdc_mdio_regs.h
