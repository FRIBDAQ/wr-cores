/*
 * txpi.c - bench helper for the TXPI (TX phase interpolator) gating experiment.
 *
 * Accesses the rxpi_gthe4_map registers through the mpsoc_map WRPC_AUX bridge
 * window:  physical base = 0x80000000 (mpsoc) + 0x4000 (WRPC_AUX) = 0x80004000.
 *
 * WARNING: this whole region is behind the PS->PL AXI bridge clocked by the
 * GT-derived clk_62m5.  If the PHY / clk_62m5 is dead, ANY access here hangs the
 * CPU uninterruptibly.  Only run this while the transceiver is up (WR locked).
 *
 * Build (on the KR260, or cross):  cc -O2 -o txpi txpi.c
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/mman.h>

#define AUX_PHYS   0x80004000UL   /* mpsoc 0x80000000 + WRPC_AUX 0x4000 */
#define PAGE_SIZE  4096

/* Register byte offsets in rxpi_gthe4_map (index = offset/4). */
enum {
  R_ID       = 0x00 / 4,
  R_RESET    = 0x04 / 4,
  R_STATUS   = 0x08 / 4,
  R_CTRL     = 0x0c / 4,
  R_BITSLIDE = 0x10 / 4,
  R_NSAMP    = 0x14 / 4,
  R_SHIFT    = 0x18 / 4,
  R_PSCTRL   = 0x1c / 4,
  R_PSSTAT   = 0x20 / 4,
  R_PSCOUNT  = 0x24 / 4,
  R_PSRES    = 0x28 / 4,
  R_TXPI     = 0x2c / 4,
  R_TXPI_STEP = 0x30 / 4,
  R_TXPI_STAT = 0x34 / 4,
};

#define ID_MAGIC        0x000618e4u

/* reset register bits */
#define RST_RX_PMA      (1u << 0)   /* force a relink */
#define RST_RXPI        (1u << 16)

/* status register bits */
#define STAT_PHY_READY  (1u << 0)

/* ps_ctrl bits (MMCM fine phase shift) */
#define PSC_RST         (1u << 0)   /* resets MMCM + phase counter */
#define PSC_PD          (1u << 1)
#define PSC_INCDEC      (1u << 8)   /* 1 = increment on shift */
#define PSC_SHIFT       (1u << 9)   /* wire strobe: issue one PSEN on write */

/* ps_stat bits */
#define PSSTAT_LOCKED   (1u << 18)
#define PSSTAT_BUSY     (1u << 19)

/* MMCM fine-PS steps per CLKOUT0 period: VCO=1250MHz, step=1/(56*Fvco)~14.3ps,
 * 16ns period -> ~1119 steps.  Sweep a little past one period. */
#define PS_STEP_PS      14.3
#define PS_MAX_SWEEP    1300

/* txpi_ctrl fields */
#define TXPI_EN         (1u << 0)
#define TXPI_OVRDEN     (1u << 1)
#define TXPI_PD         (1u << 2)
#define TXPI_SEL        (1u << 3)
#define TXPI_SS_SHIFT   4
#define TXPI_SS_MASK    (0x1fu << TXPI_SS_SHIFT)

/* txpi_stat bits */
#define TXPISTAT_BUSY   (1u << 0)

static volatile uint32_t *aux;

static inline uint32_t rd(int idx)          { return aux[idx]; }
static inline void      wr(int idx, uint32_t v) { aux[idx] = v; }

static int parse_uint(unsigned *res, const char *s, const char *name)
{
  char *e;
  if (s == NULL) { printf("missing value for %s\n", name); return -1; }
  *res = strtoul(s, &e, 0);
  if (*e != 0) { printf("invalid value for %s: %s\n", name, s); return -1; }
  return 0;
}

/* Wait for a fresh ps sampler result and return its 24-bit value; -1 on timeout. */
static long ps_read(unsigned nsamp)
{
  if (nsamp)
    wr(R_PSCOUNT, nsamp & 0xffffff);

  unsigned g0 = (rd(R_PSRES) >> 24) & 0xff;
  for (int i = 0; i < 100000; i++) {
    uint32_t r = rd(R_PSRES);
    if (((r >> 24) & 0xff) != g0)
      return r & 0xffffff;
    usleep(20);
  }
  return -1;
}

