set projDir [file dirname [info script]]

set_param general.maxThreads 8
get_param general.maxThreads

# Xilinx speed grades: 1,2,3: 1 = slowest, 3 = fastest
set speed   2
set fpga xczu7ev-ffvc1156-${speed}-e
set device  ${fpga}

set top     zcu10x_ref_top

# Check hdlmake has generated file dependencies
if {![file exists files.tcl]} {
    puts "File: files.tcl not found, please check hdlmake has generated the file dependencies."
    exit 1
}

source files.tcl

# constraint files
read_xdc $projDir/zcu106_ref_design.xdc

set start_time [clock seconds]

synth_design -top ${top} -part ${device} -generic g_BOARD_NAME="X106" > ${top}_synth.log
write_checkpoint -force ${top}_synth

opt_design -directive Explore -verbose > ${top}_opt.log
write_checkpoint -force ${top}_opt

place_design -directive Explore > ${top}_place.log
write_checkpoint -force ${projDir}/${top}_place

phys_opt_design -directive Explore > ${top}_phys_opt.log
write_checkpoint -force ${projDir}/${top}_phys_opt

route_design -directive Explore > ${top}_route.log
write_checkpoint -force ${projDir}/${top}_route

report_timing_summary -file ${top}_timing_summary.rpt
report_timing -sort_by group -max_paths 100 -path_type full -file ${top}_timing.rpt
report_utilization -hierarchical -file ${top}_utilization.rpt
report_io -file ${top}_pin.rpt

# bitstream configuration...
write_bitstream -force ${projDir}/${top}.bit
write_debug_probes -force ${projDir}/${top}.ltx

set end_time [clock seconds]
set total_time [ expr { $end_time - $start_time} ]
set absolute_time [clock format $total_time -format {%H:%M:%S} -gmt true ]
puts "\ntotal build time: $absolute_time\n"

set hold_slack [get_property SLACK [get_timing_paths -hold]]
set setup_slack [get_property SLACK [get_timing_paths -setup]]
if {$hold_slack < 0 || $setup_slack < 0} {
	puts "Setup or Hold violations: WNS=$setup_slack, WHS=$hold_slack\n"
	exit 1
} else {
	puts "No timing violations (WNS=$setup_slack, WHS=$hold_slack)\n"
}

exit 0
