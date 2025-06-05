create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name gthe4_sdm_helper
set_property CONFIG.preset {GTH-Gigabit_Ethernet} [get_ips gthe4_sdm_helper]
set_property -dict [list \
  CONFIG.CHANNEL_ENABLE {X0Y7} \
  CONFIG.LOCATE_RX_USER_CLOCKING {CORE} \
  CONFIG.LOCATE_TX_USER_CLOCKING {CORE} \
  CONFIG.RX_MASTER_CHANNEL {X0Y7} \
  CONFIG.RX_PLL_TYPE {QPLL1} \
  CONFIG.RX_REFCLK_SOURCE {} \
  CONFIG.RX_SLIDE_MODE {PCS} \
  CONFIG.TX_MASTER_CHANNEL {X0Y7} \
  CONFIG.TX_OUTCLK_SOURCE {TXPROGDIVCLK} \
  CONFIG.TX_PLL_TYPE {QPLL1} \
  CONFIG.TX_REFCLK_SOURCE {} \
  CONFIG.RX_BUFFER_MODE {0} \
  CONFIG.TX_BUFFER_MODE {0} \
  CONFIG.RX_REFCLK_FREQUENCY {156.25} \
  CONFIG.RX_REFCLK_SOURCE {} \
  CONFIG.TX_REFCLK_FREQUENCY {156.25} \
  CONFIG.ENABLE_OPTIONAL_PORTS {} \
  CONFIG.LOCATE_COMMON {EXAMPLE_DESIGN} \
] [get_ips gthe4_sdm_helper]
generate_target {instantiation_template} [get_files /home/tgingold/Repositories/ohwr/wr-cores-kria/syn/kr260_ref_design/kr260_ref_top.srcs/sources_1/ip/gthe4_sdm_helper/gthe4_sdm_helper.xci]