/* Pulse a reset bit; then wait for phy_ready to come back.  Returns 0 on ready. */
static int wait_phy_ready(unsigned timeout_ms)
{
  for (unsigned i = 0; i < timeout_ms; i++) {
    if (rd(R_STATUS) & STAT_PHY_READY)
      return 0;
    usleep(1000);
  }
  return -1;
}

/* Issue a hardware counted TXPI pulse of <n> substeps (TXPIPPMEN held high for n
 * clk_62m5 cycles by the gateware), then wait for busy to clear.  Deterministic,
 * unlike a software EN toggle.  0 on done, -1 on timeout. */
static int txpi_pulse_n(unsigned n)
{
  wr(R_TXPI_STEP, n & 0xffffff);
  for (int i = 0; i < 200000; i++) {
    if (!(rd(R_TXPI_STAT) & TXPISTAT_BUSY)) return 0;
    usleep(50);
  }
  return -1;
}

/* --- MMCM vernier phase measurement (the REAL txoutclk<->rxoutclk phase) ---
 * The ps sampler counts, over a `window` of clk_ps cycles, how many times the
 * (locked, same-freq) rxoutclk is sampled high by the phase-shifted txoutclk
 * copy.  At a fixed MMCM phase that count is ~0 or ~window (a 1-bit comparator).
 * Sweeping the MMCM fine phase and finding where the count flips gives the phase
 * offset at ~14 ps/step. */

/* Reset the MMCM (zeroes ps_stat.phase) and wait for it to relock. clk_ps only
 * feeds the sampler, so this perturbs nothing in the datapath. */
static void mmcm_reset(void)
{
  wr(R_PSCTRL, PSC_RST);
  usleep(2000);
  wr(R_PSCTRL, 0);
  for (int i = 0; i < 2000; i++) {
    if (rd(R_PSSTAT) & PSSTAT_LOCKED) break;
    usleep(1000);
  }
}

/* Issue one MMCM fine phase-shift step (inc!=0 => increment). */
static void mmcm_shift(int inc)
{
  wr(R_PSCTRL, PSC_SHIFT | (inc ? PSC_INCDEC : 0));
}

/* Sweep the MMCM phase up from 0 and return ps_stat.phase at the first FALLING
 * edge (count high->low) after seeing a high plateau.  Using a consistent edge
 * type makes the reading comparable across relinks (a fixed reference), ~14 ps/
 * LSB.  -1 if no edge in one period.  window sets averaging (bigger=cleaner). */
static long phase_measure(unsigned window)
{
  if (!window) window = 256;
  wr(R_PSCOUNT, window);
  long thr = window / 2;
  mmcm_reset();
  int seen_high = 0, prev_hi = -1;
  for (unsigned k = 0; k < PS_MAX_SWEEP; k++) {
    long c = ps_read(0);
    if (c < 0) return -1;
    int hi = c > thr;
    if (hi) seen_high = 1;
    if (seen_high && prev_hi == 1 && hi == 0)
      return rd(R_PSSTAT) & 0xffff;   /* falling edge = consistent reference */
    prev_hi = hi;
    mmcm_shift(1);
  }
  return -1;
}

/* Pulse the RX-PMA reset to force a relink; wait for phy_ready.  0 on ready. */
static int relink_once(unsigned timeout_ms)
{
  uint32_t r = rd(R_RESET);
  wr(R_RESET, r | RST_RX_PMA);
  usleep(130000);
  wr(R_RESET, r & ~RST_RX_PMA);
  return wait_phy_ready(timeout_ms);
}

/* Closed-loop park to a phase target using the hardware counted pulse + vernier
 * meter.  TXPI moves the phase in one (hardware-fixed) direction; we estimate
 * the gain (MMCM-steps per substep) at runtime and issue proportional, damped
 * counted pulses, wrapping forward through one period if the target is behind.
 * Returns final phase (>=0) or -1 on timeout; *iters gets the pulse count. */
