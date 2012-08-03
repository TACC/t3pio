#include "parallel.h"


Parallel::Parallel()
{
}


void Parallel::init(int * argc, char *** argv, MPI_Comm commIn)
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


void Parallel::fini()
{
  MPI_Finalize();
}



Parallel::~Parallel()
{
  // Do nothing
}
