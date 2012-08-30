! -*- f90 -*-
#include "assert.hf"
#include "top.hf"
program main
   use parallel
   use grid
   use cmdline
   use writer
   implicit none
   include 'mpif.h'
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

   call partitionProc(nDim)

   ! partition grid to local locations.
   call partitionGrid(global, local)

   ! parallel write out file.
   if (HDF5Flag) then
      call h5_writer(local,global)
      if (H5chunk) wrtStyle = "h5chunk"
      if (H5slab)  wrtStyle = "h5slab"
   else
      call parallel_writer(local, global)
      wrtStyle = "romio"
   endif

   if (p % myProc == 0) then
      call outputResults(wrtStyle, local)
   end if

   call MPI_Finalize(ierr);

end program main

subroutine outputResults(wrtStyle, local)

   use parallel
   use grid
   use cmdline
   use writer
   implicit none

   real(8)      :: fileSz
   type(grid_t) :: local
   character(*) :: wrtStyle
   
   fileSz = totalSz /(1024*1024*1024)
   if (LuaOutput) then
      print 1000, p % nProcs, local % num(1), Numvar, trim(wrtStyle), Factor, nIOUnits,  &
           nWritersPer, nStripes, stripeSize/(1024*1024), fileSz, t, rate
   else
      print 1010, p % nProcs, local % num(1), Numvar, Factor, nIOUnits,  nWritersPer, &
           nStripes, stripeSize/(1024*1024), fileSz, t, rate, adjustr(trim(wrtStyle))
   end if

1000 format("%% { nprocs = ",i6, ", lSz = ",i4,", numvar = ",i2,', wrtStyle = "',a,  &
        '", factor = ',i3, ", nWritersPer = ",i5, ", iounits = ",i5, ", nstripes = ", i5,                 &
        ", stripeSz = ", i10, ", fileSz = ", 1pg15.7, ", time = ", 1pg15.7,        &
        ", rate = ", 1pg15.7,"},")

1010 format(/,"cubeTestHDF5 Results: ",/  &
              "--------------------- "//  &
              " Nprocs:        ", i7,/,   &
              " lSz:           ", i7,/,   &
              " Numvar:        ", i7,/,   &
              " factor:        ", i7,/,   &
              " iounits:       ", i7,/,   &
              " nWritersPer:   ", i7,/,   &
              " nstripes:      ", i7,/,   &
              " stripeSz (MB): ", i7,/,   &
              " fileSz (GB):   ", f9.3,/, &
              " time:          ", f9.3,/, &
              " rate (MB/s):   ", f9.3,/, &
              " wrtStyle:      ", a9)

end subroutine outputResults