static long park_run(long target, unsigned tol, unsigned maxiter, unsigned window,
                     long period, double gain0, int verbose, unsigned *iters)
{
  unsigned it = 0;
  int dir = 0;                                /* +1 TXPI raises phase, -1 lowers */
  double gain = (gain0 > 0) ? gain0 : 0.1;    /* MMCM-steps per substep */
  long p = phase_measure(window);
  if (p < 0) { if (iters) *iters = 0; return -1; }

  while (it < maxiter) {
    unsigned n;
    long g = 0;
    if (dir == 0) {
      n = 200;                                /* probe to learn direction+gain */
    } else {
      /* gap measured along the (unidirectional) TXPI direction */
      g = (dir > 0) ? ((target - p) % period + period) % period
                    : ((p - target) % period + period) % period;
      if (g <= (long)tol || g >= period - (long)tol) break;
      long move = (long)((double)g * 0.7);    /* damped */
      n = (unsigned)((double)move / gain);
      if (n < 1) n = 1;
      if (n > 4000000) n = 4000000;
    }
    if (txpi_pulse_n(n) < 0) { if (iters) *iters = it; return -1; }
    it++;
    long np = phase_measure(window);
    if (np < 0) { if (iters) *iters = it; return -1; }
    long fwd = ((np - p) % period + period) % period;  /* 0..period */
    long signed_d = (fwd <= period / 2) ? fwd : fwd - period;
    if (signed_d != 0) {
      if (dir == 0) dir = (signed_d > 0) ? 1 : -1;
      long ad = signed_d < 0 ? -signed_d : signed_d;
      gain = 0.5 * gain + 0.5 * ((double)ad / (double)n);
    }
    if (verbose)
      printf("  park it=%u: p=%ld->%ld gap=%ld n=%u dir=%+d gain=%.4f\n",
             it, p, np, g, n, dir, gain);
    p = np;
  }
  if (iters) *iters = it;
  return p;
}

static int do_regs(int argc, char **argv)
{
  (void)argc; (void)argv;
  printf("id        [0x00]: %08x %s\n", rd(R_ID),
         rd(R_ID) == ID_MAGIC ? "(ok)" : "(BAD MAGIC!)");
  printf("reset     [0x04]: %08x\n", rd(R_RESET));
  printf("status    [0x08]: %08x  phy_ready=%d\n", rd(R_STATUS),
         !!(rd(R_STATUS) & STAT_PHY_READY));
  printf("ctrl      [0x0c]: %08x\n", rd(R_CTRL));
  printf("bitslide  [0x10]: %08x  slide=%u comma_lane=0x%02x\n", rd(R_BITSLIDE),
         rd(R_BITSLIDE) & 0x1f, (rd(R_BITSLIDE) >> 8) & 0xff);
  printf("rxpi_nsamp[0x14]: %08x\n", rd(R_NSAMP));
  printf("rxpi_shift[0x18]: %08x\n", rd(R_SHIFT));
  printf("ps_ctrl   [0x1c]: %08x\n", rd(R_PSCTRL));
  printf("ps_stat   [0x20]: %08x  phase=%u locked=%d busy=%d\n", rd(R_PSSTAT),
         rd(R_PSSTAT) & 0xffff, !!(rd(R_PSSTAT) & PSSTAT_LOCKED),
         !!(rd(R_PSSTAT) & PSSTAT_BUSY));
  printf("ps_res    [0x28]: %08x  val=%u gen=%u\n", rd(R_PSRES),
         rd(R_PSRES) & 0xffffff, (rd(R_PSRES) >> 24) & 0xff);
  uint32_t t = rd(R_TXPI);
  printf("txpi_ctrl [0x2c]: %08x  en=%d ovrden=%d pd=%d sel=%d stepsize=0x%02x\n",
         t, !!(t & TXPI_EN), !!(t & TXPI_OVRDEN), !!(t & TXPI_PD),
         !!(t & TXPI_SEL), (t & TXPI_SS_MASK) >> TXPI_SS_SHIFT);
  return 0;
}

