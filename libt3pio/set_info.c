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

#define prt(x) if (myProc == 0) printf("%s:%d: %s: %d\n",__FILE__,__LINE__,#x,x)

int t3pio_parse_int_arg(int orig, int value)
{
  if (value == T3PIO_IGNORE_ARGUMENT)
    return orig;
  return value;
}

void t3pio_extract_key_values(MPI_Info info, T3PIO_results_t* r)
{
  int ierr;
  if (r)
    {
      char key[128], value[128];
      int i, valuelen, nkeys, flag;
      ierr = MPI_Info_get_nkeys(info, &nkeys);

      for (i = 0; i < nkeys; ++i)
        {
          ierr = MPI_Info_get_nthkey(info, i, key);
          ierr = MPI_Info_get_valuelen(info, key, &valuelen, &flag);
          ierr = MPI_Info_get(info, key, valuelen+1, value, &flag);

          if      (strcmp("cb_nodes",        key) == 0) sscanf(value, "%d", &(*r).numIO);
          else if (strcmp("striping_factor", key) == 0) sscanf(value, "%d", &(*r).numStripes);
          else if (strcmp("striping_unit",   key) == 0) sscanf(value, "%d", &(*r).stripeSize);
        }
    }
}

int t3pio_set_info(MPI_Comm comm, MPI_Info info, const char* path, ...)
{

  T3Pio_t t3;
  int     argType;
  int     ierr = 0;
  va_list ap;
  int     nProcs, myProc;
  char    buf[128];
  int     S_dne, S_auto_max;
  int     mStripeSz     = -1;

  T3PIO_results_t *results = NULL;

  t3pio_init(&t3);
  
  va_start(ap, path);

  while ( (argType = va_arg(ap, int)) != 0)
    {
      if (argType <= T3PIO_START_RANGE || argType >= T3PIO_END_RANGE )
        break;

      switch(argType)
        {
        case T3PIO_GLOBAL_SIZE:
          t3.globalSz   = va_arg(ap,int);
          break;
        case T3PIO_STRIPE_COUNT:
          t3.maxStripes = t3pio_parse_int_arg(t3.maxStripes, va_arg(ap,int));
          break;
        case T3PIO_MAX_AGGREGATORS:
          t3.maxWriters = t3pio_parse_int_arg(t3.maxWriters, va_arg(ap,int));
          break;
        case T3PIO_STRIPE_SIZE_MB:
          mStripeSz     = t3pio_parse_int_arg(t3.stripeSz,   va_arg(ap,int));
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

  /* Set max Stripe Sz to make sense:
     a) value == -2  => Do Not Set
     b) value <   1  => 2MByte
     c) value >   1  => (value)*1 Mbyte
   */

  if (mStripeSz == T3PIO_BYPASS)
    mStripeSz = -1;
  else
    {
      if (mStripeSz < 1)
        mStripeSz = 2;
      mStripeSz = (1 << 20) * mStripeSz;
    }


  MPI_Comm_rank(comm, &myProc);
  MPI_Comm_size(comm, &nProcs);
  
  t3.stripeSz   = 1024 * 1024;

  S_dne       = t3pio_maxStripes(comm, myProc, path);

  if (getenv("T3PIO_BYPASS"))
    {
      if (results)
        t3pio_extract_key_values(info, results);
      return ierr;
    }

  if (t3.fn && t3.fn[0])
    {
      /* Check for user supplied file for reading */

      t3.numStripes = t3pio_readStripes(comm, myProc, t3.fn);
      t3.stripeSz   = -1;    /* Can not change stripe sz on files to be read */
    }
  else if (t3.maxStripes != T3PIO_BYPASS)
    {
      S_auto_max  = min(S_dne, GOOD_CITZENSHIP_STRIPES);
      if (t3.numNodes >= S_auto_max )
        t3.numStripes  = S_auto_max;
      else
        {
          int k = min(S_auto_max / t3.numNodes, MAX_STRIPES_PER_NODE);
          t3.numStripes = k * t3.numNodes;
        }
      if (t3.maxStripes > 0)
        t3.numStripes = min(S_dne, t3.maxStripes);
    }

  if (t3.maxWriters == T3PIO_BYPASS) 
    t3.numIO = -1;
  else if (t3.maxWriters == T3PIO_OPTIMAL) 
    t3.numIO = t3.numStripes;
  else if (t3.maxWriters > 0)
    t3.numIO  = min(nProcs, t3.maxWriters);

  t3.stripeSz = mStripeSz;

  if (t3.numIO > 0)
    {
      sprintf(buf, "%d", t3.numIO);
      MPI_Info_set(info, (char *) "cb_nodes", buf);
    }
  if (t3.numStripes > 0)
    {
      sprintf(buf, "%d", t3.numStripes);
      MPI_Info_set(info, (char *) "striping_factor", buf);
    }
  if (t3.stripeSz > 0)
    {
      sprintf(buf, "%d", t3.stripeSz);
      MPI_Info_set(info, (char *) "striping_unit", buf);
    }

  if (results)
    t3pio_extract_key_values(info, results);

  return ierr;
}
