fetchto = "../../ip_cores"

files = [ "pxie_fmc_ref_top.vhd", ]

modules = {
    "local" : [
        "../../",
    ],
    "git" : [
        "git://gitlab.com/ohwr/hdl-core-lib/general-cores.git",
        "git://gitlab.com/ohwr/hdl-core-lib/gn4124-core.git",
        "git://gitlab.com/ohwr/hdl-core-lib/etherbone-core.git",
    ],
}
