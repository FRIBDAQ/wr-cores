fetchto = "../../ip_cores"

files = [
    "cute_wr_ref_top.vhd",
    "cute_wr_ref_top.ucf",
]

modules = {
    "local" : [
        "../../",
        "../../board/cute",
    ],
    "git" : [
        "git://gitlab.com/ohwr/project/general-cores.git",
        "git://gitlab.com/ohwr/project/etherbone-core.git",
        "git://gitlab.com/ohwr/project/urv-core.git",
    ],
}
