#####################################################
#################### Reset Button ###################
#####################################################
# set_property PACKAGE_PIN H18 [get_ports BUTTON]
# set_property IOSTANDARD LVCMOS25 [get_ports BUTTON]

#####################################################
#################### Version ########################
#####################################################
set_property PACKAGE_PIN D10 [get_ports VER0]
set_property PACKAGE_PIN A14 [get_ports VER1]
set_property PACKAGE_PIN A13 [get_ports VER2]
set_property IOSTANDARD LVCMOS25 [get_ports VER0]
set_property IOSTANDARD LVCMOS25 [get_ports VER1]
set_property IOSTANDARD LVCMOS25 [get_ports VER2]

#####################################################
#################### Temp Sensor#####################
#####################################################
set_property PACKAGE_PIN U14 [get_ports ONE_WIRE]
set_property IOSTANDARD LVCMOS33 [get_ports ONE_WIRE]

#####################################################
################ Clock Signals  (LVDS) ##############
#####################################################
set_property PACKAGE_PIN T14 [get_ports CLK_62M5_DMTD]
set_property IOSTANDARD LVCMOS33 [get_ports CLK_62M5_DMTD]

set_property PACKAGE_PIN E15 [get_ports FPGA_GCLK_P]
set_property PACKAGE_PIN D15 [get_ports FPGA_GCLK_N]
set_property IOSTANDARD LVDS_25 [get_ports FPGA_GCLK_P]
set_property IOSTANDARD LVDS_25 [get_ports FPGA_GCLK_N]

set_property PACKAGE_PIN B6 [get_ports MGTREFCLK1_P]
set_property PACKAGE_PIN B5 [get_ports MGTREFCLK1_N]

set_property PACKAGE_PIN F14 [get_ports OE_125M]
set_property IOSTANDARD LVCMOS25 [get_ports OE_125M]
set_property PACKAGE_PIN D6 [get_ports MGTREFCLK0_P]
set_property PACKAGE_PIN D5 [get_ports MGTREFCLK0_N]

#####################################################
#################### DAC Signals ####################
#####################################################
set_property PACKAGE_PIN U12 [get_ports DAC_LDAC_N]
set_property PACKAGE_PIN V14 [get_ports DAC_SCLK]
set_property PACKAGE_PIN V12 [get_ports DAC_SDO]
set_property PACKAGE_PIN V13 [get_ports DAC_SYNC_N]
set_property PACKAGE_PIN T13 [get_ports DAC_SDI]
set_property IOSTANDARD LVCMOS33 [get_ports DAC_LDAC_N]
set_property IOSTANDARD LVCMOS33 [get_ports DAC_SCLK]
set_property IOSTANDARD LVCMOS33 [get_ports DAC_SDO]
set_property IOSTANDARD LVCMOS33 [get_ports DAC_SYNC_N]
set_property IOSTANDARD LVCMOS33 [get_ports DAC_SDI]

set_property PACKAGE_PIN N17 [get_ports DAC_DMTD_LDAC_N]
set_property PACKAGE_PIN K17 [get_ports DAC_DMTD_SCLK]
set_property PACKAGE_PIN N18 [get_ports DAC_DMTD_SDO]
set_property PACKAGE_PIN M17 [get_ports DAC_DMTD_SYNC_N]
set_property PACKAGE_PIN L18 [get_ports DAC_DMTD_SDI]
set_property IOSTANDARD LVCMOS33 [get_ports DAC_DMTD_LDAC_N]
set_property IOSTANDARD LVCMOS33 [get_ports DAC_DMTD_SCLK]
set_property IOSTANDARD LVCMOS33 [get_ports DAC_DMTD_SDO]
set_property IOSTANDARD LVCMOS33 [get_ports DAC_DMTD_SYNC_N]
set_property IOSTANDARD LVCMOS33 [get_ports DAC_DMTD_SDI]

