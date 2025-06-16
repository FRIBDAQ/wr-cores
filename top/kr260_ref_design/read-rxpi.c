#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdint.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/mman.h>

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

  if (parse_uint(&cnt, argv[2], "read") < 0)
    return 1;

  msize = (4 * cnt + PAGE_MASK) & ~PAGE_MASK;

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

  mpsoc->rxpi_samp = samp;

  /* Flush */
  for (unsigned rdcnt = mpsoc->fifo_rdcount; rdcnt > 0; rdcnt--) {
    mpsoc->fifo_data;
  }

  mpsoc->fifo_nfull = 1;

  mpsoc->fifo_ctrl |= MPSOC_MAP_FIFO_CTRL_EN;

  ptr = buf;
  for (i = cnt; i; ) {
    unsigned rdcnt = mpsoc->fifo_rdcount;

    // printf("rdcnt: %u\n", rdcnt);

    if (rdcnt == 0) {
      usleep(10);
      continue;
    }

    if (rdcnt > i)
      rdcnt = i;

    i -= rdcnt;

    for (; rdcnt > 0; rdcnt--) {
      uint32_t val = mpsoc->fifo_data;
      *ptr++ = val;
    }
  }

  mpsoc->fifo_ctrl &= ~MPSOC_MAP_FIFO_CTRL_EN;

  for (i = 0; i < cnt; i++) {
    uint32_t val = buf[i];
    printf ("%u\n", val & 0xffff);
    printf ("%u\n", val >> 16);
  }

  fprintf(stderr, "nfull: %u\n", mpsoc->fifo_nfull);
  return 0;
}

static struct cmd_pair commands[] =
  {
    {"help", do_help},
    {"ctrl", do_ctrl},
    {"qpll1", do_qpll1},
    {"regs", do_regs},
    {"read", do_read},
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
