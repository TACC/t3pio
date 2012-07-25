module t3pio

   use mpi

contains
   subroutine t3pio_set_info(comm, info, ierr,
      global_size, max_stripes, factor, file)

      integer                :: comm, info, ierr
      integer,      optional :: global_size, max_stripes, factor
      character(*), optional :: file

      if (.not. present(global_size)) global_size = -1
      if (.not. present(max_stripes)) max_stripes = -1
      if (.not. present(factor))      factor      = -1


      ierr = t3piointernal(comm, info, global_size, max_stripes, factor)

   end subroutine t3pio_set_info



end module t3pio
