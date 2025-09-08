fetchto = "../../ip_cores"

files = [ "kr260_ref_top.vhd",
          "wr_gthe4_adapter.vhd", "wr_gthe4_rxtx_adapter.vhd",
          "mpsoc.bd", "mpsoc_map.vhd",
          "rxpi_gthe4_map.vhd",
          "gthe4_sdm.tcl",
          "xwrc_board_gthe4_rxpi.vhd",
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
