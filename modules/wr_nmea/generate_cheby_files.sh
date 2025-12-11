#!/bin/bash
##-----------------------------------------------------------------------------
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
##-----------------------------------------------------------------------------

cheby -i nmea_master_regs.cheby --gen-hdl nmea_master_regs.vhd
cheby -i nmea_master_regs.cheby --gen-c nmea_master.h
