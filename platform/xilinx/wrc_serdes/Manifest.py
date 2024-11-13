if (syn_device[0:4].upper()=="XC6S"):    # Spartan6
	files = ["oserdes_8_to_1_spartan6.vhd"]
elif (syn_device[0:4].upper()=="XC7K" or syn_device[0:4].upper()=="XC7A"):    # Kintex7, Artix7
  files = ["oserdes_8_to_1_7series.vhd"]
elif (syn_device[0:4].upper()=="XCZU"):  #Zynq Ultrascale+
  files = ["oserdes_8_to_1_ultrascale.vhd"]
