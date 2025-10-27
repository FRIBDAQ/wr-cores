fetchto = "../../ip_cores"

files = [ "pxie_fmc_ref_top.vhd", ]

modules = {
    "local" : [
        "../../",
    ],
    "git" : [
        "https://gitlab.com/ohwr/project/general-cores.git",
        "https://gitlab.com/ohwr/project/etherbone-core.git",
        "https://gitlab.com/ohwr/project/urv-core.git",
    ],
}
