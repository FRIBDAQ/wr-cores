
################################################################################
# general purpose clocks

set_property PACKAGE_PIN D4 [get_ports clk_200_p]
set_property PACKAGE_PIN D3 [get_ports clk_200_n]
set_property IOSTANDARD LVDS_25 [get_ports clk_200_p]


################################################################################
# reset from MMC

set_property PACKAGE_PIN H11 [get_ports reset_mmc_n]
set_property IOSTANDARD LVCMOS18 [get_ports reset_mmc_n]


################################################################################
# Clocks

set_property PACKAGE_PIN G16 [get_ports clk_20m_vcxo_i]
set_property PACKAGE_PIN AT25 [get_ports clk_125m_pllref_p_i]
set_property PACKAGE_PIN AT26 [get_ports clk_125m_pllref_n_i]
set_property PACKAGE_PIN Y11 [get_ports clk_125m_gtp_n_i]
set_property PACKAGE_PIN Y12 [get_ports clk_125m_gtp_p_i]

set_property IOSTANDARD LVCMOS18 [get_ports clk_20m_vcxo_i]
set_property IOSTANDARD LVDS [get_ports clk_125m_pllref_p_i]
set_property DQS_BIAS TRUE [get_ports clk_125m_pllref_p_i]
set_property EQUALIZATION EQ_LEVEL0 [get_ports clk_125m_pllref_p_i]


################################################################################
# SFP

set_property PACKAGE_PIN AT4 [get_ports sfp_rxp_i]
set_property PACKAGE_PIN AT3 [get_ports sfp_rxn_i]
set_property PACKAGE_PIN AR6 [get_ports sfp_txp_o]
set_property PACKAGE_PIN AR5 [get_ports sfp_txn_o]


################################################################################
# DAC

set_property PACKAGE_PIN D8 [get_ports plldac_sclk_o]
set_property PACKAGE_PIN C8 [get_ports plldac_din_o]
set_property PACKAGE_PIN D6 [get_ports pll25dac_cs_n_o]
set_property PACKAGE_PIN E6 [get_ports pll20dac_cs_n_o]

set_property IOSTANDARD LVCMOS33 [get_ports plldac_sclk_o]
set_property IOSTANDARD LVCMOS33 [get_ports plldac_din_o]
set_property IOSTANDARD LVCMOS33 [get_ports pll25dac_cs_n_o]
set_property IOSTANDARD LVCMOS33 [get_ports pll20dac_cs_n_o]


################################################################################
# EEPROM (called WR.I2C on the schematics)

set_property PACKAGE_PIN C9 [get_ports eeprom_sda_io]
set_property PACKAGE_PIN D9 [get_ports eeprom_scl_io]

set_property IOSTANDARD LVCMOS33 [get_ports eeprom_sda_io]
set_property IOSTANDARD LVCMOS33 [get_ports eeprom_scl_io]


################################################################################
# front-panel LEDs

