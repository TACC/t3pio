#include "comm.h"


Comm::Comm()
{
}


void Comm::init(int * argc, char *** argv, MPI_Comm commIn)
{
  int flag;

  comm = commIn;
  if (comm == MPI_COMM_WORLD)
    {
      MPI_Initialized(&flag);
      if (! flag)
        MPI_Init(argc, argv);
    }

  MPI_Comm_rank(comm, &myProc);
  MPI_Comm_size(comm, &nProcs);
}

void Comm::fini()
{
  MPI_Finalize();
}

Comm::~Comm()
{
  // Do nothing
}
