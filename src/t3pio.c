#include "config.h"
#include <stdarg.h>
#include "t3pio.h"
#include "t3pio_internal.h"


int t3pio_set_info(MPI_Comm comm, MPI_Info info, const char* dir, ...)
{

  static  T3Pio_t T3;

  T3Pio_t t3;
  int     argType;
  int     ierr = 0;
  va_list ap;
  int     nProcs, myProc


  VA_START(ap, dir);

  if (T3.numNodes < 1)
    t3pio_init(&T3);

  t3init(&t3);
  
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
  VA_END(ap);

  /* Set factor to 2 unless the user specified something different*/
  if (t3.factor < 0)
    t3.factor = 2;

  MPI_Comm_rank(comm, &myProc);
  MPI_Comm_size(comm, &nProcs);
  
  if (
  

  return ierr;
}
