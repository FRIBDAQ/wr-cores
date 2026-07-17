board  = "cts"
target = "xilinx"
action = "synthesis"

syn_device = "xck26"
syn_grade = "-2LV-c"
syn_package = "-sfvc784"

syn_top = "cts_top"
syn_project = "cts"
syn_tool = "vivado"

files = [
    "cts.xdc",
]

modules = {
    "local" : [
        "../../top/cts/",
    ],
}

