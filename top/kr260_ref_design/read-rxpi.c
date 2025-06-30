#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <time.h>

#include "mpsoc_map.h"

#define PAGE_SIZE 4096
#define PAGE_MASK (PAGE_SIZE - 1)
#define MAP_SIZE (2 * PAGE_SIZE)

static volatile struct mpsoc_map *mpsoc;

static int
parse_uint(unsigned *res, const char *s, const char *name)
{
  char *e;

  if (s == NULL) {
    printf("missing value for %s\n", name);
    return -1;
  }

  *res = strtoul(s, &e, 0);
  if (*e != 0) {
    printf("invalid value for %s: %s\n", name, s);
    return -1;
  }
  return 0;
}

struct cmd_pair {
  const char *name;
  int (*exec)(int argc, char **argv);
};

static struct cmd_pair commands[];

static int do_help(int argc, char **argv)
{
  printf ("commands:\n");
  for (struct cmd_pair *cmd = commands; cmd->name; cmd++)
    printf("  %s\n", cmd->name);

  return 0;
}

static int do_ctrl(int argc, char **argv)
{
  unsigned int val;

  if (parse_uint(&val, argv[2], "ctrl") < 0)
    return 1;

  mpsoc->ctrl = val;
  return 0;
}

static int do_qpll1(int argc, char **argv)
{
  unsigned int val;

  if (parse_uint(&val, argv[2], "qpll1") < 0)
    return 1;

  mpsoc->qpll1_sdm = val;
  return 0;
}

static int do_samp(int argc, char **argv)
{
  unsigned int val;

  if (parse_uint(&val, argv[2], "samp") < 0)
    return 1;

  mpsoc->rxpi_samp = val;
  return 0;
}

static int do_regs(int argc, char **argv)
{
  printf ("ctrl:      %08x\n", (unsigned)mpsoc->ctrl);
  printf ("status:    %08x\n", (unsigned)mpsoc->status);
  printf ("qpll0_sdm: %08x\n", (unsigned)mpsoc->qpll0_sdm);
  printf ("qpll1_sdm: %08x\n", (unsigned)mpsoc->qpll1_sdm);
  printf ("rxpi_samp: %08x\n", (unsigned)mpsoc->rxpi_samp);
  printf ("fifo_ctrl: %08x\n", (unsigned)mpsoc->fifo_ctrl);
  printf ("rdcount:   %08x\n", (unsigned)mpsoc->fifo_rdcount);
  printf ("nfull:     %08x\n", (unsigned)mpsoc->fifo_nfull);
  printf ("fifo_data: %08x\n", (unsigned)mpsoc->fifo_data);
  printf ("bitslide:  %08x\n", (unsigned)mpsoc->bitslide);

  return 0;
}

