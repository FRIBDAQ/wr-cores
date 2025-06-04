create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name gthe4_sdm
set_property CONFIG.preset {GTH-Gigabit_Ethernet} [get_ips gthe4_sdm]
set_property -dict [list \
  CONFIG.CHANNEL_ENABLE {X0Y6} \
  CONFIG.ENABLE_OPTIONAL_PORTS {sdm0data_in sdm0toggle_in sdm0width_in} \
  CONFIG.LOCATE_RX_USER_CLOCKING {CORE} \
  CONFIG.LOCATE_TX_USER_CLOCKING {CORE} \
  CONFIG.RX_MASTER_CHANNEL {X0Y6} \
  CONFIG.RX_PLL_TYPE {QPLL0} \
  CONFIG.RX_QPLL_FRACN_NUMERATOR {6871} \
  CONFIG.RX_REFCLK_SOURCE {} \
  CONFIG.RX_SLIDE_MODE {PCS} \
  CONFIG.TX_MASTER_CHANNEL {X0Y6} \
  CONFIG.TX_OUTCLK_SOURCE {TXPROGDIVCLK} \
  CONFIG.TX_PLL_TYPE {QPLL0} \
  CONFIG.TX_QPLL_FRACN_NUMERATOR {6871} \
  CONFIG.TX_REFCLK_SOURCE {} \
  CONFIG.RX_BUFFER_MODE {0} \
  CONFIG.TX_BUFFER_MODE {0} \
  CONFIG.ENABLE_OPTIONAL_PORTS {sdm0data_in sdm0reset_in sdm0toggle_in sdm0width_in qpll0lock_out} \
  CONFIG.RX_REFCLK_FREQUENCY {156.2495001} \
  CONFIG.RX_REFCLK_SOURCE {} \
  CONFIG.TX_REFCLK_FREQUENCY {156.2495001} \
] [get_ips gthe4_sdm]
generate_target {instantiation_template} [get_files /home/tgingold/Repositories/ohwr/wr-cores-kria/syn/kr260_ref_design/kr260_ref_top.srcs/sources_1/ip/gthe4_sdm/gthe4_sdm.xci]
