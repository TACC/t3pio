#include <mpi.h>
#include <stdio.h>
#include <string.h>
#include "t3pio.h"
#include "t3pio_internal.h"

int t3piointernal_(int* f_comm, int* f_info, const char* dir, int* global_sz, 
                   int* max_stripes, int* mStripeSz, const char* file,
                   int* nWriters, int* s_dne, int* s_auto_max, int* nStripesT3,
                   int* nStripesSet)
{
  return t3pio_internal(f_comm, f_info, dir, global_sz, max_stripes, mStripeSz,
                        file, nWriters, s_dne, s_auto_max, nStripesT3, nStripesSet);
}
int T3PIOINTERNAL(int* f_comm, int* f_info, const char* dir, int* global_sz, 
                  int* max_stripes, int* mStripeSz, const char* file,
                  int* nWriters, int* s_dne, int* s_auto_max, int* nStripesT3,
                  int* nStripesSet)
{
  return t3pio_internal(f_comm, f_info, dir, global_sz, max_stripes, mStripeSz,
                        file, nWriters, s_dne, s_auto_max, nStripesT3, nStripesSet);
}

int t3piointernal(int* f_comm, int* f_info, const char* dir, int* global_sz, 
                  int* max_stripes, int* mStripeSz, const char* file,
                  int* nWriters, int* s_dne, int* s_auto_max, int* nStripesT3,
                  int* nStripesSet)
{
  return t3pio_internal(f_comm, f_info, dir, global_sz, max_stripes, mStripeSz,
                        file, nWriters, s_dne, s_auto_max, nStripesT3, nStripesSet);
}

int t3pio_internal(int* f_comm, int* f_info, const char* dir, int* global_sz, 
                   int* max_stripes, int* mStripeSz, const char* file,
                   int* nWriters, int* s_dne, int* s_auto_max, int* nStripesT3,
                   int* nStripesSet)
{
  int             ierr;
  T3PIO_results_t results;
  MPI_Comm        comm = MPI_Comm_f2c(*f_comm);
  MPI_Info        info = MPI_Info_f2c(*f_info);

  ierr = t3pio_set_info(comm, info, dir,
			T3PIO_GLOBAL_SIZE, 	   *global_sz,
			T3PIO_STRIPE_COUNT, 	   *max_stripes,
                        T3PIO_MAX_AGGREGATORS,     *nWriters,
                        T3PIO_STRIPE_SIZE_MB,      *mStripeSz,
			T3PIO_FILE,        	   file,
                        T3PIO_RESULTS,             &results);

  *s_dne       = results.S_dne;
  *s_auto_max  = results.S_auto_max;
  *nStripesT3  = results.nStripesT3;
  *nStripesSet = results.nStripesSet;
  *f_info      = MPI_Info_c2f(info);

  return   ierr;
}



void t3piointernalversion_(char* v, int *len)
{
  t3pio_version_internal(v, len);
}
void t3piointernalversion(char* v, int *len)
{
  t3pio_version_internal(v, len);
}
void T3PIOINTERNALVERSION(char* v, int *len)
{
  t3pio_version_internal(v, len);
}

void  t3pio_version_internal(char *v, int *len)
{
  const char* myVersion = t3pio_version();
  int slen              = strlen(myVersion);
  int vlen              = *len;
  slen = (slen < vlen) ? slen : vlen;
  memcpy(v, myVersion, slen);
  if (vlen > slen)
    memset(&v[slen],' ', vlen - slen); 
}
