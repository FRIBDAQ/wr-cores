fetchto = "../../ip_cores"

files = [ "cts_top.vhd", "mpsoc_map.vhd", "clkMux.vhd" ]

modules = {
    "local" : [
        "../../",
    ],
    "git" : [
        "git://ohwr.org/hdl-core-lib/general-cores.git",
        "git://ohwr.org/hdl-core-lib/gn4124-core.git",
        "git://ohwr.org/hdl-core-lib/etherbone-core.git",
        "git://ohwr.org/hdl-core-lib/urv-core.git",
    ],
}
