board  = "zcu102"
target = "xilinx"
action = "synthesis"

syn_device = "xczu9eg"
syn_grade = "-2-e"
syn_package = "-ffvb1156"

syn_top = "zcu102_ref_top"
syn_project = "zcu102_ref_top"
syn_tool = "vivado"

files = [
    "zcu102_ref_design.xdc",
]

modules = {
    "local" : [
        "../../top/zcu102_ref_design/",
    ],
}

