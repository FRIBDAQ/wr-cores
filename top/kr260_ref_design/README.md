KR260 demo board
================

Build
=====

Install Ubuntu 22.04.4 LTS on the kria board.

Use vivado 2024.2

$ hdlmake
$ make project
$ vivado
Generate the bitstream, program the board
Compile wrpc-sw tools on the board, and load firmware


HW notes
========

refclk0 is 156.25Mhz (*8 = 1250Mhz)
  SOM240_2 C3/C4 FPGA:Y6/Y5
refclk1 is 74.25Mhz
  SOM240_2 A7/A8 FPGA:V5/V6

sfp+ is connected to
  gth_dp2_*
  SOM240_2m JA2B B1/B2/B5/B6
  FPGA T2/T1/R4/R3
  MGTH 2_224

MGTH 0 and 1 connected to J22 connector.
MGTH 3 is not connected.

sfp led:
1_a12 FPGA:G8
1_a13 FPGA:F7

sfp i2c:
 sda: 2_b50 FPGA:AC11
 scl: 2_b49 FPGA:AB11

sfp others:
 tx_fault:   hda19 1_c23  FPGA:A10
 tx_disable: hdb19 2_a47  FPGA:Y10
 mod_abs:    hdb18 2_a46  FPGA:W10

clock: hpa_clk0p_clk 25_000_000 (1v8)
  1_a6 FPGA:C3
  2_d18 FPGA:L3

uart on the USB is UART1. Uboot and linux use 115200-8-n1

AXI bus at 0x8000_0000

PMOD4:         SOM2      FPGA (LVCMOS33)
 1-2   HDB08-HDB12    C48-B44   AC12-AD11
 3-4   HDB09-HDB13    C50-B45   AD12-AD10
 5-6   HDB10-HDB14    C51-B46   AE10-AA11
 7-8   HDB11-HDB15    C52-B48   AF10-AA10
 9-10  GND  -GNA
11-12  3V3  -3V3

Docs:
=====

Xilinx ds987
https://github.com/Xilinx/XilinxBoardStore/blob/035e9055a6a88989048b9a22b2a372035a4c2d1d/boards/Xilinx/kr260_som/1.1/part0_pins.xml
https://github.com/Xilinx/XilinxBoardStore/blob/2022.2/boards/Xilinx/kr260_carrier/1.0/board.xml

Linux (Ubuntu)
==============

https://xilinx.github.io/kria-apps-docs/kr260/build/html/docs/linux_boot.html

Default login is 'ubuntu'.

eth1 is top right.

TODO: xmutil

wrpc tool
=========

They should be built on the board.

$ sudo ./wrpc info -b host -b 0x80000000
hwfr=00000000:  memsize: 16kB,  storage: 0, storage sector size: 0kB
hwir=4b523236:  KR26

devmem2
=======

Play with leds:

$ sudo devmem2 0x80001000 w 2


loading bitstream
=================

'xmutil' is a wrapper, calls dfx-mgr-client for applications

echo top.bit.bin > /sys/class/fpga_manager/fpga0/firmware


QPLL
====

According to ug576 v1.7.1 p 51, both QPLL are fractional PLLs

QPLL0 is used for the main gthe4 while QPLL1 is used for the helper frequency
(through a second gthe4).

As the fractional PLL can only increase the frequency, a negative offset is added to the frequency through TXPIPPM.
