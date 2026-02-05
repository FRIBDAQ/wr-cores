###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
target = "xilinx"
action = "synthesis"

# XC5VLX50T-1FFG1136C
syn_device = "XC5VLX50T"
syn_grade = "-1"
syn_package = "FF1136"

syn_top = "vxs_wr_ref_top"
syn_project = "vxs_wr_ref.xise"

syn_tool = "ise"

syn_properties = [
       ["Other XST Command Line Options", "-use_new_parser yes"] ]

modules = { "local" : "../../top/vxs_ref_design/"}
