! -*- f90 -*-
#include "assert.hf"
#include "top.hf"
program main
   use parallel
   use grid
   use cmdline
   use writer
   use mpi
   implicit none
   integer       :: i, j, k, ii, jj, ierr
   character(7)  :: wrtStyle

   type(grid_t) :: global, local

   call msg_init(MPI_COMM_WORLD)
   call parse()

   if (VersionFlag .or. HelpFlag) then
      if (p % myProc == 0) then
         print *, "cubeTest version 1.0"
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
      call outputResults(wrtStyle, local, global)
   end if

   call MPI_Finalize(ierr);

end program main

subroutine outputResults(wrtStyle, local, global)

   use parallel
   use grid
   use cmdline
   use writer
   use t3pio
   implicit none

   real(8)       :: fileSz
   type(grid_t)  :: local, global
   character(*)  :: wrtStyle
   character(15) :: xferStyle
   character(80) :: t3pioV

   if (Collective) then
      xferStyle="Collective"
   else
      xferStyle="Independent"
   end if
      
   call t3pio_version(t3pioV)
   
   fileSz = totalSz /(1024*1024*1024)
   if (LuaOutput) then
      print 1000, adjustr(trim(t3pioV)), p % nProcs, local % num(1),        &
           global % num(1), Numvar, trim(wrtStyle), trim(xferStyle),        &
           nIOUnits, aggregators, nStripes, stripeSize/(1024*1024),         &
           fileSz, totalTime, rate
   end if
   if (TableOutput) then
      print 1010, p % nProcs, local % num(1), global % num(1), Numvar,      &
           nIOUnits, aggregators, nStripes, stripeSize/(1024*1024),         &
           fileSz, totalTime, rate, adjustr(trim(wrtStyle)),                &
           adjustr(trim(xferStyle)), adjustr(trim(t3pioV))
   end if

1000 format("%% { t3pioV = '", a,"', nprocs = ",i6, ", lSz = ",i4, ", gSz = ",i5, &
          ", numvar = ",i2, ', wrtStyle = "',a, '", xferStyle = "',a,'"',         &
          ", iounits = ",i5, ", aggregators = ",i5, ", nstripes = ", i5,          &
          ", stripeSz = ", i10, ", fileSz = ", 1pg15.7,", totalTime = ", 1pg15.7, &
          ", rate = ", 1pg15.7,"},")

1010 format(/,"cubeTest Results: ",/  &
              "--------------------- "//  &
              " Nprocs:        ", i7,/,   &
              " lSz:           ", i7,/,   &
              " gSz:           ", i7,/,   &
              " Numvar:        ", i7,/,   &
              " iounits:       ", i7,/,   &
              " aggregators:   ", i7,/,   &
              " nstripes:      ", i7,/,   &
              " stripeSz (MB): ", i7,/,   &
              " fileSz (GB):   ", f9.3,/, &
              " totalTime:     ", f9.3,/, &
              " rate (MB/s):   ", f9.3,/, &
              " wrtStyle:      ", a9,/,   &
              " xferStyle:     ", a11,/,  &
              " t3pioV:        ", a)
   

end subroutine outputResults

