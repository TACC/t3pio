#include "config.h"
#include "limits.h"
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
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
  int     remoteFile    = 0;
  int     maxWritersPer = INT_MAX;
  int*    pNodes        = NULL;

  T3PIO_results_t *results = NULL;


  t3pio_init(&t3);
  
  va_start(ap, dir);

  while ( (argType = va_arg(ap, int)) != 0)
    {
      if (argType <= T3PIO_START_RANGE || argType >= T3PIO_END_RANGE )
        break;

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
        case T3PIO_MAX_WRITERS:
          t3.maxWriters = va_arg(ap,int);
          break;
        case T3PIO_NUM_NODES:
          pNodes = va_arg(ap, int*);
          break;
        case T3PIO_MAX_WRITER_PER_NODE:
          maxWritersPer= va_arg(ap,int);
          break;
        case T3PIO_FILE:
          t3.fn = va_arg(ap,char *);
          break;
        case T3PIO_RESULTS:
          results = va_arg(ap, T3PIO_results_t *);
          break;
        }
    }
  va_end(ap);

  /* Check for valid maxWritersPer */
  if (maxWritersPer < 0)
    maxWritersPer = INT_MAX;

  /* Set factor to 1 unless the user specified something different*/
  if (t3.factor < 0 || t3.factor > 4)
    t3.factor = 1;

  MPI_Comm_rank(comm, &myProc);
  MPI_Comm_size(comm, &nProcs);
  
  t3pio_numComputerNodes(comm, nProcs, &t3.numNodes, &t3.numCoresPer, &t3.maxCoresPer);
  t3.nodeMem    = t3pio_nodeMemory(comm, myProc);
  t3.stripeSz   = 1024 * 1024;
  if (pNodes) 
    *pNodes     = t3.numNodes;
  

  if (t3.fn && t3.fn[0])
    {
      /* Check for user supplied file for reading */

      t3.numStripes = t3pio_readStripes(comm, myProc, t3.fn);
      if (t3.numNodes * t3.factor < t3.numStripes)
        t3.numStripes = t3.numNodes * t3.factor;

      t3.stripeSz = -1;         /* Can not change stripe sz on files
                                   to be read */
      remoteFile = 1;
    }
          
  else
    {
      int half        = max(t3.maxCoresPer/2, 1);
      int nWritersPer = min(t3.numCoresPer, half);
      maxWritersPer   = min(nWritersPer, maxWritersPer)
      int maxPossible = t3pio_maxStripes(comm, myProc, dir);

      /* No more than 2/3 of the max stripes possible */
      t3.numStripes    = maxPossible*2/3;  

      /* No more than maxWriters per node*/
      t3.numStripes    = min(t3.numStripes, t3.factor*t3.numNodes*maxWritersPer);
      
      if (t3.maxStripes > 0)
        t3.numStripes = min(maxPossible,    t3.maxStripes);
    }

  t3.numIO = t3.numStripes / t3.factor;

  if (t3.maxWriters > 0)
    {
      t3.numIO  = min(nProcs, t3.maxWriters);
      t3.factor = t3.numStripes / t3.numIO;
    }


  if (t3.globalSz > 0 && !remoteFile)
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
      t3.stripeSz     = 1 << ((int) exp) + 20;
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


  if (results)
    {
      char key[128], value[128];
      int i, valuelen, nkeys, flag;
      ierr = MPI_Info_get_nkeys(info, &nkeys);

      for (i = 0; i < nkeys; ++i)
        {
          ierr = MPI_Info_get_nthkey(info, i, key);
          ierr = MPI_Info_get_valuelen(info, key, &valuelen, &flag);
          ierr = MPI_Info_get(info, key, valuelen+1, value, &flag);

          if      (strcmp("cb_nodes",        key) == 0) sscanf(value, "%d", &(*results).numIO);
          else if (strcmp("striping_factor", key) == 0) sscanf(value, "%d", &(*results).numStripes);
          else if (strcmp("striping_unit",   key) == 0) sscanf(value, "%d", &(*results).stripeSize);
        }
      results->factor      = results->numStripes/results->numIO;
      results->nWritersPer = max(results->numIO/t3.numNodes, 1);
    }

  return ierr;
}
