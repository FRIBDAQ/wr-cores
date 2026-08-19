# LPDC comma alignment and phase matching on the CTS/KR260 GTHE4: what we tried and why it was reverted

**Date:** 2026-08-14 &nbsp;&nbsp; **Status:** SUPERSEDED — see addendum &nbsp;&nbsp; **Target:** CTS / KR260, Xilinx GTHE4 (Kria K26), White Rabbit

> **Addendum (2026-08-19).** The root-cause conclusion of this note (§6: the RXPI direct-tag is inherently non-deterministic per relink; sub-ns needs a DMTD clock) is **disproven**. The scatter had three concrete causes — an uncalibrated master-side timestamp phase (the sweep never ran on a master), an uncompensated per-relink rxslide UI latency, and a GTHE4 mod-10 wrap in that latency. With those fixed the direct-tag path delivers per-relink PPS deterministic to ±50 ps, no DMTD. See [lpdc-rxpi-deterministic-pps.md](lpdc-rxpi-deterministic-pps.md). The bring-up record below (the seven walls) remains valid and was the foundation of the successful second campaign.

**Scope.** This note records an attempt to add LPDC (Low Phase Drift Calibration) deterministic RX comma alignment on top of the existing RXPI fine-phase path on the CTS GTHE4 transceiver, the sequence of issues found during bring-up and how each was solved, and the point at which the effort stopped. The link-layer determinism goal was met; the sub-nanosecond *phase* goal was not, for a reason that sits one layer below LPDC. The work was reverted; two useful parallel fixes were kept. This documents the outcome so the direction is not blindly re-attempted.

---

## 1. Goal

Combine two deterministic-latency strategies on the CTS GTHE4:

- **LPDC** — bypass the RX elastic buffer and align the 8b10b comma to a *fixed* tap, so the RX byte/UI latency is deterministic (the classic White Rabbit "low phase drift" method).
- **RXPI** — the existing CTS mechanism that reads the CDR phase-interpolator (`dmonitorout`) and sweeps an MMCM to measure/compensate the sub-UI phase.

Target outcome: a robust WR link with **reproducible, sub-ns phase across relinks and power-cycles**.

---

## 2. What we built (the LPDC integration)

RX-only conversion; the TX path was left exactly as the working RXPI design.

| Layer | Change |
|---|---|
| GT IP (`gthe4_phy.tcl`) | RX elastic **buffer bypass** + **RAW 20-bit**, internal 8b10b / comma alignment off; QPLL0 fractional-N, `dmonitor`, `txpippm` preserved |
| Fabric datapath (`rxpi_lp_adapter.vhd`, new) | raw 20-bit → `gtx_comma_detect_lp` (fixed-tap barrel shift) → fabric `gc_dec_8b10b` ×2; instantiates `lpdc_mdio_regs` |
| Register access | endpoint `phy_mdio_master` wired to `lpdc_mdio_regs` (MDIO PHY-specific window) |
| Fine phase | RXPI `dmonitor` sweep kept unchanged (`xwrc_gthe4_rxpi.vhd`) |
| Firmware (`lpdc_gthe4_rxpi.c`) | merged an LPDC comma-target FSM with the existing sweep FSM |

---

## 3. Bring-up: the walls and the fixes

Each item below was a distinct failure found on hardware and resolved before the next surfaced.

| # | Symptom | Root cause | Fix |
|---|---|---|---|
| 1 | Slave never re-rolls, deadlocks | RX-retry gated on `phy_ready`, which needs `buffbypass_done`; wrong tap + stuck buffbypass = deadlock | evaluate the comma detector directly, re-roll immediately, add a timeout |
| 2 | Link flaps / rejects a good tap | `comma_pos_valid` (asserts only during idles) was gating acceptance | accept on the latched `aligned` bit instead |
| 3 | Comma position jitters, no sync | RX buffer-bypass alignment started before the CDR relocked | gate the buffbypass reset on `rx_reset_done`; reset the comma detector on `rx_rst_done` |
| 4 | "Mostly fails to find the comma" | the comma lands on a single **parity** per boot, and the parity **flips per power-cycle** (the long-standing 98%-odd bitslide) | adaptive parity target in firmware |
| 5 | PHY aligned but `wr0` down | auto-negotiation was kicked once at boot, *before* the PHY aligned, and never restarted | restart AN on alignment |
| 6 | AN never completes (`lpa=0000`) | on an **odd** target tap, the comma barrel-shift's 1-bit borrow **corrupts the `/C1//C2/` D21.5/D2.2 marker** (the comma and config bytes decoded fine); an **even** tap has no borrow | captured the decoded RX words (`rxpi pat`) to prove it; steer to an even tap |
| 7 | Reaching an even tap on every boot | PMA `rxslide` is rejected by the IP in the bypass/RAW config (only `PCS`/`OFF` allowed) | **PCS `rxslide`** + a fabric FSM that bit-slips the comma to **tap 0** deterministically |

