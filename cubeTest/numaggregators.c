#include <mpi.h>
#include "numaggregators.h"
#include "t3pio.h"

void f_numagg(hid_t *file_id, int *num)
{
#ifndef USE_HDF5
  *num = 0;
#else

  int             ierr;
  MPI_Comm        commF;
  MPI_File       *pFH = NULL;
  MPI_Info        infoF = MPI_INFO_NULL;
  T3PIO_results_t results;

  ierr = MPI_Info_create(&infoF);
  ierr = H5Fget_vfd_handle(*file_id, &infoF);
  t3pio_extract_key_values(infoF, &results);
  *num = results.numIO;

  ierr = MPI_Info_free(&infoF);
#endif
}
