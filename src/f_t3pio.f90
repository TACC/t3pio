module t3pio

   use mpi

   type T3PIO_Results_t
      integer :: numIO       ! The number of readers/writers
      integer :: numStripes  ! The number of stripes
      integer :: factor      ! numStripes/numIO
      integer :: stripeSize  ! stripe size in bytes
   end type T3PIO_Results_t



contains
   subroutine t3pio_set_info(comm, info, dirIn, ierr,       &
      global_size, max_stripes, factor, file, results)

      integer, parameter            :: PATHMAX = 2048
      integer                       :: comm, info, ierr
      character(*)                  :: dirIn
      integer,          optional    :: global_size, max_stripes, factor
      character(*),     optional    :: file
      character(PATHMAX)            :: dir
      character(PATHMAX)            :: usrFile
      character(256)                :: key, value
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
      
      if (present(results)) then
         call MPI_Info_get_nkeys(info, nkeys, ierr)

         do i = 0, nkeys - 1
            call MPI_Info_get_nthkey(info, i, key, ierr)
            call MPI_Info_get_valuelen(info, key, valuelen, flag, ierr)
            call MPI_Info_get(info, key, valuelen+1, value, flag, ierr)

            if       (key == "cb_nodes") then
               read(value,'(i15)') results % numIO
            else if  (key == "striping_factor") then
               read(value,'(i15)') results % numStripes
            else if  (key == "striping_unit") then
               read(value,'(i15)') results % stripeSize
            end if
         end do

         results % factor = results % numStripes / results % numIO
      end if

   end subroutine t3pio_set_info



end module t3pio
