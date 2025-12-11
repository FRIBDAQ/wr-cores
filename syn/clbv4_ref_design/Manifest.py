###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
board  = "clbv4" 
target = "xilinx"
action = "synthesis"

syn_device = "xc7k160t"
syn_grade = "-2"
syn_package = "fbg676"

syn_top = "clbv4_wr_ref_top"
syn_project = "clbv4_wr_ref.xpr"

syn_tool = "vivado"

modules = { "local" : "../../top/clbv4_ref_design/"}
