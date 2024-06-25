fetchto = "../../ip_cores"

files = [
    "damc_fmc2zup_ref_top.vhd",
    "damc_fmc2zup_ref_top.xdc",
    "damc_fmc2zup_ref_timing.xdc"
]

modules = {
    "local" : [
        "../../",
        "../../board/damc-fmc2zup"
    ],
    "git" : [
        "git://ohwr.org/hdl-core-lib/general-cores.git",
        "git://ohwr.org/hdl-core-lib/etherbone-core.git",
    ],
}
