def __helper():
  dirs = []
  if syn_device[:4] == "10as":      dirs.extend(["wr_arria10_phy"])
  if syn_device[:7] == "10ax027":   dirs.extend(["wr_arria10_scu4_phy"])
  if syn_device[:7] == "10ax048":   dirs.extend(["wr_arria10_ftm4_phy"])
  if syn_device[:7] == "10ax115":   dirs.extend(["wr_arria10_e3p1_phy"])
  if syn_device[:9] == "10ax027h2": dirs.extend(["wr_arria10_pex10_phy"])
  if syn_device[:9] == "10ax066h2": dirs.extend(["wr_arria10_ftm10_phy"])
  return dirs

files = [ "wr_arria10_phy.vhd" ]

modules = {"local": __helper() }
