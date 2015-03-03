module t3pio

   integer, parameter :: T3PIO_OPTIMAL         = -1
   integer, parameter :: T3PIO_BYPASS          = -2
   integer, parameter :: T3PIO_IGNORE_ARGUMENT = -3

   type T3PIO_Results_t
      integer :: numIO       ! The number of readers/writers
      integer :: numStripes  ! The number of stripes
      integer :: stripeSize  ! stripe size in bytes
      integer :: s_dne       ! max number of stripes (do not exceed)
      integer :: s_auto_max  ! min(s_dne,GOOD_CITZENSHIP_STRIPES)
      integer :: nStripesT3  ! The number of stripes T3PIO would chose automatically.
   end type T3PIO_Results_t

contains
   subroutine t3pio_extract_key_values(info, results)
      use mpi
      implicit none

      integer               :: info, i, nkeys, ierr
      integer               :: valuelen
      logical               :: flag
      character(256)        :: key, value
      type(T3PIO_Results_t) :: results

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
   end subroutine t3pio_extract_key_values

   subroutine t3pio_set_info(comm, info, dirIn, ierr, global_size,    &
                             stripe_count, stripe_size_mb, file,      &
                             max_aggregators, results)

      use mpi
      implicit none

      integer, parameter              :: PATHMAX = 2048
      integer                         :: comm, info, ierr, myProc
      character(*)                    :: dirIn
      integer,          optional      :: global_size, stripe_count
      character(*),     optional      :: file
      integer,          optional      :: max_aggregators
      integer,          optional      :: stripe_size_mb
      character(PATHMAX)              :: dir
      character(PATHMAX)              :: usrFile
      integer                         :: len, valuelen
      integer                         :: nWriters
      integer                         :: gblSz, maxStripes, f
      integer                         :: t3piointernal, maxStripeSz
      integer                         :: s_dne, s_auto_max, nStripesT3
      type(T3PIO_Results_t), optional :: results

      nWriters      = T3PIO_OPTIMAL
      gblSz         = T3PIO_OPTIMAL
      maxStripes    = T3PIO_OPTIMAL
      maxStripeSz   = T3PIO_OPTIMAL
      usrFile       = ""


      if (present(max_aggregators))      nWriters      = max_aggregators
      if (present(global_size))          gblSz         = global_size
      if (present(stripe_count))         maxStripes    = stripe_count
      if (present(stripe_size_mb))       maxStripeSz   = stripe_size_mb
      if (present(file))                 usrFile       = file

      len     = len_trim(dirIn)+1
      dir     = dirIn(1:len-1) // CHAR(0)

      len     = len_trim(usrFile)+1
      usrFile = usrFile(1:len-1) // CHAR(0)

      ierr = t3piointernal(comm, info, dir, gblSz, maxStripes, maxStripeSz, &
                           usrFile, nWriters, s_dne, s_auto_max, nStripesT3)
      
      if (present(results)) then
         call t3pio_extract_key_values(info, results)
         results % s_dne      = s_dne
         results % s_auto_max = s_auto_max
         results % nStripesT3 = nStripesT3
      end if

   end subroutine t3pio_set_info

   subroutine t3pio_version(myVersion)
      implicit none
      character(*)  :: myVersion
      integer       :: vlen
      vlen = len(myVersion)
      call t3pioInternalVersion(myVersion, vlen)

   end subroutine t3pio_version


end module t3pio
