fetchto = "../../ip_cores"

files = [ "kr260_ref_top.vhd", "wr_gthe4_adapter.vhd",
          "mpsoc.bd", "mpsoc_map.vhd",
        ]

modules = {
    "local" : [
        "gthe4_qpll",
        "../../",
    ],
    "git" : [
        "https://ohwr.org/project/general-cores.git",
        "https://ohwr.org/project/urv-core.git",
    ],
}
