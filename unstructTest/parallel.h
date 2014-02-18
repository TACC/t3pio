#ifndef PARALLEL_H
#define PARALLEL_H

#include "mpi.h"

class Parallel
{
public:
  Parallel();
  ~Parallel();
  void init(int * argc, char *** argv, MPI_Comm comm);
  void fini();

public:
  int myProc;
  int nProcs;
  MPI_Comm comm;

};



#endif //PARALLEL_H
