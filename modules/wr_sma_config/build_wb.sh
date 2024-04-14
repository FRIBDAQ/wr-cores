#!/bin/bash

mkdir -p doc
/home/fpga/workspace/wr-tool/wishbone-gen/wbgen2 -D ./doc/sma_config.html -C sma_config_regs.h -V sma_config_wb_slave.vhd -p sma_config_wbgen2_pkg.vhd --cstyle struct  --lang vhdl -H record sma_config.wb
