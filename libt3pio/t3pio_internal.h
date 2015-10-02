#ifndef T3PIO_INTERNAL_H
#define T3PIO_INTERNAL_H

#include "t3pio.h"
#include <mpi.h>
typedef struct
{
  int globalSz;
  int maxStripes;
  int factor;
  int numNodes;
  int numCoresPer;
  int maxCoresPer;
  int numIO;
  int numStripes;
  int nodeMem;
  int stripeSz;
  int maxWriters;
  int S_dne;
  int S_auto_max;
  int nStripesT3;
  int nStripesSet;
  char* fn;
} T3Pio_t;

void t3pio_extract_key_values(MPI_Info info, T3Pio_t *t3, T3PIO_results_t* r);
void t3pio_init(T3Pio_t* t3);
void t3pio_numComputerNodes(MPI_Comm comm, int nProc,  int* numNodes);
int  t3pio_maxStripes(MPI_Comm comm,       int myProc, const char* dir);
int  t3pio_readStripes(MPI_Comm comm,      int myProc, const char* fn);
int  t3pio_nodeMemory(MPI_Comm comm,       int myProc);
int  t3pio_maxStripesPossible(MPI_Comm comm, int myProc);
int  t3pio_lustre_version();
void t3pio_version_internal(char *v, int *len);

int  t3pio_internal(int* f_comm, int* f_info, const char* dir, int* global_size, int* max_stripes,
                    int* max_stripe_size, const char* file, int* maxWriters, int* s_dne,
                    int* s_auto_max, int* nStripesT3, int* nStripesSet);



#endif /* T3PIO_INTERNAL_H */

