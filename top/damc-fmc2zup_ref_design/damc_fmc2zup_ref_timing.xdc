
#set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets clk_200]

create_clock -name clk_20m_vcxo -period 50 [get_ports clk_20m_vcxo_i]
create_clock -name clk_125m_pllref -period 8 [get_ports clk_125m_pllref_p_i]
create_clock -name clk_125m_gtp -period 8 [get_ports clk_125m_gtp_p_i]
create_clock -name clk_200 -period 5 [get_ports clk_200_p]

# rename auto-generated clock to give specific name
# (see output of report_clock command for details)
#create_generated_clock -name wr_pll0_clk0 [get_pins {cmp_xwrc_board_damc_fmc2zup/cmp_xwrc_platform/gen_default_plls.gen_zynqultrascaleplus_default_plls.cmp_sys_clk_pll/CLKOUT0}] 

#set_false_path -to [get_pins {cmp_xwrc_board_damc_fmc2zup/cmp_board_common/cmp_xwr_core/WRPC/U_SOFTPLL/U_Wrapped_Softpll/gen_ref_dmtds[0].DMTD_REF/gen_straight.clk_i_d0_reg/D}]
#set_false_path -to [get_pins {cmp_xwrc_board_damc_fmc2zup/cmp_board_common/cmp_xwr_core/WRPC/U_SOFTPLL/U_Wrapped_Softpll/gen_feedback_dmtds[0].DMTD_FB/gen_straight.clk_i_d0_reg/D}]
#set_false_path -to [get_pins {cmp_xwrc_board_damc_fmc2zup/cmp_board_common/cmp_xwr_core/WRPC/U_SOFTPLL/U_Wrapped_Softpll/gen_feedback_dmtds[0].DMTD_FB/U_sync_tag_strobe/sync_posedge.sync0_reg/D}]

# set_clock_groups -asynchronous -group [get_clocks clk_pl_1] -group [get_clocks wr_pll0_clk0] -group [get_clocks clk_125m_pllref]
set_clock_groups -asynchronous -group [get_clocks clk_pl_1] -group [get_clocks clk_125m_pllref]

#set_clock_groups -asynchronous -group [get_clocks clk_20m_vcxo] -group [get_clocks clk_125m_pllref] -group [get_clocks clk_125m_gtp]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets cmp_ibufds_clk_200/O]
