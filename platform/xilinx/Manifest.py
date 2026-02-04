###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
if (syn_device[0:4].upper()=="XC7A" or syn_device[0:4].upper()=="XC7K"):     #Artix7 and Kintex7
	modules = {"local" : ["common","wr_gtp_phy","7Series"]}
	files = ["wr_xilinx_pkg.vhd", "xwrc_platform_vivado.vhd"]
elif (syn_device[0:4].upper()=="XCZU"):                                      #Zynq US+
	modules = {"local" : ["common","wr_gtp_phy","UltraScalePlus"]}
	files = [ "wr_xilinx_pkg.vhd", "xwrc_platform_vivado.vhd" ]
elif (syn_device[0:4].upper()=="XC5V"):                                      # Virtex5
	modules = {"local" : ["common","wr_gtp_phy","Virtex5"]}
	files = [ "wr_xilinx_pkg.vhd", "xwrc_platform_xilinx.vhd" ]
elif (syn_device[0:4].upper()=="XC6S" or syn_device[0:4].upper()=="XC6V"):   # Spartan6 and Virtex6
	modules = {"local" : ["common","wr_gtp_phy","6Series"]}
	files = [ "wr_xilinx_pkg.vhd", "xwrc_platform_xilinx.vhd" ]
else
	modules = {"local" : ["common","wr_gtp_phy"]}
	files = [ "wr_xilinx_pkg.vhd", "xwrc_platform_vivado.vhd" ]
