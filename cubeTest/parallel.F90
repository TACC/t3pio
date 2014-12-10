! -*- f90 -*-
#include "assert.hf"
module parallel
   use mpi
   implicit none

   type Parallel_t
      integer :: myProc
      integer :: nProcs
      integer :: comm
   end type Parallel_t

   integer iProcA(3), nProcA(3)

   type (Parallel_t), save :: p = Parallel_t(0, 1, -1)

contains

   subroutine msg_init(comm)
      implicit none
      integer :: ierr, comm

      call MPI_init(ierr)
      p % comm = comm
      call MPI_Comm_size( p % comm, p % nProcs, ierr)
      ASSERT(ierr == 0, "MPI_Comm_size")
      call MPI_Comm_rank( p % comm, p % myProc, ierr)
      ASSERT(ierr == 0, "MPI_Comm_rank")

   end subroutine msg_init

   subroutine partitionProc(ndim, yzPart)
      implicit none

      integer :: ndim, npA(2)
      logical :: yzPart
      integer :: rem

      if (yzPart) then
         call build2d_partition(npA)
         nProcA(1) = 1
         nProcA(2) = npA(1)
         nProcA(3) = npA(2)
         iProcA(3) = p % myProc/(nProcA(1) * nProcA(2))
         rem       = mod(p % myProc,(nProcA(1) * nProcA(2)))
         iProcA(2) = rem / nProcA(1)
         iProcA(1) = mod(rem,nProcA(1))
         return
      end if
         
      if (ndim == 2) then
         call build2d_partition(nProcA)
         iProcA(1) = mod(p % myProc, nProcA(1))
         iProcA(2) = p % myProc/nProcA(1)

      else if (ndim == 3) then
         call build3d_partition(nProcA)
         iProcA(3) = p % myProc/(nProcA(1) * nProcA(2))
         rem       = mod(p % myProc,(nProcA(1) * nProcA(2)))
         iProcA(2) = rem / nProcA(1)
         iProcA(1) = mod(rem,nProcA(1))
      end if
   end subroutine partitionProc

   subroutine build2d_partition(np)
      integer np(2)
      real(8) :: xp
      integer :: exponent, npx
      
      xp       = sqrt(real(p % nProcs))
      exponent = int(log(xp)/log(2.0)) + 1
      npx      = int(2.0**exponent + 1.5)
      do while ( npx * (p % nProcs/npx) /= p % nProcs)
         npx = npx - 1
      end do

      np(1) = npx
      np(2) = p % nProcs / npx
   end subroutine build2d_partition

   subroutine build3d_partition(np)
      integer np(3)
      real(8) :: xp
      integer :: exponent, npx, npy, npz, npxy
      
      xp  = p % nProcs
      npz = xp**(1.0/3.0) + 1.5
      do while ( npz * (p % nProcs/npz) /= p % nProcs )
         npz = npz - 1
      end do
      npxy = p % nProcs/npz
      npx  = sqrt(real(npxy)) + 1.5
      do while ( npx *(npxy/npx) /= npxy)
         npx = npx - 1
      end do
      npy = npxy/npx

      np(1) = npx
      np(2) = npy
      np(3) = npz

   end subroutine build3d_partition
   



end module parallel
