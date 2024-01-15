##################
# Clocks
##################
create_clock -period 8.000 -name wr_clk_helper_125m [get_ports {wr_clk_helper_125m_p_i}]
create_clock -period 8.000 -name wr_clk_main_125m [get_ports {wr_clk_main_125m_p_i}]
create_clock -period 8.000 -name wr_clk_sfp_125m [get_ports {wr_clk_sfp_125m_p_i}]

create_clock -period 16.000 -name gth_eth_txclk [get_pins cmp_xwrc_board_zcu10x/cmp_xwrc_platform/gen_phy_zynqus_qplls.cmp_gth/gen_gtwizard_v1_7_gthe4_sdm_eth.U_gtwizard_gthe4/inst/gen_gtwizard_gthe4_top.gtwizard_v1_7_gthe4_sdm_eth_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[27].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/TXOUTCLK]
create_clock -period 16.000 -name gth_eth_rxclk [get_pins cmp_xwrc_board_zcu10x/cmp_xwrc_platform/gen_phy_zynqus_qplls.cmp_gth/gen_gtwizard_v1_7_gthe4_sdm_eth.U_gtwizard_gthe4/inst/gen_gtwizard_gthe4_top.gtwizard_v1_7_gthe4_sdm_eth_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[27].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/RXOUTCLK]

create_clock -period 16.000 -name gth_dmtd_txclk [get_pins cmp_xwrc_board_zcu10x/cmp_xwrc_platform/gen_default_plls.gen_zynqus_sdm_qplls.gtwizard_dmtd_inst/inst/gen_gtwizard_gthe4_top.gtwizard_v1_7_gthe4_sdm_dmtd_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST/TXOUTCLK]

create_clock -period 100.000 -name clk_10m_ext -waveform {0.000 50.000} [get_ports clk_10m_ext_i]

set_clock_groups -asynchronous -group {wr_clk_main_125m clk_sys_62m5} -group {wr_clk_sfp_125m wr_clk_helper_125m} -group {gth_eth_txclk} -group {gth_eth_rxclk} -group {gth_dmtd_txclk} -group {clk_10m_ext}

##################
# I/O constraints
##################

# LEDs 0=DS38, 1=DS37, 2=DS39, and 3=DS40
set_property PACKAGE_PIN AL11 [get_ports {user_led_o[0]}]
set_property PACKAGE_PIN AL13 [get_ports {user_led_o[1]}]
set_property PACKAGE_PIN AK13 [get_ports {user_led_o[2]}]
set_property PACKAGE_PIN AE15 [get_ports {user_led_o[3]}]
set_property IOSTANDARD LVCMOS12 [get_ports {user_led_o[*]}]
set_property OFFCHIP_TERM NONE [get_ports user_led_o[*]]

# PL HDMI EDID EEPROM U109 @0x50
set_property PACKAGE_PIN N12 [get_ports eeprom_scl_b]
set_property PACKAGE_PIN P12 [get_ports eeprom_sda_b]
set_property IOSTANDARD LVCMOS33 [get_ports eeprom_s??_b]
set_property OFFCHIP_TERM NONE [get_ports eeprom_s??_b]

# PL UART to Quad USB UART
set_property PACKAGE_PIN AL17 [get_ports uart0_txd_o]
set_property PACKAGE_PIN AH17 [get_ports uart0_rxd_i]
set_property IOSTANDARD LVCMOS12 [get_ports uart0_?xd_?]
set_property OFFCHIP_TERM NONE [get_ports uart0_txd_o]

# SFP0 (I2C via shared I2C1 hierarchy)
set_property PACKAGE_PIN AE22 [get_ports sfp_tx_disable_o]
set_property PACKAGE_PIN AH19 [get_ports sfp_scl_b]
set_property PACKAGE_PIN AL21 [get_ports sfp_sda_b]
set_property PACKAGE_PIN AA2 [get_ports sfp_rxp_i]
set_property IOSTANDARD LVCMOS12 [get_ports sfp_s??_b]
set_property IOSTANDARD LVCMOS12 [get_ports sfp_tx_disable_o]
set_property OFFCHIP_TERM NONE [get_ports sfp_s??_b]
set_property OFFCHIP_TERM NONE [get_ports sfp_s??_b]
set_property OFFCHIP_TERM NONE [get_ports sfp_tx_disable_o]

