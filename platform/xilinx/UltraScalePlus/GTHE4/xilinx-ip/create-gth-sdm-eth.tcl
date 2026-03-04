###############################################################################
## SPDX-FileCopyrightText: 2026 Missing Link Electronics(missinglinkelectronics.com)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
set module_name {gtwizard_v1_7_gthe4_sdm_eth}

set_part ${device}
create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name "${module_name}"

set_property CONFIG.preset {GTH-Gigabit_Ethernet} [get_ips "${module_name}"]
set_property -dict [list \
  CONFIG.CHANNEL_ENABLE {X1Y14} \
  CONFIG.RX_MASTER_CHANNEL {X1Y14} \
  CONFIG.TX_MASTER_CHANNEL {X1Y14} \
  CONFIG.TX_BUFFER_MODE {0} \
  CONFIG.RX_BUFFER_MODE {0} \
  CONFIG.RX_SLIDE_MODE {PCS} \
  CONFIG.ENABLE_OPTIONAL_PORTS {drpclk_in rxpcsreset_in sdm0data_in sdm0toggle_in} \
  CONFIG.LOCATE_IN_SYSTEM_IBERT_CORE {EXAMPLE_DESIGN} \
  CONFIG.LOCATE_TX_USER_CLOCKING {CORE} \
  CONFIG.LOCATE_RX_USER_CLOCKING {CORE} \
  CONFIG.RX_PLL_TYPE {QPLL1} \
  CONFIG.RX_QPLL_FRACN_NUMERATOR {261990} \
  CONFIG.RX_REFCLK_FREQUENCY {124.975605} \
  CONFIG.RX_REFCLK_SOURCE {} \
  CONFIG.TXPROGDIV_FREQ_ENABLE {true} \
  CONFIG.TX_PLL_TYPE {QPLL0} \
  CONFIG.TX_QPLL_FRACN_NUMERATOR {261990} \
  CONFIG.TX_REFCLK_FREQUENCY {124.975605} \

] [get_ips "${module_name}"]

unset module_name
