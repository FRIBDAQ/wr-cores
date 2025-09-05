##################
# Clocks
##################

# 74.xxx Mhz (Not used)
# create_clock -period 13.400 -name clk [get_ports {refclk1_p_i}]

# 156.25 Mhz
create_clock -period 6.400 -name clk [get_ports {refclk0_p_i}]

# Aux oscillator (used only for leds ?)
create_clock -period 40.000 -name clk_25m [get_ports {clk_25m_i}]

create_generated_clock -name clk_62m5 [get_pins inst_mmcm_62m5/CLKOUT0]
create_generated_clock -name clk_ps_out [get_pins inst_mmcm_ps/CLKOUT0]

# GTH monitor clock
# Not sure about the period (apparently 2* clk)
create_clock -period 10.000 -name dmon_clk [get_pins {inst_gth_channel/inst/gen_gtwizard_gthe4_top.gthe4_sdm_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/DMONITOROUTCLK}]

# create_clock -period 16.000 -name gth_txclk   -waveform {0.000 8.000} [get_nets cmp_xwrc_board_pxie_fmc/cmp_xwrc_platform/gen_phy_zynqus.cmp_gth/tx_out_clk_o]

# create_clock -period 16.000 -name gth_rxoutclk [get_nets {inst_gth_channel/inst/gen_gtwizard_gthe4_top.gthe4_sdm_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST.RXOUTCLK}]

# create_clock -period 16.000 -name gth_rxoutclkpcs [get_nets {inst_gth_channel/inst/gen_gtwizard_gthe4_top.gthe4_sdm_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST.RXOUTCLKPCS}]

# create_clock -period 16.000 -name gth_txoutclk [get_nets {inst_gth_channel/inst/gen_gtwizard_gthe4_top.gthe4_sdm_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST.TXOUTCLK}]


#create_clock -period 8.000 -name wr_clk_helper_125m -waveform {0.000  4.000} [get_ports {wr_clk_helper_125m_p_i}]
#create_clock -period 8.000 -name wr_clk_main_125m   -waveform {0.000  4.000} [get_ports {wr_clk_main_125m_p_i}]
#create_clock -period 8.000 -name wr_clk_sfp_125m    -waveform {0.000  4.000} [get_ports {wr_clk_sfp_125m_p_i}]
#create_clock -period 16.000 -name gth_txclk         -waveform {0.000 8.000} [get_nets cmp_xwrc_board_pxie_fmc/cmp_xwrc_platform/gen_phy_zynqus.cmp_gth/tx_out_clk_o]
#create_clock -period 16.000 -name gth_rxclk         -waveform {0.000 8.000} [get_nets cmp_xwrc_board_pxie_fmc/cmp_xwrc_platform/gen_phy_zynqus.cmp_gth/rx_rbclk_o]

#create_generated_clock -name clk_dmtd -source [get_ports {wr_clk_helper_125m_p_i}] -divide_by 2 [get_pins cmp_xwrc_board_pxie_fmc/cmp_xwrc_platform/gen_default_plls.gen_zynqus_default_plls.cmp_clk_dmtd_buf_o/O]

#set_clock_groups -asynchronous -group {wr_clk_main_125m wr_clk_sfp_125m} -group {wr_clk_helper_125m clk_dmtd} -group {gth_txclk} -group {gth_rxclk}

set_clock_groups -asynchronous \
  -group clk_62m5 \
  -group clk_ps_out \
  -group clk_25m \
  -group dmon_clk \
  -group [get_clocks -of_objects [get_pins {inst_gth_channel/inst/gen_gtwizard_gthe4_top.gthe4_sdm_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/RXOUTCLK}]] \
  -group [get_clocks -of_objects [get_pins {inst_gth_channel/inst/gen_gtwizard_gthe4_top.gthe4_sdm_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/TXOUTCLK}]]


# Input delays
# We don't really care about the delay on async inputs
set_input_delay 8.0 -clock clk_62m5 [get_ports {sfp_mod_abs_i}]
set_false_path -from [get_ports {sfp_mod_abs_i}]
set_input_delay 8.0 -clock clk_62m5 [get_ports {sfp_scl_b}]
set_false_path -from [get_ports {sfp_scl_b}]
set_input_delay 8.0 -clock clk_62m5 [get_ports {sfp_sda_b}]
set_false_path -from [get_ports {sfp_sda_b}]
set_input_delay 8.0 -clock clk_62m5 [get_ports {sfp_tx_fault_i}]
set_false_path -from [get_ports {sfp_tx_fault_i}]

# Output delays
set_output_delay 2.0 -clock clk_25m [get_ports {led1_o}]
set_false_path -to [get_ports {led1_o}]
set_output_delay 2.0 -clock clk_25m [get_ports {led2_o}]
set_false_path -to [get_ports {led2_o}]

set_output_delay 2.0 -clock clk_62m5 [get_ports {pmod4_6_b}]
set_false_path -to [get_ports {pmod4_6_b}]
set_output_delay 2.0 -clock clk_62m5 [get_ports {pmod4_8_b}]
set_false_path -to [get_ports {pmod4_8_b}]

