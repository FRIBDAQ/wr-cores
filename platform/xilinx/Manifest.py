###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
modules = {"local" : ["wr_gtp_phy"]}
files   = [ "wr_xilinx_pkg.vhd"]

if (syn_device[0:4].upper()=="XC7A" or syn_device[0:4].upper()=="XC7K"):     #Artix7 and Kintex7
	modules["local"] += ["7Series"]
	files            += ["xwrc_platform_vivado.vhd"]

elif (syn_device[0:4].upper()=="XCZU"):                                      #Zynq US+
	modules["local"] += ["UltraScalePlus"]
	files            += ["xwrc_platform_vivado.vhd" ]

elif (syn_device[0:4].upper()=="XC5V"):                                      # Virtex5
	modules["local"] += ["Virtex5"]
	files            += ["xwrc_platform_xilinx.vhd" ]

elif (syn_device[0:4].upper()=="XC6S" or syn_device[0:4].upper()=="XC6V"):   # Spartan6 and Virtex6
	modules["local"] += ["6Series"]
	files            += ["xwrc_platform_xilinx.vhd" ]
