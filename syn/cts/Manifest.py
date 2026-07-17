board  = "kr260"
target = "xilinx"
action = "synthesis"

syn_device = "xck26"
syn_grade = "-2LV-c"
syn_package = "-sfvc784"

syn_top = "kr260_ref_top"
syn_project = "kr260_ref_top"
syn_tool = "vivado"

files = [
    "kr260_ref_design.xdc",
]

modules = {
    "local" : [
        "../../top/kr260_ref_design/",
    ],
}