static int do_get(int argc, char **argv)
{
  (void)argc; (void)argv;
  printf("txpi_ctrl = 0x%08x\n", rd(R_TXPI));
  return 0;
}

static int do_set(int argc, char **argv)
{
  unsigned v;
  if (argc < 3) { printf("usage: set <hex>\n"); return 1; }
  if (parse_uint(&v, argv[2], "set") < 0) return 1;
  wr(R_TXPI, v);
  printf("txpi_ctrl <- 0x%08x (readback 0x%08x)\n", v, rd(R_TXPI));
  return 0;
}

static int do_en(int argc, char **argv)
{
  unsigned v;
  if (argc < 3) { printf("usage: en <0|1>\n"); return 1; }
  if (parse_uint(&v, argv[2], "en") < 0) return 1;
  uint32_t t = rd(R_TXPI);
  t = v ? (t | TXPI_EN) : (t & ~TXPI_EN);
  wr(R_TXPI, t);
  printf("txpi_ctrl = 0x%08x\n", rd(R_TXPI));
  return 0;
}

static int do_ss(int argc, char **argv)
{
  unsigned v;
  if (argc < 3) { printf("usage: ss <val>\n"); return 1; }
  if (parse_uint(&v, argv[2], "ss") < 0) return 1;
  uint32_t t = rd(R_TXPI);
  t = (t & ~TXPI_SS_MASK) | ((v << TXPI_SS_SHIFT) & TXPI_SS_MASK);
  wr(R_TXPI, t);
  printf("txpi_ctrl = 0x%08x\n", rd(R_TXPI));
  return 0;
}

/* Assert TXPIPPMEN for <usec> microseconds, then deassert.  For discrete-step
 * testing; also usable (large usec) to observe a continuous ppm slew. */
static int do_pulse(int argc, char **argv)
{
  unsigned usec;
  if (argc < 3) { printf("usage: pulse <us>\n"); return 1; }
  if (parse_uint(&usec, argv[2], "pulse") < 0) return 1;
  uint32_t t = rd(R_TXPI);
  wr(R_TXPI, t | TXPI_EN);
  usleep(usec);
  wr(R_TXPI, t & ~TXPI_EN);
  printf("pulsed en for %u us; txpi_ctrl = 0x%08x\n", usec, rd(R_TXPI));
  return 0;
}

static int do_ps(int argc, char **argv)
{
  unsigned nsamp = 0;
  if (argc >= 3 && parse_uint(&nsamp, argv[2], "ps") < 0) return 1;
  long v = ps_read(nsamp);
  if (v < 0) { printf("ps_res: timeout (sampler not advancing)\n"); return 1; }
  printf("ps_res val = %ld (0x%lx)\n", v, v);
  return 0;
}

/* Real vernier phase measurement (MMCM sweep).  usage: phase [window] */
static int do_phase(int argc, char **argv)
{
  unsigned window = 0;
  if (argc >= 3 && parse_uint(&window, argv[2], "window") < 0) return 1;
  long p = phase_measure(window);
  if (p < 0) { printf("phase: no edge found in one period\n"); return 1; }
  printf("phase = %ld steps (~%.0f ps)\n", p, p * PS_STEP_PS);
  return 0;
}

/* Diagnostic: dump sampler count vs MMCM phase across one sweep so you can SEE
 * the transition and confirm the sampler works.  usage: pscan [window] [every] */
static int do_pscan(int argc, char **argv)
{
  unsigned window = 256, every = 16;
  if (argc >= 3 && parse_uint(&window, argv[2], "window") < 0) return 1;
  if (argc >= 4 && parse_uint(&every, argv[3], "every") < 0) return 1;
  if (every == 0) every = 1;
  wr(R_PSCOUNT, window);
  mmcm_reset();
  for (unsigned k = 0; k < PS_MAX_SWEEP; k++) {
    long c = ps_read(0);
    if (k % every == 0)
      printf("  k=%4u phase=%5u count=%ld\n", k, rd(R_PSSTAT) & 0xffff, c);
    mmcm_shift(1);
  }
  return 0;
}

