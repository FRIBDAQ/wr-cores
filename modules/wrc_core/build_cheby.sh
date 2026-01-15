cheby -i wrc_cpu_csr.cheby --header=commit --gen-hdl wrc_cpu_csr.vhd --gen-c wrc_cpu_csr.h
cheby -i wrc_devices_map.cheby --header=commit --gen-hdl wrc_devices_map.vhd
cheby -i wrc_host_map.cheby --header=commit --gen-hdl wrc_host_map.vhd --gen-c wrc_host_map.h
cheby -i wrc_syscon_map.cheby --header=commit --gen-hdl wrc_syscon_map.vhd --gen-c wrc_syscon_map.h