#####################################################
#################### GTP Signals#####################
#####################################################
set_property PACKAGE_PIN U17 [get_ports {SFP_TX_DISABLE_O[0]}]
set_property PACKAGE_PIN V17 [get_ports {SFP_FAULT_I[0]}]
set_property PACKAGE_PIN P18 [get_ports {SFP_LOS_I[0]}]
set_property PACKAGE_PIN R18 [get_ports {SFP_MOD_DEF0_I[0]}]
set_property PACKAGE_PIN T18 [get_ports {SFP_MOD_DEF1_IO[0]}]
set_property PACKAGE_PIN T17 [get_ports {SFP_MOD_DEF2_IO[0]}]
set_property PACKAGE_PIN A3 [get_ports {SFP_RX_I_N[0]}]
set_property PACKAGE_PIN A4 [get_ports {SFP_RX_I_P[0]}]
set_property PACKAGE_PIN F1 [get_ports {SFP_TX_O_N[0]}]
set_property PACKAGE_PIN F2 [get_ports {SFP_TX_O_P[0]}]

#set_property PACKAGE_PIN N16 [get_ports { SFP_RATE_SELECT[0] } ]
set_property PACKAGE_PIN M15 [get_ports {SFP_TX_DISABLE_O[1]}]
set_property PACKAGE_PIN L14 [get_ports {SFP_FAULT_I[1]}]
set_property PACKAGE_PIN P15 [get_ports {SFP_LOS_I[1]}]
set_property PACKAGE_PIN T12 [get_ports {SFP_MOD_DEF0_I[1]}]
set_property PACKAGE_PIN N14 [get_ports {SFP_MOD_DEF1_IO[1]}]
set_property PACKAGE_PIN M14 [get_ports {SFP_MOD_DEF2_IO[1]}]
set_property PACKAGE_PIN G3 [get_ports {SFP_RX_I_N[1]}]
set_property PACKAGE_PIN G4 [get_ports {SFP_RX_I_P[1]}]
set_property PACKAGE_PIN B1 [get_ports {SFP_TX_O_N[1]}]
set_property PACKAGE_PIN B2 [get_ports {SFP_TX_O_P[1]}]
#set_property PACKAGE_PIN R13 [get_ports { SFP_RATE_SELECT[1] } ]

