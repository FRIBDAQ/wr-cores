###############################################################################
## SPDX-FileCopyrightText: 2026 CERN (home.cern)
##
## SPDX-License-Identifier: LGPL-2.1-or-later
###############################################################################

if (syn_device[0:4].upper()=="XCZU" or  # Zynq Ultrascale GTH
      syn_device[0:5].upper()=="XCK26"):  # Kria K26
    files = [
        "gthe4_sdm.vhd",
        "rxpi_gthe4_map.vhd",
        "xwrc_gthe4_rxpi.vhd",
        #  Deterministic-latency RX adapter (RX buffer bypass + fixed comma tap),
        #  replaces wr_gthe4_adapter in the board.  RX is RAW with fabric 8b10b
        #  decode (gc_dec); TX stays GT-internal 8b10b.
        "rxpi_lp_adapter.vhd",
        #  Local copies (identical) of 7Series/GTXE2-LPDC gtx_comma_detect_lp
        #  and general-cores gc_dec_8b10b, so this platform dir is
        #  self-contained for the CTS build flow.
        "gtx_comma_detect_lp.vhd",
        "gc_dec_8b10b.vhd",
    ]

