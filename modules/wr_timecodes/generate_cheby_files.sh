#!/bin/bash
##-----------------------------------------------------------------------------
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
##-----------------------------------------------------------------------------

cheby -i timecode_regs.cheby --gen-hdl timecode_regs.vhd
cheby -i timecode_regs.cheby --gen-c timecode_regs.h
cheby -i timecode_regs.cheby --consts-style=vhdl --gen-consts timecode_consts.vhd 
