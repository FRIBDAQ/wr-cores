###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name gtwizard_ultrascale_0
set_property CONFIG.preset {GTH-Gigabit_Ethernet} [get_ips gtwizard_ultrascale_0]
set_property -dict [list \
  CONFIG.CHANNEL_ENABLE {X0Y4} \
  CONFIG.RX_MASTER_CHANNEL {X0Y4} \
  CONFIG.TX_MASTER_CHANNEL {X0Y4} \
  CONFIG.RX_BUFFER_MODE {0} \
  CONFIG.TX_BUFFER_MODE {0} \
  CONFIG.TX_OUTCLK_SOURCE {TXPROGDIVCLK} \
  CONFIG.LOCATE_IN_SYSTEM_IBERT_CORE {EXAMPLE_DESIGN} \
  CONFIG.RX_DATA_DECODING {RAW} \
  CONFIG.RX_USER_DATA_WIDTH {20} \
  CONFIG.TX_DATA_ENCODING {RAW} \
  CONFIG.TX_USER_DATA_WIDTH {20} \
  CONFIG.LOCATE_RX_USER_CLOCKING {CORE} \
  CONFIG.LOCATE_TX_USER_CLOCKING {CORE} \
  CONFIG.RX_COMMA_M_ENABLE {false} \
  CONFIG.RX_COMMA_P_ENABLE {false} \
  CONFIG.RX_SLIDE_MODE {PCS} \
  CONFIG.ENABLE_OPTIONAL_PORTS {cpllrefclksel_in loopback_in rxresetdone_out txresetdone_out} \
] [get_ips gtwizard_ultrascale_0]
generate_target all [get_files gtwizard_ultrascale_0.xci]
# export_ip_user_files -of_objects [get_files gtwizard_ultrascale_0.xci] -no_script -sync -force -quiet
