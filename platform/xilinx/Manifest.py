###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
if (syn_device[0:4].upper()=="XC7A" or syn_device[0:4].upper()=="XC7K" or
        syn_device[0:4].upper()=="XCZU"):
	files = [ "wr_xilinx_pkg.vhd", "xwrc_platform_vivado.vhd", "wrc_dpram/wrc_platform_dpram_ultrascale.vhd" ]
else:
	files = [ "wr_xilinx_pkg.vhd", "xwrc_platform_xilinx.vhd" ]
modules = {"local" : ["wr_gtp_phy", "chipscope", "wrc_serdes"]}

#if (syn_device[0:4].upper()=="XCKU" or syn_device[0:4].upper()=="XC7U" ):
#	files += [ "wrc_dpram/wrc_platform_dpram_ultrascale.vhd" ]
