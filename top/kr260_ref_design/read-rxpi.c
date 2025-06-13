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

#define MAP_SIZE (2 * 4096)

static int
parse_uint(unsigned *res, const char *s, const char *name)
{
  char *e;
  
  *res = strtoul(s, &e, 0);
  if (*e != 0) {
    printf("invalid value for %s: %s\n", name, s);
    return -1;
  }
  return 0;
}

int main(int argc, char **argv)
{
    int fd;
    off_t paddr = 0x80000000;
    volatile struct mpsoc_map *mpsoc;
    unsigned cnt;
    unsigned samp = 1024;

    cnt = 0;

    for (unsigned argn = 1; argn < argc; argn++) {
      const char *opt = argv[argn];

      if (argn + 1 < argc && strcmp(opt, "-s") == 0) {
	argn++;
	if (parse_uint(&samp, argv[argn], opt) < 0)
	  return 2;
      } else if (opt[0] == '-') {
	printf("unknown option %s\n", opt);
	return 2;
      }
      else {
	if (parse_uint(&cnt, opt, "count") < 0)
	  return 2;
      }
    }

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



    if (cnt == 0) {
      printf ("ctrl:      %08x\n", (unsigned)mpsoc->ctrl);
      printf ("qpll1_sdm: %08x\n", (unsigned)mpsoc->qpll1_sdm);
      printf ("rxpi_samp: %08x\n", (unsigned)mpsoc->rxpi_samp);
      printf ("fifo_ctrl: %08x\n", (unsigned)mpsoc->fifo_ctrl);
      printf ("rdcount:   %08x\n", (unsigned)mpsoc->fifo_rdcount);
      printf ("nfull:     %08x\n", (unsigned)mpsoc->fifo_nfull);
    }
    else {

      fprintf(stderr, "reading %u values every %u samples\n", cnt, samp);

      mpsoc->rxpi_samp = samp;

      /* Flush */
      for (unsigned rdcnt = mpsoc->fifo_rdcount; rdcnt > 0; rdcnt--) {
	mpsoc->fifo_data;
      }

      mpsoc->fifo_nfull = 1;

      mpsoc->fifo_ctrl |= MPSOC_MAP_FIFO_CTRL_EN;

      while (cnt > 0) {
	unsigned rdcnt = mpsoc->fifo_rdcount;

	// printf("rdcnt: %u\n", rdcnt);

	if (rdcnt == 0) {
	  usleep(10);
	  continue;
	}

	if (rdcnt < cnt)
	  cnt -= rdcnt;
	else {
	  cnt = 0;
	  mpsoc->fifo_ctrl &= ~MPSOC_MAP_FIFO_CTRL_EN;
	}
	
	for (; rdcnt > 0; rdcnt--) {
	  uint32_t val = mpsoc->fifo_data;
	  printf ("%u\n", val & 0xffff);
	  printf ("%u\n", val >> 16);
	}
      }

      fprintf(stderr, "nfull: %u\n", mpsoc->fifo_nfull);
    }
    
    return 0;
}
