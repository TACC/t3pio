! -*- f90 -*-
module grid
   integer, parameter :: MAXDIM = 3

   type grid_t
      integer :: nd
      integer :: is(MAXDIM), ie(MAXDIM)
      integer :: num(MAXDIM)
   end type grid_t

contains
   subroutine partitionGrid (global, local)
      use parallel
      use cmdline
      implicit none
      type (grid_t) global, local

      integer :: is, ie, rem, i, n

      global % num(3) = 1
      local  % num(3) = 1


      global % nd = nDim
      do i = 1, nDim
         global % is(i) = 1
      end do

      if (GblSz == 0) then
         do i = 1, nDim
            n               = LocalSz * nProcA(i)
            global % ie(i)  = n
            global % num(i) = n
         end do
      else
         do i = 1, nDim
            global % ie(i)  = GblSz
            global % num(i) = GblSz
         end do
      end if

      local % nd = nDim
      do i = 1, nDim
         n =       global % num(i) / nProcA(i)
         rem = mod(global % num(i),  nProcA(i))
         if (iProcA(i) < rem ) then
            n  = n + 1
            is = n * iProcA(i) + 1
         else
            is = (n+1)*rem + (iProcA(i) - rem) * n + 1
         end if
         ie = is + n - 1
         local % is(i)  = is
         local % ie(i)  = ie
         local % num(i) = ie - is + 1
      end do

   end subroutine partitionGrid

end module grid
