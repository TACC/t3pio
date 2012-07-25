#ifndef T3PIO_INTERNAL_H
#define T3PIO_INTERNAL_H

#include <mpi.h>
typedef struct
{
  int globalSz;
  int maxStripes;
  int factor;
  int numNodes;
  int numIO;
  int numStripes;
  int stripeSz;
  char* dir;
  char* fn;
} T3Pio_t;

void t3pio_init(T3pio_t* t3);
int t3pio_numComputerNodes(MPI_Comm comm, int nProc);
int t3pio_maxStripes(MPI_Comm comm,       int myProc)


#endif /* T3PIO_INTERNAL_H */

