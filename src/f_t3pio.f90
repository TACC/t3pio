module t3pio

   use mpi

contains
   subroutine t3pio_set_info(comm, info, dirIn, ierr,       &
      global_size, max_stripes, factor, file)

      integer                       :: comm, info, ierr
      character(*)                  :: dirIn
      integer,          optional    :: global_size, max_stripes, factor
      character(*),     optional    :: file
      character(len=:), allocatable :: dir
      integer                       :: dirLen

      if (.not. present(global_size)) global_size = -1
      if (.not. present(max_stripes)) max_stripes = -1
      if (.not. present(factor))      factor      = -1

      dirLen = len_trim(dirIn)+1
      allocate (character(dirLen) :: dir)
      dir  = dirIn(1:dirLen-1) // CHAR(0)

      ierr = t3piointernal(comm, info, dir, global_size, max_stripes, factor)

      deallocate(dir)
   end subroutine t3pio_set_info



end module t3pio
