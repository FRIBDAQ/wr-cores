fetchto = "../../ip_cores"

files = [ "kr260_ref_top.vhd", "wr_gthe4_adapter.vhd",
          "mpsoc.bd", "mpsoc_map.vhd",
          "drp_core.vhd", "drp_map.vhd",
          "gthe4_common/gthe4_sdm_gthe4_common_wrapper.v",
          "gthe4_common/gtwizard_ultrascale_v1_7_gthe4_common.v",
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
