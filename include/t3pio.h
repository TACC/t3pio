#ifndef T3PIO_H
#define T3PIO_H

#ifdef __cplusplus
extern "C" {
#endif

#include <mpi.h>

#define T3PIO_START_RANGE         1000
#define T3PIO_GLOBAL_SIZE         1001
#define T3PIO_MAX_STRIPES         1002
#define T3PIO_FACTOR              1003
#define T3PIO_FILE                1004
#define T3PIO_RESULTS             1005   
#define T3PIO_MAX_WRITER_PER_NODE 1006
#define T3PIO_NUM_NODES           1007
#define T3PIO_MAX_WRITERS         1008
#define T3PIO_MAX_STRIPE_SIZE     1009
#define T3PIO_END_RANGE           1010

typedef struct
{
  int numIO;         /* The number of Reader/Writers */
  int numStripes;    /* The number of stripes */
  int factor;        /* numStripes/numIO */
  int stripeSize;    /* stripe size in bytes*/
  int nWritersPer;   /* number of writers per node */
} T3PIO_results_t;

int t3pio_set_info(MPI_Comm comm, MPI_Info info, const char *dir, ...);

const char* t3pio_version();

#ifdef __cplusplus
}
#endif

#endif  /*T3PIO_H*/