**Diagnostic tooling built along the way** (all in the now-reverted driver): `rxpi stat` (PHY + endpoint sync/AN/LPA), `rxpi pat` (latch & dump decoded RX words via `lpdc_mdio_regs.idle_pat`), `rxpi an <0|1>`, `rxpi ld` (tune `phase_ld`), `rxpi fixoff` (skip the sweep, pin a fixed offset).

---

## 4. The working result

After the PCS-rxslide-to-tap-0 fix, the **link layer was fully deterministic**:

- Both ends align at tap 0 every boot: `pos=0 aligned=1`.
- Auto-negotiation completes: `link=1 aneg=1 lpa=4020`.
- Slave locks: `MPL1 lck:1`.
- **Fiber replug re-links cleanly**, regardless of session parity.

This confirmed the LPDC comma alignment did its job: the byte/UI-level latency was made deterministic and the WR Ethernet link was solid and reproducible.

---

## 5. Phase matching — where it stopped

With the link working, the **per-relink phase offset stayed ~2–8 ns and was not reproducible** (the spread was under 16 ns, i.e. within one 62.5 MHz period). Two coupled problems:

- **Intermittent lock loss (~every 3 min).** A CDR-PI rollover spike trips `phase_ld` → unlock → PTP desequences (`slave_handle_followup`) → the FSM **re-runs the sweep**, which **jumps the offset mid-session**.
- **The per-relink sweep `delta` is not reproducible.** Live dumps showed `delta` swinging ~12→179 (×200 ps) with the sweep's `±56/4` boundary heuristic flipping and a coarse-cycle ambiguity in the coarse/fine stitch.

The decisive experiment was `rxpi fixoff`: **skip the sweep entirely and pin a fixed ptracker offset**. The offset **still scattered across relinks**. That rules the sweep out as the root cause — the underlying reference is moving.

---

## 6. Root cause

The RXPI **direct-tag** phase measurement (the accumulated CDR phase-interpolator reading, fed to the SoftPLL as `direct_tag0`) references the **random CDR lock phase**, not a local clock. So:

- The comma alignment pins the **UI** (byte boundary) — deterministic.
- Nothing in this scheme pins the **sub-UI recovered-clock phase** reproducibly — the direct-tag carries a per-relink offset it cannot resolve, and the sweep was trying to correct a moving target (so "measure once and store" was never going to work).

CTS uses the direct-tag path precisely **because the board has no DMTD clock** (`clk_dmtd` is tied to `0`, `g_direct_tag = true`). A DMTD clock references the **local** oscillator, giving a phase that is deterministic modulo one period — which is exactly what a reproducible sub-ns measurement needs.

Frequency **syntonization** was never the problem: the boards held ~9 ps RMS throughout.

---

## 7. Conclusion and path forward

- **LPDC succeeded at its layer.** Deterministic byte/UI comma alignment (tap 0 via PCS rxslide) produced a robust, reproducibly re-linking WR connection with correct auto-negotiation. That is a genuine, kept-worthy result.
- **Sub-ns phase is blocked one layer below LPDC**, in the RXPI direct-tag reference. No amount of comma alignment or sweep bookkeeping fixes a phase reference tied to the random CDR lock.
- **The real path to <1 ns is not more datapath work — it is a clock.** Provide a **DMTD clock** (a few ppm off the WR reference, e.g. derived from the on-board Si5344) and switch the ptracker from direct-tag to the **standard WR DDMTD**. That is a board/clocking change.
- **Decision: reverted** the LPDC work in both `wr-cores` and `wrpc-sw`, back to pure-RXPI. Until a DMTD clock is available, pure-RXPI is the working baseline — fine for frequency / syntonization use.

---

## 8. Repository state after revert

Reverted (my LPDC changes): `board/gthe4-rxpi/gthe4_phy.tcl`, `board/gthe4-rxpi/xwrc_board_gthe4_rxpi.vhd`, `platform/xilinx/UltraScalePlus/GTHE4-rxpi/Manifest.py`, `platform/xilinx/UltraScalePlus/GTHE4-rxpi/rxpi_lp_adapter.vhd` (deleted), and `wrpc-sw/dev/lpdc_gthe4_rxpi.c`.

**Kept** (two parallel, non-LPDC improvements made during the session — do not discard):

| File | What it does |
|---|---|
| `platform/xilinx/UltraScalePlus/GTHE4-rxpi/xwrc_gthe4_rxpi.vhd` | `b_rxpi` continuous-unwrap CDR accumulator — kills the half-UI rollover spikes on the pure-RXPI path |
| `wrpc-sw/softpll/spll_main.c` | looser `phase_ld` (threshold 2000 / delock 8192) |

**Note.** The generated `gthe4_phy` IP on disk is still the LPDC (bypass/RAW) version from the last resynth. Re-run the reverted `gthe4_phy.tcl` to regenerate the original (buffered, 8b10b, 16-bit) IP before the next build, or the reverted board component/port map will mismatch.
