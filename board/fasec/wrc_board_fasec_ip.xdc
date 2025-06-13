create_clock -period 50.000 -name clk_20m_vcxo -waveform {0.000 25.000} [get_ports clk_20m_vcxo_i]
create_clock -period 8.000 -name clk_125m_pllref -waveform {0.000 4.000} [get_ports clk_125m_pllref_p_i]
create_clock -period 8.000 -name clk_125m_gtp -waveform {0.000 4.000} [get_ports clk_125m_gtp_p_i]
create_clock -period 100.000 -name clk_10m_ext -waveform {0.000 50.000} [get_ports clk_10m_ext_i]
create_clock -period 16.000 -name clk_gtx_rx -waveform {0.000 8.000} [get_pins cmp_xwrc_board_fasec/cmp_xwrc_platform/gen_phy_kintex7.cmp_gtx/U_GTX_INST/gtxe2_i/RXOUTCLK]

set_clock_groups -asynchronous -group [get_clocks clk_gtx_rx] -group [get_clocks gen_default_plls.gen_kintex7_artix7_default_plls.clk_dmtd]

set_clock_groups -asynchronous -group [get_clocks clk_sys] -group [get_clocks clk_gtx_rx]
