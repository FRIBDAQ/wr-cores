board  = "damc-fmc2zup"
target = "xilinx"
action = "synthesis"

# xczu11eg-ffvc1760-2L-e
syn_device = "xczu11eg"
syn_grade = "-2L-e"
syn_package = "-ffvc1760"

syn_top = "damc_fmc2zup_ref_top"
syn_project = "damc_fmc2zup_ref.xpr"

syn_tool = "vivado"

modules = {
    "local": "../../top/damc-fmc2zup_ref_design/",
}

syn_post_project_cmd = (
    "echo \"Creating Vivado IP Block Diagram\";"
    "echo \"$(TCL_OPEN)\" > tmp.tcl;"
    "echo \"source ../../top/damc-fmc2zup_ref_design/system_bd.tcl\" >> tmp.tcl;"
    "echo \"source ../../top/damc-fmc2zup_ref_design/create_wrapper.tcl\" >> tmp.tcl;"
    "echo \"$(TCL_CLOSE)\" >> tmp.tcl;"
    "$(TCL_INTERPRETER) tmp.tcl"
)
