#ifndef T3PIO_H
#define T3PIO_H

#include <mpi.h>

#define T3PIO_GLOBAL_SIZE  1001
#define T3PIO_MAX_STRIPES  1002
#define T3PIO_FACTOR       1003
#define T3PIO_FILE         1004
#define T3PIO_RESULT       1005

typedef struct
{
  int numIO;        /* The number of Reader/Writers */
  int numStripes;   /* The number of stripes */
  int factor;       /* numStripes/numIO */
  int stripeSize;   /* stripe size in bytes*/
} T3PIO_results_t;

int t3pio_set_info(MPI_Comm comm, MPI_Info info, const char *dir, ...);





#endif  /*T3PIO_H*/
