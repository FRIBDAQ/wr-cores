###############################################################################
## SPDX-FileCopyrightText: 2025 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################
import logging

if 'target' not in globals():
        logging.info("'target' is not defined, no platform selected")
elif target=="altera":
	modules = {"local" : "altera"}
elif target=="xilinx":
	modules = {"local" : "xilinx"}
