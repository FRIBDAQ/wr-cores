# Call this from your makefile before hdlmake to generate .ip files for PLLs
# > cd ip_cores/wr-cores/platform/altera/wr_arria10_pll_default && bash ./gen_arria10_pll_default.sh
# Will generate PLL IPs specific for 10AX027H3F34E2SG's Idrogen board, but synthesys may correct that for your Arria10 FPGA.

qsys-script --script=arria10_dmtd_pll_default.tcl
qsys-script --script=arria10_ext_ref_pll_default.tcl
qsys-script --script=arria10_sys_pll_default.tcl
