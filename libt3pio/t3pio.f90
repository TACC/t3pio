module t3pio

   type T3PIO_Results_t
      integer :: numIO       ! The number of readers/writers
      integer :: numStripes  ! The number of stripes
      integer :: factor      ! numStripes/numIO
      integer :: stripeSize  ! stripe size in bytes
      integer :: nWritersPer ! number of writers per node.
      integer :: nWriters    ! Total number of writers.
   end type T3PIO_Results_t



contains
   subroutine t3pio_set_info(comm, info, dirIn, ierr,       &
        global_size, stripe_count, stripe_size_mb, factor,  &
        file, results, max_writers_per_node, max_aggregators)

      use mpi
      implicit none

      integer, parameter              :: PATHMAX = 2048
      integer                         :: comm, info, ierr, myProc
      character(*)                    :: dirIn
      integer,          optional      :: global_size, stripe_count, factor
      character(*),     optional      :: file
      integer,          optional      :: max_writers_per_node, max_aggregators
      integer,          optional      :: stripe_size_mb
      character(PATHMAX)              :: dir
      character(PATHMAX)              :: usrFile
      character(256)                  :: key, value
      integer                         :: len, valuelen, maxWritersPer
      integer                         :: nNodes, nkeys, i, nWriters
      logical                         :: flag
      integer                         :: gblSz, maxStripes, f
      integer                         :: t3piointernal, maxStripeSz
      type(T3PIO_Results_t), optional :: results

      


      nWriters      = -1
      maxWritersPer = -1
      gblSz         = -1
      maxStripes    = -1
      maxStripeSz   = -1
      f             = -1
      usrFile       = ""


      if (present(max_aggregators))      nWriters      = max_aggregators
      if (present(max_writers_per_node)) maxWritersPer = max_writers_per_node
      if (present(global_size))          gblSz         = global_size
      if (present(stripe_count))         maxStripes    = stripe_count
      if (present(stripe_size_mb))       maxStripeSz   = stripe_size_mb
      if (present(factor))               f             = factor
      if (present(file))                 usrFile       = file

      len     = len_trim(dirIn)+1
      dir     = dirIn(1:len-1) // CHAR(0)

      len     = len_trim(usrFile)+1
      usrFile = usrFile(1:len-1) // CHAR(0)

      ierr = t3piointernal(comm, info, dir, gblSz, maxStripes, maxStripeSz, &
                           f, usrFile, maxWritersPer, nWriters, nNodes)
      
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

         results % factor      = results % numStripes / results % numIO
         results % nWritersPer = max(results % numIO /nNodes,1)
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
