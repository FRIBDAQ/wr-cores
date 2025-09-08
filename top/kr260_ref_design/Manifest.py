fetchto = "../../ip_cores"

files = [ "kr260_ref_top.vhd",
          "mpsoc.bd", "mpsoc_map.vhd",
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
