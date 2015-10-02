#ifndef T3PIO_H
#define T3PIO_H

#ifdef __cplusplus
extern "C" {
#endif

#include <mpi.h>

#define T3PIO_OPTIMAL               -1
#define T3PIO_BYPASS                -2
#define T3PIO_IGNORE_ARGUMENT       -3
#define T3PIO_START_RANGE         1000
#define T3PIO_GLOBAL_SIZE         1001
#define T3PIO_STRIPE_COUNT        1002
#define T3PIO_FILE                1004
#define T3PIO_RESULTS             1005   
#define T3PIO_MAX_AGGREGATORS     1008
#define T3PIO_STRIPE_SIZE_MB      1009
#define T3PIO_END_RANGE           1010

typedef struct
{
  int numIO;         /* The number of Reader/Writers */
  int numStripes;    /* The number of stripes */
  int numStripesSet; /* The number of stripes that T3Pio set*/
  int factor;        /* numStripes/numIO */
  int stripeSize;    /* stripe size in bytes*/
  int nWritersPer;   /* number of writers per node */
  int numNodes;      /* number of nodes */
  int S_dne;         /* the do not exceed number of stripes */
  int S_auto_max;    /* min(s_dne, GOOD_CITZENSHIP_STRIPES) */
  int nStripesT3;    /* Number of stripes T3PIO would choose */
  int nStripesSet;   /* Number of stripes T3PIO tried to set*/
} T3PIO_results_t;

int t3pio_set_info(MPI_Comm comm, MPI_Info info, const char *dir, ...);

const char* t3pio_version();

#ifdef __cplusplus
}
#endif

#endif  /*T3PIO_H*/