set_property IOSTANDARD LVCMOS33 [get_ports {SFP_TX_DISABLE_O[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SFP_FAULT_I[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SFP_LOS_I[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SFP_MOD_DEF0_I[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SFP_MOD_DEF1_IO[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SFP_MOD_DEF2_IO[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {SFP_RATE_SELECT[0]} ]
set_property IOSTANDARD LVCMOS33 [get_ports {SFP_TX_DISABLE_O[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SFP_FAULT_I[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SFP_LOS_I[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SFP_MOD_DEF0_I[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SFP_MOD_DEF1_IO[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SFP_MOD_DEF2_IO[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {SFP_RATE_SELECT[1]} ]

#####################################################
########################  LED  ######################
#####################################################
set_property PACKAGE_PIN H14 [get_ports {LED_GREEN_O[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED_GREEN_O[0]}]
set_property PACKAGE_PIN G14 [get_ports {LED_RED_O[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED_RED_O[0]}]
set_property PACKAGE_PIN H17 [get_ports {LED_GREEN_O[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED_GREEN_O[1]}]
set_property PACKAGE_PIN E18 [get_ports {LED_RED_O[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {LED_RED_O[1]}]

#####################################################
###################### UART #########################
#####################################################
set_property PACKAGE_PIN R16 [get_ports UART_RX_I]
set_property PACKAGE_PIN R17 [get_ports UART_TX_O]
set_property PACKAGE_PIN K15 [get_ports RESET_N]
set_property PACKAGE_PIN B17 [get_ports LOCK]
#set_property PACKAGE_PIN T15 [get_ports CLK_25M_BAK]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RX_I]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX_O]
set_property IOSTANDARD LVCMOS33 [get_ports RESET_N]
set_property IOSTANDARD LVCMOS25 [get_ports LOCK]
#set_property IOSTANDARD LVCMOS33 CLK_25M_BAK

#####################################################
###################### TIME #########################
#####################################################

set_property IOSTANDARD LVDS_25 [get_ports SYNC_CLK_10M_O_N]
set_property IOSTANDARD LVDS_25 [get_ports SYNC_CLK_10M_O_P]
set_property PACKAGE_PIN B9 [get_ports SYNC_CLK_10M_O_P]
set_property PACKAGE_PIN A9 [get_ports SYNC_CLK_10M_O_N]
set_property IOSTANDARD LVDS_25 [get_ports PPS_O_N]
set_property IOSTANDARD LVDS_25 [get_ports PPS_O_P]
set_property PACKAGE_PIN D8 [get_ports PPS_O_P]
set_property PACKAGE_PIN C8 [get_ports PPS_O_N]

#####################################################
################### Delay Chip#######################
#####################################################
set_property PACKAGE_PIN J18 [get_ports {DELAY_EN[0]}]
set_property PACKAGE_PIN K18 [get_ports {DELAY_SCLK[0]}]
set_property PACKAGE_PIN M16 [get_ports {DELAY_SLOAD[0]}]
set_property PACKAGE_PIN J14 [get_ports {DELAY_SDIN[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {DELAY_EN[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {DELAY_SCLK[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {DELAY_SLOAD[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {DELAY_SDIN[0]}]

#####################################################
###################### FLASH ########################
#####################################################
set_property PACKAGE_PIN L15 [get_ports QSPI_CS]
set_property IOSTANDARD LVCMOS33 [get_ports QSPI_CS]
set_property PACKAGE_PIN K16 [get_ports QSPI_DQ0]
set_property IOSTANDARD LVCMOS33 [get_ports QSPI_DQ0]
set_property PACKAGE_PIN L17 [get_ports QSPI_DQ1]
set_property IOSTANDARD LVCMOS33 [get_ports QSPI_DQ1]
#set_property PACKAGE_PIN J15 [get_ports QSPI_DQ2]
#set_property IOSTANDARD LVCMOS33 [get_ports QSPI_DQ2]
#set_property PACKAGE_PIN J16 [get_ports QSPI_DQ3]
#set_property IOSTANDARD LVCMOS33 [get_ports QSPI_DQ3]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]
set_property CONFIG_MODE SPIx1 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]

#####################################################
############### main PLL AD9516 #####################
#####################################################
set_property PACKAGE_PIN V9 [get_ports PLL_CS]
set_property PACKAGE_PIN U15 [get_ports PLL_REFSEL]
set_property PACKAGE_PIN U11 [get_ports PLL_RESET]
set_property PACKAGE_PIN V11 [get_ports PLL_SCLK]
set_property PACKAGE_PIN U10 [get_ports PLL_SDO]
set_property PACKAGE_PIN P16 [get_ports PLL_SYNC]
set_property PACKAGE_PIN U16 [get_ports PLL_LOCK]
set_property PACKAGE_PIN U9 [get_ports PLL_SDI]
set_property PACKAGE_PIN V16 [get_ports PLL_STAT]

set_property IOSTANDARD LVCMOS33 [get_ports PLL_CS]
set_property IOSTANDARD LVCMOS33 [get_ports PLL_REFSEL]
set_property IOSTANDARD LVCMOS33 [get_ports PLL_RESET]
set_property IOSTANDARD LVCMOS33 [get_ports PLL_SCLK]
set_property IOSTANDARD LVCMOS33 [get_ports PLL_SDO]
set_property IOSTANDARD LVCMOS33 [get_ports PLL_SYNC]
set_property IOSTANDARD LVCMOS33 [get_ports PLL_LOCK]
set_property IOSTANDARD LVCMOS33 [get_ports PLL_SDI]
set_property IOSTANDARD LVCMOS33 [get_ports PLL_STAT]

## NORMAL
create_clock -period 16.000 -name CLK_62M5_DMTD -waveform {0.000 8.000} [get_ports CLK_62M5_DMTD]
create_clock -period 8.000 -name MGTREFCLK0_P -waveform {0.000 4.000} [get_ports MGTREFCLK0_P]
create_clock -period 8.000 -name MGTREFCLK1_P -waveform {0.000 4.000} [get_ports MGTREFCLK1_P]
create_clock -period 8.000 -name clk_serdes_i -waveform {0.000 4.000} [get_ports FPGA_GCLK_P]
create_clock -period 16.000 -name RXOUTCLK0 -waveform {0.000 8.000} [get_pins {u_cute_a7_core/cmp_xwrc_platform/gen_phy_artix7.cmp_gtp/U_GTP_INST/gen_GT_INTS[0].GT_INST/gtpe2_i/RXOUTCLK}]
create_clock -period 16.000 -name TXOUTCLK0 -waveform {0.000 8.000} [get_pins {u_cute_a7_core/cmp_xwrc_platform/gen_phy_artix7.cmp_gtp/U_GTP_INST/gen_GT_INTS[0].GT_INST/gtpe2_i/TXOUTCLK}]
create_clock -period 16.000 -name RXOUTCLK1 -waveform {0.000 8.000} [get_pins {u_cute_a7_core/cmp_xwrc_platform/gen_phy_artix7.cmp_gtp/U_GTP_INST/gen_GT_INTS[1].GT_INST/gtpe2_i/RXOUTCLK}]
create_clock -period 16.000 -name TXOUTCLK1 -waveform {0.000 8.000} [get_pins {u_cute_a7_core/cmp_xwrc_platform/gen_phy_artix7.cmp_gtp/U_GTP_INST/gen_GT_INTS[1].GT_INST/gtpe2_i/TXOUTCLK}]
create_clock -period 16.000 -name clk_gtp_ref1_div2 -waveform {0.000 8.000} -add [get_nets -hierarchical *clk_gtp_ref1_div2*]

# set_property ASYNC_REG true [get_nets {u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/U_SOFTPLL/U_Wrapped_Softpll/gen_with_ext_clock_input.U_Aligner_EXT/cnt_in_gray_xd_reg_n_0_[*]}]

# set_property IOB TRUE [get_ports SYNC_CLK_10M_O_P]
# set_property IOB TRUE [get_ports PPS_O_P]

set_clock_groups -name g1 -asynchronous -group CLK_62M5_DMTD -group MGTREFCLK0_P
set_clock_groups -name g2 -asynchronous -group CLK_62M5_DMTD -group MGTREFCLK1_P
set_clock_groups -name g3 -asynchronous -group CLK_62M5_DMTD -group RXOUTCLK0
set_clock_groups -name g4 -asynchronous -group CLK_62M5_DMTD -group RXOUTCLK1
set_clock_groups -name g5 -asynchronous -group CLK_62M5_DMTD -group TXOUTCLK0
set_clock_groups -name g6 -asynchronous -group CLK_62M5_DMTD -group TXOUTCLK1
set_clock_groups -name g8 -asynchronous -group CLK_62M5_DMTD -group clk_serdes_i
set_clock_groups -name g9 -asynchronous -group CLK_62M5_DMTD -group clk_gtp_ref1_div2
set_clock_groups -name g10 -asynchronous -group clk_gtp_ref1_div2 -group CLK_62M5_DMTD
set_clock_groups -name g13 -asynchronous -group clk_serdes_i -group clk_gtp_ref1_div2
set_clock_groups -name g15 -asynchronous -group RXOUTCLK0 -group clk_gtp_ref1_div2
set_clock_groups -name g16 -asynchronous -group RXOUTCLK1 -group clk_gtp_ref1_div2

set_property ASYNC_REG true [get_cells {u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/U_SOFTPLL/U_Wrapped_Softpll/gen_ref_dmtds[0].DMTD_REF/gen_builtin.U_Sampler/gen_straight.clk_i_d3_reg}]
set_property ASYNC_REG true [get_cells {u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/U_SOFTPLL/U_Wrapped_Softpll/gen_ref_dmtds[2].DMTD_REF/gen_builtin.U_Sampler/gen_straight.clk_i_d3_reg}]
set_property ASYNC_REG true [get_cells {u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/U_SOFTPLL/U_Wrapped_Softpll/gen_ref_dmtds[1].DMTD_REF/gen_builtin.U_Sampler/gen_straight.clk_i_d3_reg}]
set_property ASYNC_REG true [get_cells {u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/U_SOFTPLL/U_Wrapped_Softpll/gen_ref_dmtds[3].DMTD_REF/gen_builtin.U_Sampler/gen_straight.clk_i_d3_reg}]

set_property LOC RAMB36_X2Y14 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram3_reg_0_7]
set_property LOC RAMB36_X1Y17 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram3_reg_0_6]
set_property LOC RAMB36_X2Y17 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram3_reg_0_5]
set_property LOC RAMB36_X2Y15 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram3_reg_0_4]
set_property LOC RAMB36_X1Y14 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram3_reg_0_3]
set_property LOC RAMB36_X2Y16 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram3_reg_0_2]
set_property LOC RAMB36_X1Y18 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram3_reg_0_1]
set_property LOC RAMB36_X1Y15 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram3_reg_0_0]
set_property LOC RAMB36_X1Y5 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram2_reg_0_7]
set_property LOC RAMB36_X2Y5 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram2_reg_0_6]
set_property LOC RAMB36_X2Y6 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram2_reg_0_5]
set_property LOC RAMB36_X1Y6 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram2_reg_0_4]
set_property LOC RAMB36_X2Y7 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram2_reg_0_3]
set_property LOC RAMB36_X2Y4 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram2_reg_0_2]
set_property LOC RAMB36_X1Y4 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram2_reg_0_1]
set_property LOC RAMB36_X1Y3 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram2_reg_0_0]
set_property LOC RAMB36_X1Y10 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram1_reg_0_7]
set_property LOC RAMB36_X0Y10 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram1_reg_0_6]
set_property LOC RAMB36_X0Y11 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram1_reg_0_5]
set_property LOC RAMB36_X0Y12 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram1_reg_0_4]
set_property LOC RAMB36_X1Y7 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram1_reg_0_3]
set_property LOC RAMB36_X0Y8 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram1_reg_0_2]
set_property LOC RAMB36_X0Y9 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram1_reg_0_1]
set_property LOC RAMB36_X0Y7 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram1_reg_0_0]
set_property LOC RAMB36_X2Y13 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram0_reg_0_7]
set_property LOC RAMB36_X2Y11 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram0_reg_0_6]
set_property LOC RAMB36_X2Y12 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram0_reg_0_5]
set_property LOC RAMB36_X1Y8 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram0_reg_0_4]
set_property LOC RAMB36_X1Y9 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram0_reg_0_3]
set_property LOC RAMB36_X2Y8 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram0_reg_0_2]
set_property LOC RAMB36_X2Y9 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram0_reg_0_1]
set_property LOC RAMB36_X1Y13 [get_cells u_cute_a7_core/cmp_board_cute_a7/cmp_xwr_core/WRPC/DPRAM/U_DPRAM/gen_splitram.U_RAM_SPLIT/ram0_reg_0_0]


set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
# set_property BITSTREAM.CONFIG.PERSIST YES [current_design]

set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE [current_design]
set_property BITSTREAM.CONFIG.TIMER_CFG 32'h002625A0 [current_design]

