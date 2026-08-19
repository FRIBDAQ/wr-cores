create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name gthe4_phy
set_property CONFIG.preset {GTH-Gigabit_Ethernet} [get_ips gthe4_phy]
#  ---- Deterministic RX latency (RXPI + LPDC combine) ----
#  RX elastic buffer BYPASSED (RX_BUFFER_MODE 0) so RX latency is fixed; the
#  comma is aligned to a constant tap in FABRIC (gtx_comma_detect_lp barrel-shift)
#  and decoded by fabric gc_dec_8b10b in rxpi_lp_adapter.  RX is RAW 20-bit;
#  TX stays GT-INTERNAL 8b10b (16-bit, buffered).  NOTE: a fabric-RAW TX with
#  TX_BUFFER_MODE 1 was tried and made things WORSE (peer could not even hold
#  the comma; errors saturated) -- the reference's RAW TX needs TX_BUFFER 0 +
#  TXPROGDIVCLK, which would move txoutclk (= WR refclk that TXPI/SoftPLL ride
#  on).  GT-internal TX frames correctly (comma stable at tap 0, K28.5+D2.2
#  clean), so it is kept.  RX_SLIDE_MODE PCS matches
#  the proven GTHE4-LPDC reference: it configures the RX PCS gearbox that frames
#  the 20-bit raw word so gtx_comma_detect_lp can find the comma; rxslide itself
#  is tied '0' (alignment is the fabric barrel-shift).  (OFF frames differently
#  and the comma detector never aligns.)  RXOUTCLK from PMA (post-bypass).
#  Buffbypass controller located in CORE -> exposes gtwiz_buffbypass_rx_* ports
#  that the board must wire (was hardcoded).
set_property -dict [list \
  CONFIG.CHANNEL_ENABLE {X0Y6} \
  CONFIG.LOCATE_RX_USER_CLOCKING {EXAMPLE_DESIGN} \
  CONFIG.LOCATE_TX_USER_CLOCKING {EXAMPLE_DESIGN} \
  CONFIG.LOCATE_COMMON {EXAMPLE_DESIGN} \
  CONFIG.LOCATE_RESET_CONTROLLER {EXAMPLE_DESIGN} \
  CONFIG.RX_MASTER_CHANNEL {X0Y6} \
  CONFIG.TX_MASTER_CHANNEL {X0Y6} \
  CONFIG.RX_PLL_TYPE {QPLL0} \
  CONFIG.TX_PLL_TYPE {QPLL0} \
  CONFIG.RX_QPLL_FRACN_NUMERATOR {6871} \
  CONFIG.TX_QPLL_FRACN_NUMERATOR {6871} \
  CONFIG.TX_REFCLK_SOURCE {} \
  CONFIG.RX_REFCLK_SOURCE {} \
  CONFIG.TX_OUTCLK_SOURCE {TXOUTCLKPMA} \
  CONFIG.TX_BUFFER_MODE {1} \
  CONFIG.RX_REFCLK_FREQUENCY {156.2495001} \
  CONFIG.TX_REFCLK_FREQUENCY {156.2495001} \
  CONFIG.RX_COMMA_SHOW_REALIGN_ENABLE {false} \
  CONFIG.RX_BUFFER_MODE {0} \
  CONFIG.RX_OUTCLK_SOURCE {RXOUTCLKPMA} \
  CONFIG.RX_SLIDE_MODE {PCS} \
  CONFIG.RX_DATA_DECODING {RAW} \
  CONFIG.RX_USER_DATA_WIDTH {20} \
  CONFIG.RX_COMMA_M_ENABLE {false} \
  CONFIG.RX_COMMA_P_ENABLE {false} \
  CONFIG.LOCATE_RX_BUFFER_BYPASS_CONTROLLER {CORE} \
  CONFIG.ENABLE_OPTIONAL_PORTS {dmonitorclk_in drpaddr_in drpclk_in drpdi_in drpen_in drpwe_in rxbufreset_in rxpcsreset_in rxpd_in rxpmareset_in txpcsreset_in txpd_in txpippmen_in txpippmovrden_in txpippmpd_in txpippmsel_in txpippmstepsize_in txpllclksel_in txpmareset_in dmonitorout_out dmonitoroutclk_out drpdo_out drprdy_out} \
] [get_ips gthe4_phy]
generate_target {instantiation_template} [get_files gthe4_phy.xci]
