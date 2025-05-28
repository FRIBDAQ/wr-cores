##################
# Clocks
##################

create_clock -period 13.400 -name clk [get_ports {refclk1_p_i}]

#create_clock -period 8.000 -name wr_clk_helper_125m -waveform {0.000  4.000} [get_ports {wr_clk_helper_125m_p_i}]
#create_clock -period 8.000 -name wr_clk_main_125m   -waveform {0.000  4.000} [get_ports {wr_clk_main_125m_p_i}]
#create_clock -period 8.000 -name wr_clk_sfp_125m    -waveform {0.000  4.000} [get_ports {wr_clk_sfp_125m_p_i}]
#create_clock -period 16.000 -name gth_txclk         -waveform {0.000 8.000} [get_nets cmp_xwrc_board_pxie_fmc/cmp_xwrc_platform/gen_phy_zynqus.cmp_gth/tx_out_clk_o]
#create_clock -period 16.000 -name gth_rxclk         -waveform {0.000 8.000} [get_nets cmp_xwrc_board_pxie_fmc/cmp_xwrc_platform/gen_phy_zynqus.cmp_gth/rx_rbclk_o]

#create_generated_clock -name clk_dmtd -source [get_ports {wr_clk_helper_125m_p_i}] -divide_by 2 [get_pins cmp_xwrc_board_pxie_fmc/cmp_xwrc_platform/gen_default_plls.gen_zynqus_default_plls.cmp_clk_dmtd_buf_o/O]

#set_clock_groups -asynchronous -group {wr_clk_main_125m wr_clk_sfp_125m} -group {wr_clk_helper_125m clk_dmtd} -group {gth_txclk} -group {gth_rxclk}


##################
# I/O constraints
##################

set_property PACKAGE_PIN V6 [get_ports {refclk1_p_i}]
#set_property PACKAGE_PIN V7 [get_ports {refclk1_n_i}]

set_property PACKAGE_PIN T2 [get_ports {pad_rxp_i}]
set_property PACKAGE_PIN T1 [get_ports {pad_rxn_i}]

set_property PACKAGE_PIN R4 [get_ports {pad_txp_o}]
set_property PACKAGE_PIN R3 [get_ports {pad_txn_o}]

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
