#!/bin/bash
##-----------------------------------------------------------------------------
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
##-----------------------------------------------------------------------------

cheby -i wr_mini_nic_map.cheby --header=commit --gen-hdl > wr_mini_nic_map.vhd
