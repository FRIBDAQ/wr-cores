set module_name {gtwizard_v1_7_gthe4_sdm_eth}

create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name "${module_name}"

set_property CONFIG.preset {GTH-Gigabit_Ethernet} [get_ips "${module_name}"]
set_property -dict [list \
  CONFIG.CHANNEL_ENABLE {X1Y12} \
  CONFIG.RX_MASTER_CHANNEL {X1Y12} \
  CONFIG.TX_MASTER_CHANNEL {X1Y12} \
  CONFIG.TX_BUFFER_MODE {0} \
  CONFIG.RX_BUFFER_MODE {0} \
  CONFIG.RX_SLIDE_MODE {PCS} \
  CONFIG.ENABLE_OPTIONAL_PORTS {drpclk_in sdm0data_in sdm0toggle_in} \
  CONFIG.LOCATE_IN_SYSTEM_IBERT_CORE {EXAMPLE_DESIGN} \
  CONFIG.LOCATE_TX_USER_CLOCKING {CORE} \
  CONFIG.LOCATE_RX_USER_CLOCKING {CORE} \
] [get_ips "${module_name}"]

generate_target all [get_ips "${module_name}"]
catch { config_ip_cache -export [get_ips "${module_name}"] }
export_ip_user_files -of_objects [get_ips "${module_name}"] -no_script -sync -force -quiet
create_ip_run [get_ips "${module_name}"]

unset module_name
