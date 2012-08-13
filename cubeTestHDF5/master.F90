! -*- f90 -*-
#include "assert.hf"
#include "top.hf"
program main
   use mpi
   use parallel
   use grid
   use cmdline
   use writer
   implicit none
   real(8)       :: fileSz
   integer       :: i, j, k, ii, jj, ierr
   character(7)  :: wrtStyle

   type(grid_t) :: global, local

   call msg_init(MPI_COMM_WORLD)
   call parse()

   if (VersionFlag .or. HelpFlag) then
      if (p % myProc == 0) then
         print *, "cubeTestHDF5 version 1.0"
         if (HelpFlag) call usage()
      end if
      call MPI_Finalize(ierr)
      call exit()
   end if

   HERE
   call partitionProc(nDim)
   HERE

   ! partition grid to local locations.
   call partitionGrid(global, local)
   HERE

   ! parallel write out file.
   if (HDF5Flag) then
      HERE
      call h5_writer(local,global)
      if (H5chunk) wrtStyle = "h5chunk"
      if (H5slab)  wrtStyle = "h5slab"
      HERE
   else
      HERE
      call parallel_writer(local, global)
      HERE
      wrtStyle = "romio"
   endif
   HERE

   if (p % myProc == 0) then
      fileSz = totalSz/(1024.0*1024.0*1024.0)
      print 1000, p % nProcs, local % num(1), Numvar, trim(wrtStyle), Factor, nIOUnits,  &
           nStripes, stripeSize/(1024*1024), fileSz, t, rate
   end if

   call MPI_Finalize(ierr);

1000 format("%% { nprocs = ",i6, ", lSz = ",i4,", numvar = ",i2,', wrtStyle = "',a,'", factor = ',i3,   &
          ", iounits = ",i5, ", nstripes = ", i5, ", stripeSz = ", i10, ", fileSz = ", 1pg15.7, ", time = ", 1pg15.7,       &
          ", rate = ", 1pg15.7,"},")
end program main