set_output_delay 2.0 -clock clk_62m5 [get_ports {sfp_led1_o}]
set_false_path -to [get_ports {sfp_led1_o}]
set_output_delay 2.0 -clock clk_62m5 [get_ports {sfp_led2_o}]
set_false_path -to [get_ports {sfp_led2_o}]
set_output_delay 2.0 -clock clk_62m5 [get_ports {sfp_scl_b}]
set_false_path -to [get_ports {sfp_scl_b}]
set_output_delay 2.0 -clock clk_62m5 [get_ports {sfp_sda_b}]
set_false_path -to [get_ports {sfp_sda_b}]
set_output_delay 2.0 -clock clk_62m5 [get_ports {sfp_tx_disable_o}]
set_false_path -to [get_ports {sfp_tx_disable_o}]

##################
# I/O constraints
##################

#set_property PACKAGE_PIN V6 [get_ports {refclk1_p_i}]
#set_property PACKAGE_PIN V7 [get_ports {refclk1_n_i}]

set_property PACKAGE_PIN Y6 [get_ports {refclk0_p_i}]
set_property PACKAGE_PIN Y5 [get_ports {refclk0_n_i}]

set_property PACKAGE_PIN T2 [get_ports {pad_rxp_i}]
set_property PACKAGE_PIN T1 [get_ports {pad_rxn_i}]
set_property PACKAGE_PIN R4 [get_ports {pad_txp_o}]
set_property PACKAGE_PIN R3 [get_ports {pad_txn_o}]

#set_property PACKAGE_PIN P2 [get_ports {helper_rxp_i}]
#set_property PACKAGE_PIN P1 [get_ports {helper_rxn_i}]
#set_property PACKAGE_PIN N4 [get_ports {helper_txp_o}]
#set_property PACKAGE_PIN N3 [get_ports {helper_txn_o}]

set_property PACKAGE_PIN F8 [get_ports {led1_o}]
set_property PACKAGE_PIN E8 [get_ports {led2_o}]
set_property IOSTANDARD LVCMOS18 [get_ports led1_o]
set_property IOSTANDARD LVCMOS18 [get_ports led2_o]

set_property PACKAGE_PIN G8 [get_ports {sfp_led1_o}]
set_property PACKAGE_PIN F7 [get_ports {sfp_led2_o}]
set_property IOSTANDARD LVCMOS18 [get_ports sfp_led1_o]
set_property IOSTANDARD LVCMOS18 [get_ports sfp_led2_o]

set_property PACKAGE_PIN L3 [get_ports {clk_25m_i}]
set_property IOSTANDARD LVCMOS18 [get_ports {clk_25m_i}]

set_property PACKAGE_PIN AD11 [get_ports pmod4_2_b]
set_property IOSTANDARD LVCMOS33 [get_ports pmod4_2_b]
set_property SLEW FAST [get_ports pmod4_2_b]

set_property PACKAGE_PIN AD10 [get_ports pmod4_4_b]
set_property IOSTANDARD LVCMOS33 [get_ports pmod4_4_b]
set_property SLEW FAST [get_ports pmod4_4_b]

set_property PACKAGE_PIN AA11 [get_ports pmod4_6_b]
set_property IOSTANDARD LVCMOS33 [get_ports pmod4_6_b]
set_property SLEW FAST [get_ports pmod4_6_b]

set_property PACKAGE_PIN AA10 [get_ports pmod4_8_b]
set_property IOSTANDARD LVCMOS33 [get_ports pmod4_8_b]
set_property SLEW FAST [get_ports pmod4_8_b]

set_property PACKAGE_PIN A10 [get_ports sfp_tx_fault_i]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_tx_fault_i]

set_property PACKAGE_PIN Y10 [get_ports sfp_tx_disable_o]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_tx_disable_o]

set_property PACKAGE_PIN W10 [get_ports sfp_mod_abs_i]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_mod_abs_i]

set_property PACKAGE_PIN AC11 [get_ports sfp_sda_b]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_sda_b]

set_property PACKAGE_PIN AB11 [get_ports sfp_scl_b]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_scl_b]


# Very important: use POSTPI
#set_property TX_PROGCLK_SEL POSTPI [get_cells {inst_gth_channel/inst/gen_gtwizard_gthe4_top.gthe4_sdm_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST} ]
#set_property TXPI_SYNFREQ_PPM "110" [get_cells {inst_gth_channel/inst/gen_gtwizard_gthe4_top.gthe4_sdm_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST} ]

# For dmonitor
# Cf xapp1252
set_property ADAPT_CFG1 "1101100000000010" [get_cells {inst_gth_channel/inst/gen_gtwizard_gthe4_top.gthe4_sdm_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST} ]
set_property DMONITOR_CFG1 "00000001" [get_cells {inst_gth_channel/inst/gen_gtwizard_gthe4_top.gthe4_sdm_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST} ]
set_property RXCDR_CFG0 "0000010000100110" [get_cells {inst_gth_channel/inst/gen_gtwizard_gthe4_top.gthe4_sdm_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST} ]
set_property RXCDR_CFG2 "0000000011000101" [get_cells {inst_gth_channel/inst/gen_gtwizard_gthe4_top.gthe4_sdm_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST} ]
set_property RXCDR_CFG5 "0011010001111011" [get_cells {inst_gth_channel/inst/gen_gtwizard_gthe4_top.gthe4_sdm_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST} ]
