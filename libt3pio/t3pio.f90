module t3pio

   integer, parameter :: T3PIO_OPTIMAL = -1
   integer, parameter :: T3PIO_BYPASS  = -2
   integer, parameter :: T3PIO_UNSET   = -3

   type T3PIO_Results_t
      integer :: numIO       ! The number of readers/writers
      integer :: numStripes  ! The number of stripes
      integer :: stripeSize  ! stripe size in bytes
   end type T3PIO_Results_t

contains
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
      character(256)                  :: key, value
      integer                         :: len, valuelen
      integer                         :: nkeys, i, nWriters
      logical                         :: flag
      integer                         :: gblSz, maxStripes, f
      integer                         :: t3piointernal, maxStripeSz
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
                           usrFile, nWriters)
      
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
