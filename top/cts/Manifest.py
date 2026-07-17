fetchto = "../../ip_cores"

files = [ "cts_top.vhd", "wr_gthe4_adapter.vhd",
          "mpsoc.bd", "mpsoc_map.vhd",
          "gthe4_sdm.tcl",
        ]

modules = {
    "local" : [
        "../../",
    ],
    "git" : [
        "https://ohwr.org/project/general-cores.git",
        "https://ohwr.org/project/urv-core.git",
    ],
}
