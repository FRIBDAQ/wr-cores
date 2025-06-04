#!/bin/bash

cheby -i auxclk_regs.cheby --gen-hdl auxclk_regs.vhd
cheby -i auxclk_regs.cheby --gen-c auxclk_gen.h
cheby -i auxclk_regs.cheby --gen-consts ../../sim/regs/auxclk_regs.sv
