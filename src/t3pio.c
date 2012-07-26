#include "config.h"
#include <stdarg.h>
#include <stdio.h>
#include "t3pio.h"
#include "t3pio_internal.h"
#include <math.h>

#define min(x,y) (x) > (y) ? y : x;
#define max(x,y) (x) > (y) ? x : y;

int t3pio_set_info(MPI_Comm comm, MPI_Info info, const char* dir, ...)
{

  T3Pio_t t3;
  int     argType;
  int     ierr = 0;
  va_list ap;
  int     nProcs, myProc;
  char    buf[128];

  t3pio_init(&t3);
  
  va_start(ap, dir);

  while ( (argType = va_arg(ap, int)) != 0)
    {
      switch(argType)
        {
        case T3PIO_GLOBAL_SIZE:
          t3.globalSz   = va_arg(ap,int);
          break;
        case T3PIO_MAX_STRIPES:
          t3.maxStripes = va_arg(ap,int);
          break;
        case T3PIO_FACTOR:
          t3.factor = va_arg(ap,int);
          break;
        case T3PIO_FILE:
          t3.fn = va_arg(ap,char *);
          break;
        }
    }
  va_end(ap);

  /* Set factor to 2 unless the user specified something different*/
  if (t3.factor < 0)
    t3.factor = 2;

  MPI_Comm_rank(comm, &myProc);
  MPI_Comm_size(comm, &nProcs);
  
  t3.nodeMem    = t3pio_nodeMemory(comm, myProc);
  t3.numNodes   = t3pio_numComputerNodes(comm, nProcs);
  t3.numStripes = t3pio_maxStripes(comm, myProc, dir);

  if (t3.numNodes * t3.factor < t3.numStripes)
    t3.numStripes = t3.numNodes*t3.factor;

  if (t3.maxStripes > 0)
    {
      t3.numIO = t3.maxStripes / t3.factor;
      if (t3.numIO > 2*t3.numNodes) t3.numIO = 2*t3.numNodes;
      t3.numStripes = t3.numIO*t3.factor;
    }

  t3.numIO = t3.numStripes / t3.factor;

  if (t3.globalSz > 0)
    {
      double log2     = log(2.0);
      double numCores = nProcs/t3.numNodes;
      double coreMem  = t3.nodeMem/numCores;
      double bufMemSz = coreMem/16.0;
      double coreExp  = floor(log(bufMemSz)/log2);
      double sz       = ((double)t3.globalSz) / ((double)t3.numIO);
      double exp      = floor(log(sz)/log2);
      exp             = min(coreExp,exp);
      exp             = max(1.0, exp);
      t3.stripeSz     = (1 << ((int) exp)) * 1024 * 1024;
    }

  sprintf(buf, "%d", t3.numIO);
  MPI_Info_set(info, (char *) "cb_nodes", buf);
  sprintf(buf, "%d", t3.numStripes);
  MPI_Info_set(info, (char *) "striping_factor", buf);

  if (t3.stripeSz > 0)
    {
      sprintf(buf, "%d", t3.stripeSz);
      MPI_Info_set(info, (char *) "striping_unit", buf);
    }

  return ierr;
}
