###############################################################################
## SPDX-FileCopyrightText: 2026 Missing Link Electronics(missinglinkelectronics.com)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
set module_name {gtwizard_v1_7_gthe4_sdm_dmtd}

set_part ${device}
create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name "${module_name}"

set_property CONFIG.preset {GTH-Gigabit_Ethernet} [get_ips "${module_name}"]
set_property -dict [list \
  CONFIG.CHANNEL_ENABLE {X0Y7 X0Y6} \
  CONFIG.ENABLE_OPTIONAL_PORTS {sdm0data_in sdm0toggle_in sdm1data_in sdm1toggle_in txpllclksel_in txoutclk_out} \
  CONFIG.LOCATE_RX_USER_CLOCKING {CORE} \
  CONFIG.LOCATE_TX_USER_CLOCKING {CORE} \
  CONFIG.RX_MASTER_CHANNEL {X0Y7} \
  CONFIG.RX_REFCLK_SOURCE {X0Y7 clk1+1 X0Y6 clk1+1} \
  CONFIG.SECONDARY_QPLL_ENABLE {true} \
  CONFIG.SECONDARY_QPLL_FRACN_NUMERATOR {261990} \
  CONFIG.SECONDARY_QPLL_LINE_RATE {1.25} \
  CONFIG.RX_REFCLK_FREQUENCY {125} \
  CONFIG.TX_REFCLK_SOURCE {X0Y7 clk0+1 X0Y6 clk0+1} \
  CONFIG.TXPROGDIV_FREQ_ENABLE {true} \
  CONFIG.TXPROGDIV_FREQ_VAL {62.5} \
  CONFIG.TX_MASTER_CHANNEL {X0Y7} \
  CONFIG.TX_OUTCLK_SOURCE {TXPROGDIVCLK} \
  CONFIG.TX_PLL_TYPE {QPLL0} \
  CONFIG.TX_REFCLK_FREQUENCY {125} \
] [get_ips "${module_name}"]
# The fractional QPLL setting is not supported for inital parameter changes
set_property -dict [list \
  CONFIG.RX_REFCLK_FREQUENCY {125} \
  CONFIG.TX_REFCLK_FREQUENCY {124.975605} \
  CONFIG.SECONDARY_QPLL_REFCLK_FREQUENCY {124.975605} \
  CONFIG.TX_QPLL_FRACN_NUMERATOR {261990} \
] [get_ips "${module_name}"]

unset module_name