# CPU reset button SW20
set_property PACKAGE_PIN G13 [get_ports ps_por_i]
set_property IOSTANDARD LVCMOS18 [get_ports ps_por_i]

# Clock inputs
# USER_MGT_SI570_CLOCK2
set_property PACKAGE_PIN R10 [get_ports wr_clk_sfp_125m_p_i]
# USER_MGT_SI570_CLOCK1
set_property PACKAGE_PIN U10 [get_ports wr_clk_helper_125m_p_i]
# CLK_125 from Si5341b
set_property PACKAGE_PIN H9 [get_ports wr_clk_main_125m_p_i]
set_property IOSTANDARD LVDS [get_ports wr_clk_main_125m_p_i]

# PMOD (J87)
# PMOD1_3
set_property PACKAGE_PIN AN11 [get_ports clk_ref_125m_o]
# PMOD1_6
set_property PACKAGE_PIN AP12 [get_ports {pps_p_o}]
set_property IOSTANDARD LVCMOS12 [get_ports clk_ref_125m_o]
set_property IOSTANDARD LVCMOS12 [get_ports pps_p_o]
set_property OFFCHIP_TERM NONE [get_ports clk_ref_125m_o]
set_property OFFCHIP_TERM NONE [get_ports pps_p_o]

# GNSS UART on PMOD1 (J87)
# PMOD1_0
set_property PACKAGE_PIN AN8 [get_ports uart1_txd_o]
# PMOD1_1
set_property PACKAGE_PIN AN9 [get_ports uart1_rxd_i]
set_property IOSTANDARD LVCMOS12 [get_ports uart1_?xd_?]
set_property OFFCHIP_TERM NONE [get_ports uart1_txd_o]

# PPS and 10MHz reference
# PMOD1_4 PPS
set_property PACKAGE_PIN AP9 [get_ports pps_ext_i]
set_property IOSTANDARD LVCMOS12 [get_ports pps_ext_i]

# PMOD1_5 10MHz
# WARNING: This is not a clock capable pin. The 10MHz reference input for this
# ZCU106 design is untested and may perform badly.
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_10m_ext_i_IBUF_inst/O]
set_property PACKAGE_PIN AP10 [get_ports clk_10m_ext_i]
set_property IOSTANDARD LVCMOS12 [get_ports clk_10m_ext_i]

# DIP switch for XM105 SMA output clock selection
set_property PACKAGE_PIN A17 [get_ports gpio_dip_sw_i[0]]
set_property IOSTANDARD LVCMOS12 [get_ports gpio_dip_sw_i[0]]

# SMA on XM105 on FMC HPC0
set_property PACKAGE_PIN F10 [get_ports clk_hpc0_xm105_sma_o]
set_property PACKAGE_PIN G10 [get_ports pps_hpc0_xm105_sma_o]
set_property IOSTANDARD LVDCI_18 [get_ports clk_hpc0_xm105_sma_o]
set_property IOSTANDARD LVDCI_18 [get_ports pps_hpc0_xm105_sma_o]
set_property OUTPUT_IMPEDANCE RDRV_48_48 [get_ports clk_hpc0_xm105_sma_o]
set_property OUTPUT_IMPEDANCE RDRV_48_48 [get_ports pps_hpc0_xm105_sma_o]
#set_property OFFCHIP_TERM NONE [get_ports clk_hpc0_xm105_sma_o]
#set_property OFFCHIP_TERM NONE [get_ports pps_hpc0_xm105_sma_o]
set_property DCI_CASCADE {66 67} [get_iobanks 65]

# SMA on XM105 on FMC HPC1 -- NOT SUPPORTED --> tie to PMOD1_2 and PMOD1_7 instead
set_property -dict {PACKAGE_PIN AP11 IOSTANDARD LVCMOS12 OFFCHIP_TERM NONE} [get_ports clk_hpc1_xm105_sma_o]
set_property -dict {PACKAGE_PIN AN12 IOSTANDARD LVCMOS12 OFFCHIP_TERM NONE} [get_ports pps_hpc1_xm105_sma_o]

# Dummy GTH to overwrite the device-specific LOCs in the generated transceiver xdc files
set_property PACKAGE_PIN R2 [get_ports dummy_gthrxp_i[0]]
set_property PACKAGE_PIN P4 [get_ports dummy_gthrxp_i[1]]

#revert back to original instance
current_instance -quiet

# compress bitstream for faster loading
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]
