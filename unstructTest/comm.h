#ifndef COMM_H
#define COMM_H

#include "mpi.h"

class Comm
{
public:
  Comm();
  ~Comm();
  void init(int * argc, char *** argv, MPI_Comm comm);
  void fini();

public:
  int myProc;
  int nProcs;
  MPI_Comm comm;

};



#endif //COMM_H