/* Per relink: measure real phase (MMCM sweep), log spread.
 * usage: pmsweep <N> [window] [lock_ms] */
static int do_pmsweep(int argc, char **argv)
{
  unsigned n, window = 0, lock_ms = 0;
  long pmin = 0, pmax = 0;
  int have = 0;
  if (argc < 3) { printf("usage: pmsweep <N> [window] [lock_ms]\n"); return 1; }
  if (parse_uint(&n, argv[2], "N") < 0) return 1;
  if (argc >= 4 && parse_uint(&window, argv[3], "window") < 0) return 1;
  if (argc >= 5 && parse_uint(&lock_ms, argv[4], "lock_ms") < 0) return 1;

  for (unsigned i = 0; i < n; i++) {
    if (relink_once(2000) < 0) { printf("relink %3u: phy_ready TIMEOUT\n", i); continue; }
    if (lock_ms) usleep(lock_ms * 1000);
    long p = phase_measure(window);
    printf("relink %3u: phase=%ld (~%.0f ps) bitslide=0x%x\n",
           i, p, p < 0 ? 0.0 : p * PS_STEP_PS, rd(R_BITSLIDE) & 0x1f);
    if (p >= 0) {
      if (!have || p < pmin) pmin = p;
      if (!have || p > pmax) pmax = p;
      have = 1;
    }
  }
  if (have)
    printf("---- phase spread: min=%ld max=%ld span=%ld steps (~%.0f ps) ----\n",
           pmin, pmax, pmax - pmin, (pmax - pmin) * PS_STEP_PS);
  return 0;
}

static int do_relink(int argc, char **argv)
{
  (void)argc; (void)argv;
  if (relink_once(2000) < 0) { printf("relink: phy_ready timeout\n"); return 1; }
  printf("relink done, phy_ready=1\n");
  return 0;
}

/* Hardware counted TXPI pulse of N substeps.  usage: nstep <N> */
static int do_nstep(int argc, char **argv)
{
  unsigned n;
  if (argc < 3) { printf("usage: nstep <N>\n"); return 1; }
  if (parse_uint(&n, argv[2], "N") < 0) return 1;
  if (txpi_pulse_n(n) < 0) { printf("nstep: busy timeout\n"); return 1; }
  printf("pulsed %u substeps\n", n);
  return 0;
}

/* Calibrate: measure phase, pulse N substeps, measure phase, report the move
 * (MMCM-steps + ps per substep, and direction).  usage: cal <N> [window] */
static int do_cal(int argc, char **argv)
{
  unsigned n, window = 512;
  if (argc < 3) { printf("usage: cal <N> [window]\n"); return 1; }
  if (parse_uint(&n, argv[2], "N") < 0) return 1;
  if (argc >= 4 && parse_uint(&window, argv[3], "window") < 0) return 1;
  long p0 = phase_measure(window);
  if (txpi_pulse_n(n) < 0) { printf("cal: pulse busy timeout\n"); return 1; }
  long p1 = phase_measure(window);
  if (p0 < 0 || p1 < 0) { printf("cal: phase timeout\n"); return 1; }
  printf("cal: %u substeps moved phase %ld -> %ld  (delta=%+ld steps ~%.0f ps; "
         "%.4f MMCM/substep, ~%.3f ps/substep)\n",
         n, p0, p1, p1 - p0, (p1 - p0) * PS_STEP_PS,
         (double)(p1 - p0) / n, (p1 - p0) * PS_STEP_PS / n);
  return 0;
}

/* Closed-loop park to a phase target (MMCM steps).
 * usage: park <target> <tol> [window] [period] [maxiter] [gain] */
