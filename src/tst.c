#include "t3pio.h"
#include <stdio.h>
#include "mpi.h"
int main(int argc, char* argv[])
{
  
  int i, ierr, myProc, nProcs, globalSize, nkeys, valuelen, flag;
  char key[256];
  char value[256];
  MPI_Info info;

  ierr = MPI_Init(&argc, &argv);
  
  MPI_Comm_rank(MPI_COMM_WORLD, &myProc);
  MPI_Comm_size(MPI_COMM_WORLD, &nProcs);

  MPI_Info_create(&info);

  globalSize = 789;  /* In MB */

  ierr = t3pio_set_info(MPI_COMM_WORLD, info, "./",
                        T3PIO_GLOBAL_SIZE, globalSize);
  

  
  if (myProc == 0)
    {

      ierr = MPI_Info_get_nkeys(info, &nkeys);
      
      
      
      for (i = 0; i < nkeys; ++i)
        {
          ierr = MPI_Info_get_nthkey(info, i, &key[0]);
          ierr = MPI_Info_get_valuelen(info, &key[0], &valuelen, &flag);
          ierr = MPI_Info_get(info, key, valuelen+1, &value[0], &flag);
          printf("Key: %s, \tvalue: %s\n",key,value);
        }
    }

  MPI_Finalize();

  return 0;
}
