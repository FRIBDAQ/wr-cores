#!/bin/bash

cheby -i timecode_regs.cheby --gen-hdl timecode_regs.vhd
cheby -i timecode_regs.cheby --gen-c timecode_regs.h
cheby -i timecode_regs.cheby --consts-style=vhdl --gen-consts timecode_consts.vhd 
