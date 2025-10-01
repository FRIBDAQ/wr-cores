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

syn_top = "cts_top"
syn_project = "cts"
syn_tool = "vivado"

files = [
    "cts.xdc",
    "gtwizard_ultrascale_0.xci",
    "CTSExtensionMux.vhd",
    "gen_x_mhz.vhd",
]

modules = {
    "local" : [
        "../../top/cts/",
    ],
}

