#!/bin/bash
##-----------------------------------------------------------------------------
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
##-----------------------------------------------------------------------------

cheby -i irig_slave_regs.cheby --gen-hdl irig_slave_regs.vhd
cheby -i irig_slave_regs.cheby --gen-c irig_slave_regs.h