static int do_park(int argc, char **argv)
{
  unsigned tol, window = 512, maxiter = 64, t, tw;
  long target, period = 1120;
  double gain = 0.0;
  if (argc < 4) {
    printf("usage: park <target> <tol> [window] [period] [maxiter] [gain]\n");
    return 1;
  }
  if (parse_uint(&t, argv[2], "target") < 0) return 1;
  target = t;
  if (parse_uint(&tol, argv[3], "tol") < 0) return 1;
  if (argc >= 5 && parse_uint(&window, argv[4], "window") < 0) return 1;
  if (argc >= 6) { if (parse_uint(&tw, argv[5], "period") < 0) return 1; period = tw; }
  if (argc >= 7 && parse_uint(&maxiter, argv[6], "maxiter") < 0) return 1;
  if (argc >= 8) gain = atof(argv[7]);
  unsigned it;
  long v = park_run(target, tol, maxiter, window, period, gain, 1, &it);
  if (v < 0) { printf("park: phase timeout\n"); return 1; }
  long g = ((target - v) % period + period) % period;
  printf("park done: phase=%ld target=%ld gap=%+ld iters=%u %s\n",
         v, target, g <= period / 2 ? g : g - period, it,
         (g <= (long)tol || g >= period - (long)tol) ? "(within tol)"
                                                     : "(NOT within tol)");
  return 0;
}

/* Per relink: relink, wait for lock, park to target, log residual.
 * usage: sweep-park <N> <target> <tol> [lock_ms] [window] [period] */
static int do_sweep_park(int argc, char **argv)
{
  unsigned n, tol, lock_ms = 3000, window = 512, t, tw;
  long target, period = 1120, rmin = 0, rmax = 0;
  int have = 0;
  if (argc < 5) {
    printf("usage: sweep-park <N> <target> <tol> [lock_ms] [window] [period]\n");
    return 1;
  }
  if (parse_uint(&n, argv[2], "N") < 0) return 1;
  if (parse_uint(&t, argv[3], "target") < 0) return 1;
  target = t;
  if (parse_uint(&tol, argv[4], "tol") < 0) return 1;
  if (argc >= 6 && parse_uint(&lock_ms, argv[5], "lock_ms") < 0) return 1;
  if (argc >= 7 && parse_uint(&window, argv[6], "window") < 0) return 1;
  if (argc >= 8) { if (parse_uint(&tw, argv[7], "period") < 0) return 1; period = tw; }

  for (unsigned i = 0; i < n; i++) {
    if (relink_once(2000) < 0) { printf("relink %3u: phy_ready TIMEOUT\n", i); continue; }
    usleep(lock_ms * 1000);   /* wait for the SoftPLL to lock */
    long before = phase_measure(window);
    unsigned it;
    long v = park_run(target, tol, 64, window, period, 0.0, 0, &it);
    if (v < 0) { printf("relink %3u: phase timeout\n", i); continue; }
    long g = ((target - v) % period + period) % period;
    long res = (g <= period / 2) ? g : g - period;   /* signed residual */
    printf("relink %3u: before=%ld parked=%ld residual=%+ld steps (~%.0f ps) iters=%u\n",
           i, before, v, res, res * PS_STEP_PS, it);
    if (!have || res < rmin) rmin = res;
    if (!have || res > rmax) rmax = res;
    have = 1;
  }
  if (have)
    printf("---- residual after park: min=%+ld max=%+ld span=%ld steps (~%.0f ps) ----\n",
           rmin, rmax, rmax - rmin, (rmax - rmin) * PS_STEP_PS);
  return 0;
}

/* One-shot: relink, wait for lock, park to target; print result (pair each run
 * with a scope capture of PPS-A vs PPS-B).  usage: rpark <target> <tol> [lock_ms]
 * [window] [period] */
