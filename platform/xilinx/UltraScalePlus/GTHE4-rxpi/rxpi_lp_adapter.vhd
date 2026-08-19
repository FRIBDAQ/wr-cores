-------------------------------------------------------------------------------
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
-- Title      : RXPI + LPDC deterministic-latency RX adapter (GTHE4, UltraScale+)
-- Project    : White Rabbit / CTS KR260 RXPI
-------------------------------------------------------------------------------
-- Description:
--   Drop-in replacement for wr_gthe4_adapter in the CTS RXPI board, adding
--   DETERMINISTIC RX latency the LPDC way (see doc/lpdc-rxpi-phase-matching.md),
--   self-contained so the EXISTING pure-RXPI firmware works unchanged:
--
--     * RX path is RAW 20-bit (GT internal 8b10b + RX elastic buffer BYPASSED).
--       gtx_comma_detect_lp finds the K28.5 comma position and barrel-shifts the
--       word to g_comma_target_pos; it only asserts 'aligned' when the comma
--       actually SITS at the target tap -- it does NOT itself move the comma.
--
--     * COMMA STEERING (the piece the reverted attempt proved necessary on CTS,
--       doc wall #6/#7): on CTS the comma lands on a parity that is FIXED per
--       power-cycle (98% odd), so rx-reset re-rolls cannot change it and a
--       barrel-shift to an odd target corrupts the /C1//C2/ marker.  The only
--       cure is to bit-slip the comma to the EVEN tap 0 with PCS rxslide.  This
--       module contains a fabric FSM that pulses gth_rx_slide_o until the comma
--       reaches tap 0 (link_up && !aligned => slip, wait for re-acquire, repeat;
--       comma_pos is mod-20 so <=20 slips reach 0 regardless of slip direction).
--       Once at tap 0 the decode is clean and 'aligned' asserts.
--
--     * With the buffer bypassed and the comma pinned to tap 0 every relink, RX
--       latency is constant => the coarse per-relink PPS ambiguity is removed.
--
--     * rdy_o asserts only when aligned; the RXPI map turns that into
--       STATUS.PHY_READY, which the firmware waits on.  bitslide_o = 0.
--       comma_pos_o exports the current comma tap for diagnostics.
--
--     * TX path is UNCHANGED: GT-internal 8b10b (16-bit, buffered) -- byte-swap
--       + disparity, like wr_gthe4_rxtx_adapter.  It frames correctly (peer
--       holds comma at tap 0, K28.5+D2.2 decode clean).  A fabric-RAW TX with
--       TX_BUFFER_MODE 1 was tried and made the peer unable to hold the comma
--       at all (the reference's RAW TX needs TX_BUFFER 0 + TXPROGDIVCLK, which
--       would move txoutclk = the WR refclk) -- reverted.  TX phase determinism
--       is the TXPIPPM actuator in xwrc_gthe4_rxpi.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.disparity_gen_pkg.all;

entity rxpi_lp_adapter is
  generic (
    --  Fabric comma alignment target tap (0..19).  0 = proven even boundary.
    g_comma_target_pos : std_logic_vector(4 downto 0) := "00000";
    --  rxclk cycles to wait after each rxslide for the comma detector to
    --  re-acquire (must exceed gtx_comma_detect_lp's sync-loss + sync-up
    --  windows, ~1500) before deciding whether to slip again.
    g_slide_settle     : natural := 2048
    );
  port (
    -- TX path (16-bit, not 8b10b-encoded), synchronous to gth_tx_clk_i
    tx_data_i      : in  std_logic_vector(15 downto 0);
    tx_k_i         : in  std_logic_vector(1 downto 0);
    tx_disparity_o : out std_logic;
    tx_enc_err_o   : out std_logic;

    -- RX path (16-bit, 8b10b-decoded), synchronous to gth_rx_clk_i
    rx_data_o     : out std_logic_vector(15 downto 0);
    rx_k_o        : out std_logic_vector(1 downto 0);
    rx_enc_err_o  : out std_logic;

    -- RX bitslide: number of PCS rxslide pulses issued to steer the comma to
    -- tap 0, MOD 10 (the GTHE4 PCS slide latency wraps at the 10-bit symbol --
    -- HW-measured).  Each slide shifts RX latency by 1 UI (800ps), and the
    -- comma's natural landing is random per CDR lock, so this count is the
    -- per-relink UI-grained RX latency term.  The board feeds it to the
    -- endpoint (MDIO WR_SPEC.BSLIDE); PPSi announces/compensates it as a
    -- known fixed delay -- same mechanism as the classic WR gtp_bitslide.
    rx_bitslide_o : out std_logic_vector(4 downto 0);

    -- reset input, active hi
    rst_i : in std_logic;
    -- comma-detector / slide-FSM reset (board RX reset), active hi; re-pins
    -- framing on every relink
    comma_rst_i : in std_logic;

    -- GTH ready & synced (clocked by gth_rx_clk_i): serdes ready AND aligned
    rdy_o : out std_logic;

    -- GT reset / RX-buffer-bypass "done" strobes (board-driven), gate serdes
    -- ready.  (TX buffer stays enabled so there is no TX buffbypass.)
    gt_reset_tx_done_i      : in std_logic;
    gt_reset_rx_done_i      : in std_logic;
    gt_buffbypass_rx_done_i : in std_logic;
    -- GT RX CDR lock (rxcdrlock).  Drops on fiber unplug; gating serdes ready
    -- on it makes PHY_READY fall so the firmware sees link-down and re-runs the
    -- full align/AN sequence on replug.  (In the RAW datapath the fabric comma
    -- detector cannot be relied on to drop: a free-running CDR can keep it
    -- "aligned", which left the link stuck after the first unplug.)
    gt_rx_cdr_lock_i        : in std_logic := '1';

    -- Interface to the GT primitive: RX RAW 20-bit (fabric 8b10b decode);
    -- TX GT-internal 8b10b (16-bit data + K flags).
    gth_rx_data_i : in  std_logic_vector(19 downto 0);
    gth_tx_data_o : out std_logic_vector(15 downto 0);
    gth_tx_k_o    : out std_logic_vector(1 downto 0);
    -- PCS bitslip to the GT (rxslide), driven by the comma-steering FSM
    gth_rx_slide_o : out std_logic;
    gth_rx_clk_i  : in  std_logic;
    gth_tx_clk_i  : in  std_logic;

    -- Current comma tap position (gth_rx_clk_i domain), for diagnostics
    comma_pos_o : out std_logic_vector(4 downto 0);

    -- Decode diagnostics (gth_rx_clk_i domain), in rxpi_gthe4_map bitslide[31:8]
    -- (bitslide bit = dbg bit + 8):
    --  [4:0]  = current comma tap (0 = the only clean pass-through tap)
    --  [5]    = aligned
    --  [9:6]  = 8b10b errors in the last ~0.13s window, counted only while
    --           aligned (saturating 0..15); 0 = clean decode
    --  [19:10]= raw 10 bits of the last symbol that failed while aligned
    dbg_o : out std_logic_vector(23 downto 0)
    );
end rxpi_lp_adapter;

architecture rtl of rxpi_lp_adapter is

  component gtx_comma_detect_lp is
    generic (
      g_ID : integer);
    port (
      clk_rx_i            : in  std_logic;
      rst_i               : in  std_logic;
      rx_data_raw_i       : in  std_logic_vector(19 downto 0);
      rx_data_raw_o       : out std_logic_vector(19 downto 0);
      comma_target_pos_i  : in  std_logic_vector(4 downto 0);
      comma_current_pos_o : out std_logic_vector(4 downto 0);
      comma_pos_valid_o   : out std_logic;
      link_up_o           : out std_logic;
      aligned_o           : out std_logic);
  end component gtx_comma_detect_lp;

  component gc_dec_8b10b is
    port (
      clk_i       : in  std_logic;
      rst_n_i     : in  std_logic;
      in_10b_i    : in  std_logic_vector(9 downto 0);
      ctrl_o      : out std_logic;
      code_err_o  : out std_logic;
      rdisp_err_o : out std_logic;
      out_8b_o    : out std_logic_vector(7 downto 0));
  end component gc_dec_8b10b;


  signal rst_n                              : std_logic;
  signal rst_rxclk_n                        : std_logic;
  signal serdes_ready_a, serdes_ready_rxclk : std_logic;

  signal rx_data_raw, rx_data_decode        : std_logic_vector(19 downto 0);
  signal rx_data_int                        : std_logic_vector(15 downto 0);
  signal rx_k_int                           : std_logic_vector(1 downto 0);
  signal rx_code_err                        : std_logic_vector(1 downto 0);

  signal comma_cur_pos                                 : std_logic_vector(4 downto 0);
  signal comma_aligned, comma_link_up, comma_pos_valid : std_logic;

  --  Comma-steering FSM
  type t_slide_state is (SLIDE_IDLE, SLIDE_PULSE, SLIDE_WAIT);
  signal slide_state : t_slide_state;
  signal slide_cnt   : unsigned(15 downto 0);
  signal rx_slide    : std_logic;
  signal slide_done  : std_logic;
  --  Slides issued since comma_rst, MOD 10: HW-measured (2026-08-19, 8-relink
  --  crtt dataset) -- the GTHE4 PCS slide latency wraps at the 10-bit SYMBOL,
  --  not the 20-bit word: actual added RX latency = (n mod 10) UI.  Announcing
  --  n=11/18 raw over-corrected crtt by exactly 10 UI (8.0ns); n mod 10 fits
  --  all points to +/-100ps.
  signal slide_count : unsigned(4 downto 0);

  signal cur_disp                           : t_8b10b_disparity;

  --  Decode diagnostics, in bitslide[31:8]:
  --   [12:8]  = current comma tap (0 = the only clean pass-through tap)
  --   [13]    = aligned
  --   [17:14] = 8b10b errors in the last ~0.13s window, counted ONLY while
  --             aligned (saturating 0..15).  0 = clean decode.  NOTE: the
  --             previous probe never cleared and counted during pre-alignment
  --             (misframed by definition), so it read 15 even on a good link.
  --   [27:18] = raw 10 bits of the last symbol that failed while aligned
  signal dbg_lat    : std_logic_vector(23 downto 0);
  signal dbg_hi     : std_logic_vector(9 downto 0);
  signal err_cnt    : unsigned(3 downto 0);
  signal err_win    : unsigned(3 downto 0);
  signal win_cnt    : unsigned(22 downto 0);

begin

  rst_n <= not rst_i;

  ---------------------------------------------------------------------------
  -- Decode diagnostics: current comma tap + aligned + error rate, and the raw
  -- 10 bits of the last failing symbol.  Correlates tap parity with errors.
  ---------------------------------------------------------------------------
  p_dbg : process(gth_rx_clk_i)
  begin
    if rising_edge(gth_rx_clk_i) then
      if comma_rst_i = '1' then
        err_cnt <= (others => '0');
        err_win <= (others => '0');
        win_cnt <= (others => '0');
        dbg_hi  <= (others => '0');
        dbg_lat <= (others => '0');
      else
        --  Count decode errors ONLY while aligned: before the comma sits at
        --  tap 0 the word is misframed by definition and errors are expected.
        if serdes_ready_rxclk = '1' and comma_aligned = '1'
           and (rx_code_err(0) = '1' or rx_code_err(1) = '1') then
          if rx_code_err(1) = '1' then
            dbg_hi <= rx_data_decode(19 downto 10);
          else
            dbg_hi <= rx_data_decode(9 downto 0);
          end if;
          if err_cnt /= 15 then err_cnt <= err_cnt + 1; end if;
        end if;
        --  ~0.13s window @62.5MHz: publish the count and restart, so the
        --  register shows the CURRENT error rate, not history since reset.
        win_cnt <= win_cnt + 1;
        if win_cnt = 0 then
          err_win <= err_cnt;
          err_cnt <= (others => '0');
        end if;
        dbg_lat(4 downto 0)   <= comma_cur_pos;
        dbg_lat(5)            <= comma_aligned;
        dbg_lat(9 downto 6)   <= std_logic_vector(err_win);
        dbg_lat(19 downto 10) <= dbg_hi;
        dbg_lat(23 downto 20) <= (others => '0');
      end if;
    end if;
  end process;

  dbg_o <= dbg_lat;

  ---------------------------------------------------------------------------
  -- Serdes ready: reset controller done + RX buffer-bypass alignment done.
  ---------------------------------------------------------------------------
  serdes_ready_a <= not rst_i
                    and gt_reset_rx_done_i
                    and gt_reset_tx_done_i
                    and gt_buffbypass_rx_done_i
                    and gt_rx_cdr_lock_i;

  U_Sync_Serdes_RDY : entity work.gc_sync
    port map (
      clk_i     => gth_rx_clk_i,
      rst_n_a_i => '1',
      d_i       => serdes_ready_a,
      q_o       => serdes_ready_rxclk);

  U_Sync_RxReset : entity work.gc_sync
    port map (
      clk_i     => gth_rx_clk_i,
      rst_n_a_i => '1',
      d_i       => rst_n,
      q_o       => rst_rxclk_n);

  ---------------------------------------------------------------------------
  -- RX: raw 20-bit -> comma steered to FIXED tap 0 (PCS rxslide) -> 8b10b
  --
  -- This is the doc §4 HW-confirmed working scheme (wall #7): a fabric FSM
  -- pulses PCS rxslide until the comma sits at the fixed EVEN target tap 0.
  -- At target 0 the barrel-shift window is a pass-through (no borrow), so the
  -- 20-bit word frames two clean symbols; any ODD tap makes the shift borrow
  -- 1 bit and corrupts the /C1//C2/ marker (wall #6) -> AN never completes.
  -- 'aligned' asserts only when the comma actually sits at the target, which
  -- gates rdy_o / STATUS.PHY_READY.
  --
  -- Each PCS rxslide assertion slips 1 bit, so tap 0 is reachable from any
  -- natural landing (doc §4: "both ends align at tap 0 every boot").  The
  -- firmware re-throw (RX PMA reset on PHY_READY timeout) is only a safety
  -- net for a stuck acquisition.
  ---------------------------------------------------------------------------
  rx_data_raw <= gth_rx_data_i;

  U_Comma_Detect : gtx_comma_detect_lp
    generic map (
      g_ID => 0)
    port map (
      clk_rx_i            => gth_rx_clk_i,
      rst_i               => comma_rst_i,
      rx_data_raw_i       => rx_data_raw,
      rx_data_raw_o       => rx_data_decode,
      comma_target_pos_i  => g_comma_target_pos,   -- fixed tap 0
      comma_current_pos_o => comma_cur_pos,
      comma_pos_valid_o   => comma_pos_valid,
      link_up_o           => comma_link_up,
      aligned_o           => comma_aligned);

  comma_pos_o <= comma_cur_pos;

  ---------------------------------------------------------------------------
  -- Comma-steering FSM: bit-slip (rxslide) until the comma sits at the target
  -- tap.  Only slip once the comma is being seen consistently (link_up) and it
  -- is not already aligned; wait g_slide_settle rxclks after each slip for the
  -- detector to re-acquire before deciding again.
  ---------------------------------------------------------------------------
  p_slide : process(gth_rx_clk_i)
  begin
    if rising_edge(gth_rx_clk_i) then
      if comma_rst_i = '1' then
        slide_state <= SLIDE_IDLE;
        rx_slide    <= '0';
        slide_cnt   <= (others => '0');
        slide_done  <= '0';
        slide_count <= (others => '0');
      else
        --  Latch "done" once the detector has fully acquired at the target, so
        --  a later transient sync loss cannot make us slide off a good lock
        --  (that lost the earlier multi-second locks).  Cleared only by reset.
        if comma_aligned = '1' then
          slide_done <= '1';
        end if;

        case slide_state is
          when SLIDE_IDLE =>
            rx_slide <= '0';
            --  Slide toward the target while a fresh comma is seen off-target.
            --  Key off the POSITION, not 'aligned': aligned lags by the
            --  detector's sync-acquire window (~500 commas), so keying off it
            --  overshoots tap 0 and never settles (comma was stuck at pos 9).
            if slide_done = '0' and comma_pos_valid = '1'
               and comma_cur_pos /= g_comma_target_pos then
              rx_slide    <= '1';
              slide_state <= SLIDE_PULSE;
              if slide_count = 9 then
                slide_count <= (others => '0');
              else
                slide_count <= slide_count + 1;
              end if;
            end if;

          when SLIDE_PULSE =>
            --  UG578: RXSLIDE must be held HIGH for at least 2 RXUSRCLK2
            --  cycles (then low >= 32 before the next assertion, covered by
            --  the settle wait).  A 1-cycle pulse may be ignored by the PCS.
            rx_slide    <= '1';         -- 2nd high cycle
            slide_cnt   <= to_unsigned(g_slide_settle, slide_cnt'length);
            slide_state <= SLIDE_WAIT;

          when SLIDE_WAIT =>
            rx_slide <= '0';
            if slide_cnt = 0 then
              slide_state <= SLIDE_IDLE;
            else
              slide_cnt <= slide_cnt - 1;
            end if;
        end case;
      end if;
    end if;
  end process;

  --  rxslide ENABLED (doc §4 / wall #7): the fabric FSM bit-slips the comma to
  --  the fixed target tap 0, where the barrel-shift window (merged(19:0)) is a
  --  pure pass-through framing two clean symbols with NO borrow.  Any other
  --  tap stitches PREVIOUS-word bits where NEXT-word bits belong -- masked by
  --  periodic idles but corrupting non-periodic data such as the /C1//C2/ AN
  --  marker (doc wall #6).  Each rxslide assertion slips 1 bit, so tap 0 is
  --  reachable from any landing (doc §4: aligns at tap 0 every boot, any
  --  parity).  The firmware re-throw (RX PMA reset on PHY_READY timeout) is a
  --  safety net for a stuck acquisition, not the alignment mechanism.  Watch
  --  bitslide(12:8) = comma tap settle at 0.
  gth_rx_slide_o <= rx_slide;

  U_Dec1 : gc_dec_8b10b
    port map (
      clk_i       => gth_rx_clk_i,
      rst_n_i     => rst_rxclk_n,
      in_10b_i    => rx_data_decode(19 downto 10),
      ctrl_o      => rx_k_int(1),
      code_err_o  => rx_code_err(1),
      rdisp_err_o => open,
      out_8b_o    => rx_data_int(15 downto 8));

  U_Dec2 : gc_dec_8b10b
    port map (
      clk_i       => gth_rx_clk_i,
      rst_n_i     => rst_rxclk_n,
      in_10b_i    => rx_data_decode(9 downto 0),
      ctrl_o      => rx_k_int(0),
      code_err_o  => rx_code_err(0),
      rdisp_err_o => open,
      out_8b_o    => rx_data_int(7 downto 0));

  -- Endpoint 16-bit PCS wants the comma (K28.5) in the HIGH byte: emit
  -- byte-swapped, same convention as wr_gthe4_rxtx_adapter.
  p_gen_rx_outputs : process(gth_rx_clk_i)
  begin
    if rising_edge(gth_rx_clk_i) then
      if serdes_ready_rxclk = '1' then
        rx_data_o    <= rx_data_int(7 downto 0) & rx_data_int(15 downto 8);
        rx_k_o       <= rx_k_int(0) & rx_k_int(1);
        rx_enc_err_o <= rx_code_err(0) or rx_code_err(1);
      else
        rx_data_o    <= (others => '1');
        rx_k_o       <= (others => '1');
        rx_enc_err_o <= '1';
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- TX: GT-internal 8b10b path (byte-swap + disparity), identical to
  -- wr_gthe4_rxtx_adapter.  Comma byte tx_data(15:8) -> TXDATA(7:0) = first
  -- symbol on the wire.  (Fabric-RAW TX with TX_BUFFER_MODE 1 was tried and
  -- made the peer unable to hold the comma at all -- reverted.)
  ---------------------------------------------------------------------------
  gth_tx_k_o    <= tx_k_i(0) & tx_k_i(1);
  gth_tx_data_o <= tx_data_i(7 downto 0) & tx_data_i(15 downto 8);

  p_gen_tx_disparity : process(gth_tx_clk_i)
  begin
    if rising_edge(gth_tx_clk_i) then
      if serdes_ready_a = '0' then
        cur_disp <= RD_MINUS;
      else
        cur_disp <= f_next_8b10b_disparity16(cur_disp, tx_k_i, tx_data_i);
      end if;
    end if;
  end process;

  tx_disparity_o <= to_std_logic(cur_disp);
  tx_enc_err_o   <= '0';

  ---------------------------------------------------------------------------
  -- Ready / diagnostics
  ---------------------------------------------------------------------------
  rx_bitslide_o <= std_logic_vector(slide_count);
  rdy_o         <= serdes_ready_rxclk and comma_aligned;

end rtl;
