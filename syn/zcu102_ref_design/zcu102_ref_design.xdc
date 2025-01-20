##################
# Clocks
##################
create_clock -period 8.000 -name wr_clk_helper_125m [get_ports {wr_clk_helper_125m_p_i}]
create_clock -period 8.000 -name wr_clk_main_125m [get_ports {wr_clk_main_125m_p_i}]
create_clock -period 8.000 -name wr_clk_sfp_125m [get_ports {wr_clk_sfp_125m_p_i}]

create_clock -period 16.000 -name gth_eth_txclk [get_pins cmp_xwrc_board_zcu10x/cmp_xwrc_platform/gen_phy_zynqus_qplls.cmp_gth/gen_gtwizard_v1_7_gthe4_sdm_eth.U_gtwizard_gthe4/inst/gen_gtwizard_gthe4_top.gtwizard_v1_7_gthe4_sdm_eth_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[27].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/TXOUTCLK]
create_clock -period 16.000 -name gth_eth_rxclk [get_pins cmp_xwrc_board_zcu10x/cmp_xwrc_platform/gen_phy_zynqus_qplls.cmp_gth/gen_gtwizard_v1_7_gthe4_sdm_eth.U_gtwizard_gthe4/inst/gen_gtwizard_gthe4_top.gtwizard_v1_7_gthe4_sdm_eth_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[27].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/RXOUTCLK]

create_clock -period 16.000 -name gth_dmtd_txclk [get_pins cmp_xwrc_board_zcu10x/cmp_xwrc_platform/gen_default_plls.gen_zynqus_sdm_qplls.gtwizard_dmtd_inst/inst/gen_gtwizard_gthe4_top.gtwizard_v1_7_gthe4_sdm_dmtd_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/TXOUTCLK]

set_clock_groups -asynchronous -group {wr_clk_main_125m wr_clk_sfp_125m} -group {wr_clk_helper_125m} -group {gth_eth_txclk} -group {gth_eth_rxclk} -group {gth_dmtd_txclk}


##################
# I/O constraints
##################

# LEDs 0=DS38, 1=DS37, 2=DS39, and 3=DS40
set_property PACKAGE_PIN AG14 [get_ports {user_led_o[0]}]
set_property PACKAGE_PIN AF13 [get_ports {user_led_o[1]}]
set_property PACKAGE_PIN AE13 [get_ports {user_led_o[2]}]
set_property PACKAGE_PIN AJ14 [get_ports {user_led_o[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {user_led_o[*]}]
set_property OFFCHIP_TERM NONE [get_ports user_led_o[*]]

# PL HDMI EDID EEPROM U109 @0x50
set_property PACKAGE_PIN F15 [get_ports eeprom_scl_b]
set_property PACKAGE_PIN F16 [get_ports eeprom_sda_b]
set_property IOSTANDARD LVCMOS33 [get_ports eeprom_s??_b]
set_property OFFCHIP_TERM NONE [get_ports eeprom_s??_b]

# PL UART to Quad USB UART
set_property PACKAGE_PIN F13 [get_ports uart_txd_o]
set_property PACKAGE_PIN E13 [get_ports uart_rxd_i]
set_property IOSTANDARD LVCMOS33 [get_ports uart_?xd_?]
set_property OFFCHIP_TERM NONE [get_ports uart_txd_o]

# SFP2 (I2C via shared I2C1 hierarchy)
set_property PACKAGE_PIN B13 [get_ports sfp_tx_disable_o]
set_property PACKAGE_PIN K20 [get_ports sfp_scl_b]
set_property PACKAGE_PIN L20 [get_ports sfp_sda_b]
set_property PACKAGE_PIN B2 [get_ports sfp_rxp_i]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_s??_b]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_tx_disable_o]
set_property OFFCHIP_TERM NONE [get_ports sfp_s??_b]
set_property OFFCHIP_TERM NONE [get_ports sfp_s??_b]
set_property OFFCHIP_TERM NONE [get_ports sfp_tx_disable_o]

# CPU reset button SW20
set_property PACKAGE_PIN AM13 [get_ports ps_por_i]
set_property IOSTANDARD LVCMOS33 [get_ports ps_por_i]

# Clock inputs
# USER_MGT_SI570_CLOCK2
set_property PACKAGE_PIN C8 [get_ports wr_clk_sfp_125m_p_i]
# USER_MGT_SI570_CLOCK1
set_property PACKAGE_PIN L27 [get_ports wr_clk_helper_125m_p_i]
# CLK_125 from Si5341b
set_property PACKAGE_PIN G21 [get_ports wr_clk_main_125m_p_i]
set_property IOSTANDARD LVDS_25 [get_ports wr_clk_main_125m_p_i]

# PMOD (J87)
# PMOD1_2
set_property PACKAGE_PIN D22 [get_ports clk_sys_62m5_o]
# PMOD1_3
set_property PACKAGE_PIN E22 [get_ports clk_ref_125m_o]
# PMOD1_6
set_property PACKAGE_PIN J20 [get_ports {pps_p_o}]
set_property IOSTANDARD LVCMOS33 [get_ports clk_sys_62m5_o]
set_property IOSTANDARD LVCMOS33 [get_ports clk_ref_125m_o]
set_property IOSTANDARD LVCMOS33 [get_ports pps_p_o]
set_property OFFCHIP_TERM NONE [get_ports clk_sys_62m5_o]
set_property OFFCHIP_TERM NONE [get_ports clk_ref_125m_o]
set_property OFFCHIP_TERM NONE [get_ports pps_p_o]

# DIP switch for XM105 SMA output clock selection
set_property PACKAGE_PIN AN14 [get_ports gpio_dip_sw_i[0]]
set_property IOSTANDARD LVCMOS33 [get_ports gpio_dip_sw_i[0]]

# SMA on XM105 on FMC HPC0
set_property PACKAGE_PIN T8 [get_ports clk_xm105_sma_o]
set_property PACKAGE_PIN R8 [get_ports pps_p_o[1]]
set_property IOSTANDARD LVDCI_18 [get_ports clk_xm105_sma_o]
set_property IOSTANDARD LVDCI_18 [get_ports pps_p_o[1]]
set_property OUTPUT_IMPEDANCE RDRV_48_48 [get_ports clk_xm105_sma_o]
set_property OUTPUT_IMPEDANCE RDRV_48_48 [get_ports pps_p_o[1]]
#set_property OFFCHIP_TERM NONE [get_ports clk_xm105_sma_o]
#set_property OFFCHIP_TERM NONE [get_ports pps_p_o[1]]
set_property DCI_CASCADE {66 67} [get_iobanks 65]

# Dummy GTH to overwrite the device-specific LOCs in the generated transceiver xdc files
#set_property PACKAGE_PIN N31 [get_ports dummy_gthrxp_i[0]]
#set_property PACKAGE_PIN M33 [get_ports dummy_gthrxp_i[1]]

#revert back to original instance
current_instance -quiet

# compress bitstream for faster loading
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]
