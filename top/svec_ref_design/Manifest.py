fetchto = "../../ip_cores"

files = [
    "svec_wr_ref_top.vhd",
]

modules = {
    "local" : [
        "../../",
    ],
    "git" : [
        "git://gitlab.com/ohwr/project/general-cores.git",
        "git://gitlab.com/ohwr/project/vme64x-core.git",
        "git://gitlab.com/ohwr/project/etherbone-core.git",
        "git://gitlab.com/ohwr/project/urv-core.git",
    ],
}