static int do_rpark(int argc, char **argv)
{
  unsigned tol, lock_ms = 3000, window = 512, t, tw;
  long target, period = 1120;
  if (argc < 4) {
    printf("usage: rpark <target> <tol> [lock_ms] [window] [period]\n");
    return 1;
  }
  if (parse_uint(&t, argv[2], "target") < 0) return 1;
  target = t;
  if (parse_uint(&tol, argv[3], "tol") < 0) return 1;
  if (argc >= 5 && parse_uint(&lock_ms, argv[4], "lock_ms") < 0) return 1;
  if (argc >= 6 && parse_uint(&window, argv[5], "window") < 0) return 1;
  if (argc >= 7) { if (parse_uint(&tw, argv[6], "period") < 0) return 1; period = tw; }

  if (relink_once(2000) < 0) { printf("rpark: phy_ready timeout\n"); return 1; }
  usleep(lock_ms * 1000);
  long before = phase_measure(window);
  unsigned it;
  long v = park_run(target, tol, 64, window, period, 0.055, 0, &it);
  if (v < 0) { printf("rpark: phase timeout\n"); return 1; }
  long g = ((target - v) % period + period) % period;
  long res = (g <= period / 2) ? g : g - period;
  uint32_t bs = rd(R_BITSLIDE);
  printf("rpark: before=%ld parked=%ld residual=%+ld (~%.0f ps) iters=%u "
         "slide=%u comma_lane=0x%02x\n",
         before, v, res, res * PS_STEP_PS, it, bs & 0x1f, (bs >> 8) & 0xff);
  return 0;
}

static struct cmd_pair { const char *name; int (*exec)(int, char **); const char *help; } commands[] = {
  {"regs",   do_regs,   "dump all rxpi_gthe4_map registers"},
  {"get",    do_get,    "read txpi_ctrl"},
  {"set",    do_set,    "set <hex>   write raw txpi_ctrl"},
  {"en",     do_en,     "en <0|1>    set/clear TXPIPPMEN"},
  {"ss",     do_ss,     "ss <val>    set TXPIPPMSTEPSIZE (0..0x1f)"},
  {"pulse",  do_pulse,  "pulse <us>  assert EN for <us> microseconds then clear"},
  {"ps",     do_ps,     "ps [nsamp]  read raw ps_res (1-bit comparator - use phase instead)"},
  {"phase",  do_phase,  "phase [window]  REAL vernier phase (MMCM sweep, ~14ps/step)"},
  {"pscan",  do_pscan,  "pscan [window] [every]  dump count vs MMCM phase (diagnostic)"},
  {"pmsweep",do_pmsweep,"pmsweep <N> [window] [lock_ms]  per-relink real phase spread"},
  {"nstep",  do_nstep,  "nstep <N>  hardware counted TXPI pulse of N substeps"},
  {"cal",    do_cal,    "cal <N> [window]  pulse N substeps, report phase move (gain/dir)"},
  {"relink", do_relink, "force one RX PMA relink"},
  {"park",   do_park,   "park <target> <tol> [window] [period] [maxiter] [gain]  servo phase"},
  {"rpark",  do_rpark,  "rpark <target> <tol> [lock_ms] [window]  relink+park once (scope loop)"},
  {"sweep-park", do_sweep_park, "sweep-park <N> <target> <tol> [lock_ms] [window] [period]"},
  {NULL, NULL, NULL}
};

static int do_help(void)
{
  printf("txpi <command> [args]\n");
  for (struct cmd_pair *c = commands; c->name; c++)
    printf("  %-10s %s\n", c->name, c->help);
  return 0;
}

int main(int argc, char **argv)
{
  /* Answer help without touching /dev/mem: accessing the AXI window can hang
   * the CPU if clk_62m5 is dead, and help must never risk that. */
  if (argc == 1 || !strcmp(argv[1], "help") || !strcmp(argv[1], "-h"))
    return do_help();

  int fd = open("/dev/mem", O_RDWR | O_SYNC);
  if (fd < 0) { fprintf(stderr, "cannot open /dev/mem: %m\n"); return 1; }

  void *m = mmap(0, PAGE_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, AUX_PHYS);
  if (m == MAP_FAILED) { fprintf(stderr, "cannot mmap 0x%lx: %m\n", AUX_PHYS); return 1; }
  aux = (volatile uint32_t *)m;

  for (struct cmd_pair *c = commands; c->name; c++)
    if (!strcmp(c->name, argv[1]))
      return c->exec(argc, argv);

  printf("no command '%s'\n", argv[1]);
  return do_help();
}
