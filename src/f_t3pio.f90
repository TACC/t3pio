module t3pio

   use mpi

contains
   subroutine t3pio_set_info(comm, info, dirIn, ierr,       &
      global_size, max_stripes, factor, file)

      integer, parameter            :: PATHMAX = 2048
      integer                       :: comm, info, ierr
      character(*)                  :: dirIn
      integer,          optional    :: global_size, max_stripes, factor
      character(*),     optional    :: file
      character(len=:), allocatable :: dir
      integer                       :: dirLen
      integer                       :: gblSz, maxStripes, f


      gblSz      = -1
      maxStripes = -1
      f          = -1


      if (present(global_size)) gblSz      = global_size
      if (present(max_stripes)) maxStripes = max_stripes
      if (present(factor))      f          = factor

      dirLen = len_trim(dirIn)+1
      
      allocate (character(PATHMAX) :: dir)
      dir  = dirIn(1:dirLen-1) // CHAR(0)

      ierr = t3piointernal(comm, info, dir, gblSz, maxStripes, f)

      deallocate(dir)
   end subroutine t3pio_set_info



end module t3pio
