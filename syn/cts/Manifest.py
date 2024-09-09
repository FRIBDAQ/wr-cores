board  = "cts"
target = "xilinx"
action = "synthesis"

syn_device = "xck26-sfvc784"
syn_grade = "-2LV"
syn_package = "-c"

syn_top = "cts_top"
syn_project = "cts_top"
syn_tool = "vivado"

files = [
    "cts.xdc",
]

modules = {
    "local" : [
        "../../top/cts/",
    ],
}

