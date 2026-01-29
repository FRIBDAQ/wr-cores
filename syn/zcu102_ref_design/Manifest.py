board  = "zcu10x"
target = "xilinx"
action = "synthesis"

syn_device = "xczu9eg"
syn_grade = "-2-e"
syn_package = "-ffvb1156"

syn_top = "zcu10x_ref_top"
syn_project = "zcu10x_ref_top"
syn_tool = "vivado"

files = [
    "zcu102_ref_design.xdc",
]

modules = {
    "local" : [
        "../../top/zcu10x_ref_design/",
    ],
}

