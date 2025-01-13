#!/bin/bash

cheby -i nmea_master_regs.cheby --gen-hdl nmea_master_regs.vhd
cheby -i nmea_master_regs.cheby --gen-c nmea_master.h
