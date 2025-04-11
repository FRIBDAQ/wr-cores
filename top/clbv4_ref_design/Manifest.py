fetchto = "../../ip_cores"

files = [
    "clbv4_wr_ref_top.vhd",
    "clbv4_wr_ref_top.xdc",
    "clbv4_wr_ref_top.bmm",
]

modules = {
    "local" : [
        "../../",
    ],
    "git" : [
        "git://gitlab.com/ohwr/hdl-core-lib/general-cores.git",
        "git://gitlab.com/ohwr/project/urv-core.git",
    ],
}