set_property PACKAGE_PIN C10 [get_ports {led_fp[3]}]
set_property PACKAGE_PIN B10 [get_ports {led_fp[2]}]
set_property PACKAGE_PIN B12 [get_ports {led_fp[1]}]
set_property PACKAGE_PIN B11 [get_ports {led_fp[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_fp[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_fp[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_fp[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led_fp[0]}]

set_property PACKAGE_PIN A8 [get_ports {led_fp_wr[1]}]
set_property PACKAGE_PIN B8 [get_ports {led_fp_wr[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_fp_wr[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_fp_wr[0]}]

################################################################################
# FMC2
#    P-N swapped: 2, 3, 5, 6, 7, 8, 9, 14, 19, 21, 23, 32, 33

set_property PACKAGE_PIN AN24 [get_ports {fmc2_la_p_io[33]}]
set_property PACKAGE_PIN AM24 [get_ports {fmc2_la_n_io[33]}]
set_property PACKAGE_PIN AL23 [get_ports {fmc2_la_p_io[32]}]
set_property PACKAGE_PIN AK23 [get_ports {fmc2_la_n_io[32]}]
set_property PACKAGE_PIN AY27 [get_ports {fmc2_la_p_io[31]}]
set_property PACKAGE_PIN AY28 [get_ports {fmc2_la_n_io[31]}]
set_property PACKAGE_PIN BA28 [get_ports {fmc2_la_p_io[30]}]
set_property PACKAGE_PIN BB28 [get_ports {fmc2_la_n_io[30]}]
set_property PACKAGE_PIN AW24 [get_ports {fmc2_la_p_io[29]}]
set_property PACKAGE_PIN AY24 [get_ports {fmc2_la_n_io[29]}]
set_property PACKAGE_PIN BA26 [get_ports {fmc2_la_p_io[28]}]
set_property PACKAGE_PIN BB26 [get_ports {fmc2_la_n_io[28]}]
set_property PACKAGE_PIN AJ24 [get_ports {fmc2_la_p_io[27]}]
set_property PACKAGE_PIN AK24 [get_ports {fmc2_la_n_io[27]}]
set_property PACKAGE_PIN AR23 [get_ports {fmc2_la_p_io[26]}]
set_property PACKAGE_PIN AT23 [get_ports {fmc2_la_n_io[26]}]
set_property PACKAGE_PIN AP24 [get_ports {fmc2_la_p_io[25]}]
set_property PACKAGE_PIN AP25 [get_ports {fmc2_la_n_io[25]}]
set_property PACKAGE_PIN AU24 [get_ports {fmc2_la_p_io[24]}]
set_property PACKAGE_PIN AV24 [get_ports {fmc2_la_n_io[24]}]
set_property PACKAGE_PIN AW26 [get_ports {fmc2_la_p_io[23]}]
set_property PACKAGE_PIN AV26 [get_ports {fmc2_la_n_io[23]}]
set_property PACKAGE_PIN AV27 [get_ports {fmc2_la_p_io[22]}]
set_property PACKAGE_PIN AW27 [get_ports {fmc2_la_n_io[22]}]
set_property PACKAGE_PIN AN23 [get_ports {fmc2_la_p_io[21]}]
set_property PACKAGE_PIN AM23 [get_ports {fmc2_la_n_io[21]}]
set_property PACKAGE_PIN BB24 [get_ports {fmc2_la_p_io[20]}]
set_property PACKAGE_PIN BB25 [get_ports {fmc2_la_n_io[20]}]
set_property PACKAGE_PIN BA25 [get_ports {fmc2_la_p_io[19]}]
set_property PACKAGE_PIN AY25 [get_ports {fmc2_la_n_io[19]}]
set_property PACKAGE_PIN AN27 [get_ports {fmc2_la_p_io[18]}]
set_property PACKAGE_PIN AP27 [get_ports {fmc2_la_n_io[18]}]
set_property PACKAGE_PIN AR27 [get_ports {fmc2_la_p_io[17]}]
set_property PACKAGE_PIN AT27 [get_ports {fmc2_la_n_io[17]}]
set_property PACKAGE_PIN AN16 [get_ports {fmc2_la_p_io[16]}]
set_property PACKAGE_PIN AP16 [get_ports {fmc2_la_n_io[16]}]
set_property PACKAGE_PIN AL18 [get_ports {fmc2_la_p_io[15]}]
set_property PACKAGE_PIN AM18 [get_ports {fmc2_la_n_io[15]}]
set_property PACKAGE_PIN AK18 [get_ports {fmc2_la_p_io[14]}]
set_property PACKAGE_PIN AJ18 [get_ports {fmc2_la_n_io[14]}]
set_property PACKAGE_PIN AN18 [get_ports {fmc2_la_p_io[13]}]
set_property PACKAGE_PIN AN17 [get_ports {fmc2_la_n_io[13]}]
set_property PACKAGE_PIN AL16 [get_ports {fmc2_la_p_io[12]}]
set_property PACKAGE_PIN AM16 [get_ports {fmc2_la_n_io[12]}]
set_property PACKAGE_PIN AJ17 [get_ports {fmc2_la_p_io[11]}]
set_property PACKAGE_PIN AK17 [get_ports {fmc2_la_n_io[11]}]
set_property PACKAGE_PIN AY17 [get_ports {fmc2_la_p_io[10]}]
set_property PACKAGE_PIN BA17 [get_ports {fmc2_la_n_io[10]}]
set_property PACKAGE_PIN AV18 [get_ports {fmc2_la_p_io[9]}]
set_property PACKAGE_PIN AU18 [get_ports {fmc2_la_n_io[9]}]
set_property PACKAGE_PIN BB15 [get_ports {fmc2_la_p_io[8]}]
set_property PACKAGE_PIN BA15 [get_ports {fmc2_la_n_io[8]}]
set_property PACKAGE_PIN BB16 [get_ports {fmc2_la_p_io[7]}]
set_property PACKAGE_PIN BA16 [get_ports {fmc2_la_n_io[7]}]
set_property PACKAGE_PIN BB13 [get_ports {fmc2_la_p_io[6]}]
set_property PACKAGE_PIN BA13 [get_ports {fmc2_la_n_io[6]}]
set_property PACKAGE_PIN AY14 [get_ports {fmc2_la_p_io[5]}]
set_property PACKAGE_PIN AY15 [get_ports {fmc2_la_n_io[5]}]
set_property PACKAGE_PIN AW17 [get_ports {fmc2_la_p_io[4]}]
set_property PACKAGE_PIN AW16 [get_ports {fmc2_la_n_io[4]}]
set_property PACKAGE_PIN BA12 [get_ports {fmc2_la_p_io[3]}]
set_property PACKAGE_PIN AY12 [get_ports {fmc2_la_n_io[3]}]
set_property PACKAGE_PIN BB10 [get_ports {fmc2_la_p_io[2]}]
set_property PACKAGE_PIN BA10 [get_ports {fmc2_la_n_io[2]}]
set_property PACKAGE_PIN AR18 [get_ports {fmc2_la_p_io[1]}]
set_property PACKAGE_PIN AT18 [get_ports {fmc2_la_n_io[1]}]
set_property PACKAGE_PIN AV17 [get_ports {fmc2_la_p_io[0]}]
set_property PACKAGE_PIN AV16 [get_ports {fmc2_la_n_io[0]}]

set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[8]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[9]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[10]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[11]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[12]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[13]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[14]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[15]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[16]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[17]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[18]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[19]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[20]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[21]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[22]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[23]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[24]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[25]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[26]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[27]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[28]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[29]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[30]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[31]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[32]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_n_io[33]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[4]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[5]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[6]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[8]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[9]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[10]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[11]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[12]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[13]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[14]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[15]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[16]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[17]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[18]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[19]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[20]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[21]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[22]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[23]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[24]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[25]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[26]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[27]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[28]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[29]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[30]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[31]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[32]}]
set_property IOSTANDARD LVCMOS18 [get_ports {fmc2_la_p_io[33]}]

################################################################################
# front-panel cable

set_property PACKAGE_PIN F20 [get_ports fplink_trig0_p]
set_property PACKAGE_PIN E20 [get_ports fplink_trig0_n]
set_property PACKAGE_PIN D19 [get_ports fplink_trig1_p]
set_property PACKAGE_PIN C19 [get_ports fplink_trig1_n]
set_property IOSTANDARD LVCMOS18 [get_ports fplink_trig0_p]
set_property IOSTANDARD LVCMOS18 [get_ports fplink_trig0_n]
set_property IOSTANDARD LVCMOS18 [get_ports fplink_trig1_p]
set_property IOSTANDARD LVCMOS18 [get_ports fplink_trig1_n]
