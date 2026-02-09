###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
modules = {"local" : [""]}
files   = [ "wr_xilinx_pkg.vhd"]

if (syn_device[0:3].upper()=="XC7"):         # Artix7, Kintex7, Virtex7 and Zynq-7000
	modules["local"] += ["7Series"]
	files            += ["xwrc_platform_vivado.vhd"]

elif ((syn_device[0:2].upper()=="XC" and syn_device[3].upper()=="U") # US, US+
	  or (syn_device[0:5].upper()=="XCK26")):                        # and Kria26  
	modules["local"] += ["UltraScale","UltraScalePlus"]
	files            += ["xwrc_platform_vivado.vhd" ]

elif (syn_device[0:4].upper()=="XC5V"):      # Virtex5
	modules["local"] += ["Virtex5"]
	files            += ["xwrc_platform_ise.vhd" ]

elif (syn_device[0:4].upper()=="XC6S" 
	  or syn_device[0:4].upper()=="XC6V"):   # Spartan6 and Virtex6
	modules["local"] += ["6Series"]
	files            += ["xwrc_platform_ise.vhd" ]
