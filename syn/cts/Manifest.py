board  = "cts"
target = "xilinx"
action = "synthesis"

syn_device = "xck26-sfvc784"
syn_package = "-2LV"
syn_grade = "-c"
# In Makefile from hdlmake, remove line 255 which sets part property using device, package, and grade.
# Then add the following lines.
#		echo set_property board_part xilinx.com:k26c:part0:1.4 [current_project] >> $@
#		echo reset_property board_connections [current_project] >> $@
#
# Also, add the following lines under files.tcl target around line 102
# I don't understand why those are missing.
#	@echo '../../ip_cores/urv-core/rtl/urv_defs.v' >> $@
#	@echo '../../ip_cores/urv-core/rtl/urv_config.v' >> $@
#	@echo 'CTSExtensionMux.vhd' >> $@
#
# In project.tcl part in Makefile, add following to generate bin file
#		echo set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1] >> $@
#
# Finally, you have to run design_1.tcl inside the project.
# Then, create design HDL wrapper for the board design
# Then, set it as top

syn_top = "cts_top"
syn_project = "cts"
syn_tool = "vivado"

files = [
    "cts.xdc",
    "ip/gtwizard_ultrascale_0/gtwizard_ultrascale_0.xci",
    "CTSExtensionMux.vhd",
    "gen_x_mhz.vhd",
]

modules = {
    "local" : [
        "../../top/cts/",
    ],
}

