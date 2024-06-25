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
        "git://ohwr.org/project/general-cores.git",
        "git://ohwr.org/project/etherbone-core.git",
        "git://ohwr.org/project/urv-core.git",
    ],
}
