#!/bin/bash
##-----------------------------------------------------------------------------
## SPDX-FileCopyrightText:2022 Nikhef (www.nikhef.nl/en/)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
##-----------------------------------------------------------------------------

mkdir -p doc
wbgen2.exe -D ./doc/sit5359_id_wb.html -C sit5359_regs.h -p sit5359_regs_pkg.vhd -H record -V sit5359_if_wb.vhd --cstyle defines --lang vhdl sit5359_if_wb.wb