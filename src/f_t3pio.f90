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
      character(PATHMAX)            :: dir
      character(PATHMAX)            :: usrFile
      integer                       :: len
      integer                       :: gblSz, maxStripes, f


      gblSz      = -1
      maxStripes = -1
      f          = -1
      usrFile    = ""


      if (present(global_size)) gblSz      = global_size
      if (present(max_stripes)) maxStripes = max_stripes
      if (present(factor))      f          = factor
      if (present(file))        usrFile    = file

      len     = len_trim(dirIn)+1
      dir     = dirIn(1:len-1) // CHAR(0)

      len     = len_trim(usrFile)+1
      usrFile = usrFile(1:len-1) // CHAR(0)

      ierr = t3piointernal(comm, info, dir, gblSz, maxStripes, f, usrFile)
      

   end subroutine t3pio_set_info



end module t3pio
