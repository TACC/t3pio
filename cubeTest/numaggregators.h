#ifndef NUMAGGREGATORS_H
#define NUMAGGREGATORS_H

#include "config.h"

#ifdef USE_HDF5
#  include "hdf5.h"
#else
typedef int hid_t;
#endif

#define f_numagg    F77_FUNC(numagg,   NUMAGG)

void f_numagg(hid_t* file_id, int* num);

#endif /* NUMAGGREGATORS_H */
