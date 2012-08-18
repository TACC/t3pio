#include <stdio.h>
#define OMPI_SKIP_MPICXX  1
#define MPICH_SKIP_MPICXX 1
#include "parallel.h"
#include "cmdLineOptions.h"
#include "h5test.h"
#include "h5writer.h"
Parallel P;


void outputResults(CmdLineOptions& cmd, H5& h5);


int main(int argc, char* argv[])
{

  P.init(&argc, &argv, MPI_COMM_WORLD);

  CmdLineOptions cmd(argc, argv);
  CmdLineOptions::state_t state = cmd.state();
  if (state != CmdLineOptions::iGOOD)
    {
      MPI_Finalize();
      return (state == CmdLineOptions::iBAD);
    }
  
  H5 h5;

  h5.writer(cmd);

  if (P.myProc == 0)
    outputResults(cmd, h5);

  P.fini();

  return 0;
}

void outputResults(CmdLineOptions& cmd, H5& h5)
{
  double fileSz = h5.totalSz()/(1024.0 * 1024.0 * 1024.0);

  if (cmd.luaStyleOutput)
    {
      printf("%%%% { nprocs = %d, lSz = %d, wrtStyle = \"%s\", factor = %d, iounits = %d, "
             " nstripes = %d, stripeSzMB = %d,  fileSzGB = %15.7g, time = %15.7g, rate = %15.7g }\n",
             P.nProcs, cmd.localSz, cmd.h5style.c_str(), h5.factor(), h5.nIOUnits(), h5.nStripes(),
             h5.stripeSzMB(), fileSz, h5.time(), h5.rate());
    }
  else
    {
      printf("\nunstructTestHDF5:\n"
             "-------------------\n\n"
             " Nprocs:           %9d\n"  
             " lSz:              %9d\n"
             " Numvar:           %9d\n"
             " factor:           %9d\n"
             " iounits:          %9d\n"
             " nstripes:         %9d\n"
             " stripeSz (MB):    %9d\n"
             " fileSz (GB):      %9.3f\n"
             " time (sec):       %9.3f\n"
             " rate (MB/s):      %9.3f\n"
             " wrtStyle:         %9s\n",
             P.nProcs, cmd.localSz, h5.numvar(), h5.factor(), h5.nIOUnits(),
             h5.nStripes(), h5.stripeSzMB(), fileSz, h5.time(), h5.rate(),
             cmd.h5style.c_str());

    }

}