static int do_read(int argc, char **argv)
{
  unsigned samp = 100;
  uint32_t *buf;
  uint32_t *ptr;
  unsigned cnt;
  size_t msize;
  unsigned i;
  uint32_t prev_count, count;
  struct timespec tstart, tend, tdiff;

  if (parse_uint(&cnt, argv[2], "read") < 0)
    return 1;

  msize = (4 * cnt + PAGE_MASK) & ~PAGE_MASK;

  samp = mpsoc->rxpi_samp;
  if (samp == 0) {
    samp = 100;
    mpsoc->rxpi_samp = samp;
  }

  fprintf(stderr, "reading %u values every %u samples\n", cnt, samp);

  buf = mmap(0, msize, PROT_READ | PROT_WRITE,
	     MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (buf == (void *)-1) {
    fprintf(stderr, "cannot mmap buffer: %m\n");
    return 1;
  }
  if (mlock(buf, msize) != 0) {
    fprintf(stderr, "cannot mlock buffer: %m\n");
    return 1;
  }

  clock_gettime(CLOCK_MONOTONIC, &tstart);
  ptr = buf;
  prev_count = 0;
  for (i = cnt; i; i--) {
    while (1) {
      count = mpsoc->fifo_rdcount;
      if (count != prev_count)
	break;
      usleep (40);
    }
    *ptr++ = mpsoc->fifo_data;
    prev_count = count;
  }

  clock_gettime(CLOCK_MONOTONIC, &tend);

  tdiff.tv_nsec = tend.tv_nsec - tstart.tv_nsec;
  tdiff.tv_sec = tend.tv_sec - tstart.tv_sec;
  if (tdiff.tv_nsec < 0) {
    tdiff.tv_nsec += 1000000000;
    tdiff.tv_sec--;
  }
  
  for (i = 0; i < cnt; i++) {
    uint32_t val = buf[i];
    uint32_t emean = (((uint64_t)val) * 10) / (samp + 1);
    uint32_t mean = emean / 10;
    printf ("0x%08x [21:8]=%08x (m=%u.%u, mm=%u)\n",
	    val, (val >> 8) & 0x3fff,
	    mean, emean - mean * 10,
	    mean & 0x7f);
  }

  fprintf(stderr, "time: %usec %uns; mean: %uns\n",
	  (unsigned)tdiff.tv_sec, (unsigned)tdiff.tv_nsec,
	  (unsigned)tdiff.tv_nsec / cnt);
  
  fprintf(stderr, "nfull: %u\n", mpsoc->fifo_nfull);
  return 0;
}

static int do_reset(int argc, char **argv)
{
  unsigned int val = mpsoc->ctrl;
  unsigned int b;

  if (argc == 2 || strcmp(argv[2], "all") == 0)
    b = MPSOC_MAP_CTRL_GTH_RST;
  else if (strcmp(argv[2], "tx") == 0)
    b = MPSOC_MAP_CTRL_GTH_TX_RST;
  else if (strcmp(argv[2], "rx") == 0)
    b = MPSOC_MAP_CTRL_GTH_RX_RST;
  else if (strcmp(argv[2], "tx-pcs") == 0)
    b = MPSOC_MAP_CTRL_GTH_TX_PCS_RST;
  else if (strcmp(argv[2], "tx-pma") == 0)
    b = MPSOC_MAP_CTRL_GTH_TX_PMA_RST;
  else if (strcmp(argv[2], "rx-pcs") == 0)
    b = MPSOC_MAP_CTRL_GTH_RX_PCS_RST;
  else if (strcmp(argv[2], "rx-pma") == 0)
    b = MPSOC_MAP_CTRL_GTH_RX_PMA_RST;
  else if (strcmp(argv[2], "rx-buf") == 0)
    b = MPSOC_MAP_CTRL_GTH_RX_BUF_RST;
  else {
    printf("unknown bit %s\n", argv[2]);
    return 1;
  }

  mpsoc->ctrl = val | b;
  usleep(130000);
  mpsoc->ctrl = val & ~b;

  return 0;
}

static int do_slide(int argc, char **argv)
{
  unsigned int val = mpsoc->bitslide;

  if (argc == 2) {
    printf ("bitslide: %08x\n", val);
  } else if (argc == 3 && strcmp(argv[2], "force") == 0)
    val |= MPSOC_MAP_BITSLIDE_FORCE;
  else if (argc == 3 && strcmp(argv[2], "1") == 0)
    val |= MPSOC_MAP_BITSLIDE_SLIDE;
  else if (argc == 3 && strcmp(argv[2], "pulse") == 0)
    val |= MPSOC_MAP_BITSLIDE_SLIDE | MPSOC_MAP_BITSLIDE_FORCE;
  else if (argc == 3 && strcmp(argv[2], "off") == 0)
    val &= ~MPSOC_MAP_BITSLIDE_FORCE;
  else {
    printf ("usage: slide force|off|1\n");
    return 1;
  }
  mpsoc->bitslide = val;
  return 0;
}

static struct cmd_pair commands[] =
  {
    {"help", do_help},
    {"ctrl", do_ctrl},
    {"qpll1", do_qpll1},
    {"regs", do_regs},
    {"read", do_read},
    {"samp", do_samp},
    {"reset", do_reset},
    {"slide", do_slide},
    {NULL, NULL}
  };

int main(int argc, char **argv)
{
    int fd;
    off_t paddr = 0x80000000;

    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
      fprintf(stderr, "cannot open /dev/mem: %m\n");
      return 1;
    }

    mpsoc = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, paddr);
    if (mpsoc == (void *) -1) {
      fprintf(stderr, "cannot mmap /dev/mem: %m\n");
      return 1;
    }

    if (argc == 1)
      return do_help(argc, argv);
    else {
      for (struct cmd_pair *cmd = commands; cmd->name; cmd++)
	if (!strcmp(cmd->name, argv[1])) {
	  return cmd->exec(argc, argv);
	}

      printf("no command '%s'\n", argv[1]);
      return 2;
    }
}
