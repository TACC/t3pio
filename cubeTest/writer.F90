! -*- f90 -*-
#include "assert.hf"
#include "top.hf"
#define FILE_NAME "CUBE"
module writer
   use grid
   use parallel
   use cmdline
   use mpi
#ifdef USE_HDF5
   use hdf5
#endif
   use t3pio
   implicit none 
   real(8)          :: t0, t1, t2, t3
   integer          :: nIOUnits, nStripes, stripeSize, aggregators
   integer          :: s_dne, s_auto_max, nStripesT3
   character(80)    :: fn
   character(256)   :: buffer
   integer(8)       :: lSz
   real(8)          :: rate      = 0.0d0
   real(8)          :: totalSz   = 0.0d0
   real(8)          :: totalTime = 0.0d0


   type Var_t
      character(8)  :: name
      character(40) :: descript
   end type Var_t

   type (var_t), save :: varT(9) = (/ Var_t("T", "Temp in K"),          &
                                      Var_t("p", "Pressure in N/m^2"),  &
                                      Var_t("u", "X Velocity in m/s"),  &
                                      Var_t("v", "Y Velocity in m/s"),  &
                                      Var_t("w", "Z Velocity in m/s"),  &
                                      Var_t("a", "Fake variable A  "),  &
                                      Var_t("b", "Fake Variable B  "),  &
                                      Var_t("c", "Fake Variable C  "),  &
                                      Var_t("d", "Fake Variable D  ")   /)

   character(66), save :: msg(7) = (/&
        !******************************************************************
        "This is only fake test text to be written out to the h5 file      ", & ! 1
        "Had this been a real program run then real Q/A data could go here.", & ! 2
        "For the sake of doing something reasonable we include the time    ", & ! 3
        "this was run to show that it is possible:                         ", & ! 4
        "                                                                  ", & ! 5
        "                                                                  ", & ! 6
        "                                                                  "  /)

contains
   subroutine h5_writer(local, global)
      type(grid_t)     :: local, global

#     ifdef USE_HDF5
      integer(hid_t)   :: file_id      ! File    identifier
      integer(hid_t)   :: group_id     ! Group   identifier
      integer(hid_t)   :: dset_id      ! Dataset identifier
      integer(hid_t)   :: filespace    ! Dataspace identifier in file
      integer(hid_t)   :: memspace     ! Dataspace identifier in memory
      integer(hid_t)   :: plist_id     ! Property list identifier
      integer(HSIZE_t) :: sz(3),gsz(3), starts(3), count(3), block(3), h5stride(3)

      type(T3PIO_results_t) :: results

      integer, allocatable :: newSeed(:)

      character(40)    :: date, time
      integer          :: info,infoF   ! mpi info
      integer          :: xfer_mode    ! Transfer mode: Collective/Independent
      integer          :: i, ierr, m, iseed
      integer          :: iTotalSz, istat, commF
      real(8)          :: walltime
      real(8), allocatable :: u(:)

      if (Collective) then
         xfer_mode = H5FD_MPIO_COLLECTIVE_F
      else
         xfer_mode = H5FD_MPIO_INDEPENDENT_F
      end if


      !------------------------------------------------------------
      ! Form a random value using system random_seed

      call random_seed(size=m)
      allocate(newSeed(m))

      iseed = walltime()
      newSeed = iseed
      call random_seed(put=newSeed)

      !------------------------------------------------------------
      ! Compute global size of solution vector(s)

      lSz = 1
      totalSz = 8.0
      do i = 1, local % nd
         count(i)    = 1
         h5stride(i) = 1
         starts(i)   = local % is(i) - 1
         sz(i)       = local % num(i)
         gsz(i)      = global % num(i)
         lSz         = lSz * local % num(i)
         totalSz     = totalSz * DBLE(global % num(i))
      end do
      totalSz  = totalSz * Numvar
      iTotalSz = totalSz / (1024*1024)
      allocate(u(lSz), stat = istat)

      if (istat /= 0) then
         print *, "unable to allocate soln vector u, istat: ",istat
      end if

      call init3d(local, u)
      

      !------------------------------------------------------------
      ! Delete old file if it exists

      fn = FILE_NAME // ".h5"
      if ( p % myProc == 0) then
         call MPI_File_delete(fn,MPI_INFO_NULL,ierr)
      end if
      call MPI_Barrier(p % comm,ierr)

      !------------------------------------------------------------
      ! Create an MPI Info object and use the T3PIO library to
      ! initialize it.

      info = MPI_INFO_NULL
      call MPI_Info_create(info, ierr)
      ASSERT(ierr == 0, "MPI_Info_create(info)")
      infoF = MPI_INFO_NULL
      call MPI_Info_create(infoF, ierr)
      ASSERT(ierr == 0, "MPI_Info_create(infoF)")

      if (UseT3PIO) then
         call t3pio_set_info(MPI_COMM_WORLD, info, "./", ierr,     &
                             global_size          = iTotalSz,      &
                             stripe_count         = Stripes,       &
                             stripe_size_mb       = StripeSz,      &
                             max_aggregators      = MaxWriters,    &
                             results              = results )
         nIOUnits    = results % numIO
         nStripes    = results % numStripes
         stripeSize  = results % stripeSize
         s_dne       = results % s_dne
         s_auto_max  = results % s_auto_max
         nStripesT3  = results % nStripesT3
      endif

      !
      ! (1) Initialize FORTRAN predefined datatypes

      call H5open_f(ierr)
      ASSERT(ierr == 0, "H5Open_f")

      !
      ! (2) Setup file access property list w/ parallel I/O access.

      call H5Pcreate_f(H5P_FILE_ACCESS_F,plist_id,ierr)
      ASSERT(ierr == 0, "H5Pcreate_f")
      call H5Pset_fapl_mpio_f(plist_id, p % comm, info, ierr);
      ASSERT(ierr == 0, "H5Pset_fapl_mpio_f")

      !
      ! (3.0) Create the file collectively
      t0 = walltime()
      call H5Fcreate_f(fn, H5F_ACC_TRUNC_F, file_id, ierr, access_prp = plist_id)
      ASSERT(ierr == 0, "H5fcreate_f")

      call numagg(file_id, aggregators)
      call H5Pclose_f(plist_id, ierr)
      ASSERT(ierr == 0, "H5Pclose_f")


      ! (3.1) Create group
      call H5Gcreate_f(file_id,"Solution", group_id, ierr)
      ASSERT(ierr == 0, "H5Gopen_f")

      ! For timing tests do not run.
      !call add_solution_description(group_id)

      do i = 1, Numvar

         !
         ! (4) Create the data space for the dataset: filespace, memspace
         call H5Screate_simple_f(ndim, gsz, filespace, ierr)
         ASSERT(ierr == 0, "H5Screate_simple_f")
         !
         ! Each process defines dataset in memory and writes it to the hyperslab
         ! in the file.
         call H5Screate_simple_f(ndim, sz, memspace, ierr)
         ASSERT(ierr == 0, "H5Screate_simple_f")

         if (H5chunk) then
            !
            ! (5) Create chunked dataset.

            call H5Pcreate_f(H5P_DATASET_CREATE_F, plist_id, ierr)
            ASSERT(ierr == 0, "H5Pcreate_f")
            call H5Pset_chunk_f(plist_id, ndim, sz, ierr)
            ASSERT(ierr == 0, "H5Pset_chunk_f")

            call H5Dcreate_f(group_id, varT(i) % name, H5T_NATIVE_DOUBLE, filespace, &
                 dset_id, ierr, plist_id)
            ASSERT(ierr == 0, "H5Dcreate_f")
            call H5Sclose_f(filespace, ierr)
            ASSERT(ierr == 0, "H5Sclose_f")

            !
            ! (6) Select hyperslab in the file.
            call H5Dget_space_f(dset_id, filespace, ierr)
            ASSERT(ierr == 0, "H5Dget_space_f")
            call H5Sselect_hyperslab_f(filespace, H5S_SELECT_SET_F, starts, count, ierr, &
                                       h5stride, sz)
            ASSERT(ierr == 0, "H5Sselect_hyperslab_f")

         else if (H5slab) then
            !
            ! (5) Create the dataset with default properties.
            !
            CALL H5Dcreate_f(group_id, varT(i) % name, H5T_NATIVE_DOUBLE, filespace, &
                 dset_id, ierr)
            ASSERT(ierr == 0, "H5Dcreate_f")
            CALL H5Sclose_f(filespace, ierr)
            ASSERT(ierr == 0, "H5Sclose_f")
            !
            !
            ! (6) Select hyperslab in the file.
            !
            CALL H5Dget_space_f(dset_id, filespace, ierr)
            CALL H5Sselect_hyperslab_f (filespace, H5S_SELECT_SET_F, starts, sz, ierr)
         end if


         !
         ! (7a) Create property list for collective dataset write
         call H5Pcreate_f(H5P_DATASET_XFER_F, plist_id, ierr)
         ASSERT(ierr == 0, "H5Pcreate_f")
         call H5Pset_dxpl_mpio_f(plist_id, xfer_mode, ierr)
         ASSERT(ierr == 0, "H5Pset_dxpl_mpio_f")

         !
         ! (7b) Add attribute
         ! call add_attribute(dset_id, varT(i) % descript)


         !
         ! (8) Write the dataset collectively.


         call H5Dwrite_f(dset_id, H5T_NATIVE_DOUBLE, u, gsz, ierr, &
              file_space_id = filespace, mem_space_id = memspace, xfer_prp = plist_id)
         ASSERT(ierr == 0, "H5Dwrite_f")

         !
         ! (9) Close dataspaces.
         !
         call H5Sclose_f(filespace, ierr); ASSERT(ierr == 0,"H5Sclose_f")
         call H5Sclose_f(memspace, ierr); ASSERT(ierr == 0,"H5Sclose_f")

         !
         ! (10) Close the dataset and property list.
         !
         call H5Dclose_f(dset_id, ierr); ASSERT(ierr == 0,"H5Dclose_f")
         call H5Pclose_f(plist_id, ierr); ASSERT(ierr == 0,"H5Pclose_f")
      end do

      !
      ! (12) Close the group and file.
      !
      call H5Gclose_f(group_id, ierr); ASSERT(ierr == 0,"H5Gclose_f")
      call H5Fclose_f(file_id,  ierr); ASSERT(ierr == 0,"H5Fclose_f")

      !
      ! (12) Close FORTRAN predefined datatypes.
      !
      call H5Close_f(ierr); ASSERT(ierr == 0,"H5Close_f")


      totalTime = walltime() - t0
      rate = totalSz /(totalTime * 1024.0 * 1024.0)

      deallocate(u)
      ! call MPI_Info_free(info, ierr)
      ! ASSERT(ierr == 0, "MPI_Info_free(info)")
      ! call MPI_Info_free(infoF, ierr)
      ! ASSERT(ierr == 0, "MPI_Info_free(infoF)")
#     endif
   end subroutine h5_writer


   subroutine parallel_writer(local, global)
      implicit none

      type(grid_t)          :: local, global
      real(8), allocatable  :: u(:)
      integer               :: info,  i, ierr, infoF
      integer(8)            :: offset

      real(8)               :: walltime

      integer               :: sz(3),gsz(3), starts(3), iTotalSz
      integer               :: status(MPI_STATUS_SIZE), filehandle
      integer               :: coreData, gblData
      type(T3PIO_results_t) :: results

      fn = FILE_NAME // ".mpiio"

      if ( p % myProc == 0) then
         call MPI_File_delete(fn, MPI_INFO_NULL, ierr)
      end if
      call MPI_Barrier(p % comm,ierr)
      
      if ( DebugFlg and p % myProc == 0 ) print *, "Starting Parallel Write"

      lSz  = 1
      do i = 1, local % nd
         sz(i)     = local % num(i)
         lSz       = lSz * local % num(i)
         starts(i) = 0
      end do

      totalSz = 8.0
      do i = 1, nDim
         totalSz = totalSz * DBLE(global % num(i))
      end do

      allocate (u(lSz))
      call init3d(local, u)

      call MPI_Type_create_subarray(nDim , sz, sz, starts, MPI_ORDER_FORTRAN,   &
                                    MPI_DOUBLE_PRECISION, coreData, ierr)
      ASSERT(ierr == 0, "MPI_Type_create_subarray")
      call MPI_Type_commit(coreData, ierr)
      ASSERT(ierr == 0, "MPI_Type_commit")

      do i = 1, global % nd
         gsz(i)    = global % num(i);
         starts(i) = local % is(i) - 1
      end do


      call MPI_Type_create_subarray(nDim, gsz, sz, starts, MPI_ORDER_FORTRAN,  &
                                    MPI_DOUBLE_PRECISION, gblData, ierr)
      ASSERT(ierr == 0, "MPI_Type_create_subarray")
      call MPI_Type_commit(gblData, ierr)
      ASSERT(ierr == 0, "MPI_Type_commit")

      call MPI_Info_create(info,ierr)
      ASSERT(ierr == 0, "MPI_Info_create")

      call MPI_Info_create(infoF,ierr)
      ASSERT(ierr == 0, "MPI_Info_create")

      iTotalSz = totalSz / (1024*1024)
      if (UseT3PIO) then
         call t3pio_set_info(MPI_COMM_WORLD, info, "./", ierr,     &
                             global_size          = iTotalSz,      &
                             max_aggregators      = MaxWriters,    &
                             stripe_size_mb       = StripeSz,      &
                             stripe_count         = Stripes,       &
                             results              = results )

         nIOUnits    = results % numIO
         s_dne       = results % s_dne
         s_auto_max  = results % s_auto_max
         nStripesT3  = results % nStripesT3
      endif

      if ( DebugFlg and p % myProc == 0 ) print *, "Finished T3Pio Call"

      t0 = walltime()

      call MPI_File_open(p % comm, fn, MPI_MODE_CREATE+MPI_MODE_RDWR, info, filehandle, ierr)
      ASSERT(ierr == 0, "MPI_File_open")

      call MPI_File_get_info(filehandle, infoF, ierr)
      ASSERT(ierr == 0, "MPI_File_get_info")

      call t3pio_extract_key_values(infoF, results)

      aggregators = results % numIO
      nStripes    = results % numStripes
      stripeSize  = results % stripeSize
      
      offset = 0
      call MPI_File_set_view(filehandle, offset, MPI_DOUBLE_PRECISION, gblData, "native", info, ierr)
      ASSERT(ierr == 0, "MPI_File_set_view")

      lSz = local % num(1) * local % num(2) * local % num(3)

      
      if ( DebugFlg and p % myProc == 0 ) print *, "Before MPI_File_write_all"
      call MPI_File_write_all(filehandle, u, 1, coreData, status, ierr)
      ASSERT(ierr == 0, "MPI_File_write_all")
      if ( DebugFlg and p % myProc == 0 ) print *, "After MPI_File_write_all"

      call MPI_File_close(filehandle,ierr)
      ASSERT(ierr == 0, "MPI_File_close")

      if ( DebugFlg and p % myProc == 0 ) print *, "After File close"
      totalTime = walltime() - t0

      rate = totalSz /(totalTime * 1024.0 * 1024.0)
      deallocate(u)

      ! call MPI_Info_free(info, ierr)
      ! ASSERT(ierr == 0, "MPI_Info_free(info)")
      ! call MPI_Info_free(infoF, ierr)
      ! ASSERT(ierr == 0, "MPI_Info_free(infoF)")

   end subroutine parallel_writer

   subroutine init3d(local, u)
      implicit none
      type(grid_t) local
      integer :: kk, k, jj, j, ii, i, ja
      real(8) :: u(local % num(1)* local % num(2) * local % num(3))
      real(8) :: rval

      ja = 0
      kk = local % is(3) - 1
      do k = 1, local % num(3)
         kk = kk + 1
         jj = local % is(2) - 1
         do j = 1, local % num(2)
            jj = jj + 1
            ii = local % is(1) - 1
            do i = 1, local % num(1)
               call random_number(rval)
               ii = ii + 1
               ja = ja + 1
               u(ja) = dble(kk*10000 + jj*100 + ii)+rval
            end do
         end do
      end do

   end subroutine init3d

#ifdef USE_HDF5
   subroutine add_attribute(dset_id, descript)
      implicit none
      integer(hid_t)   :: dset_id     ! Group     identifier
      integer(hid_t)   :: attr_id, aspace_id, atype_id ! Attribute foo
      integer(SIZE_t)  :: attrlen
      integer          :: ierr, i
      character(*)     :: descript
      character(40)    :: attr

      integer(HSIZE_t) :: num(1)

      attrlen = 40
      num(1)  = 1
      attr    = descript

      call H5Tcopy_f(H5T_NATIVE_CHARACTER, atype_id, ierr)
      ASSERT(ierr == 0, "H5Tcopy_f")
      call H5Tset_size_f(atype_id, attrlen, ierr)
      ASSERT(ierr == 0, "H5Tset_size_f")

      call H5Screate_simple_f(1, num, aspace_id, ierr)
      ASSERT(ierr == 0, "H5Screate_simple_f")

      call H5Acreate_f(dset_id, "variable descript", atype_id, aspace_id, attr_id, ierr)
      ASSERT(ierr == 0, "H5Acreate_f")

      call H5Awrite_f(attr_id, atype_id, attr, num, ierr)
      ASSERT(ierr == 0, "H5Awrite_f")

      call H5Aclose_f(attr_id,ierr)
      ASSERT(ierr == 0, "H5Aclose_f")
      call H5Sclose_f(aspace_id,ierr)
      ASSERT(ierr == 0, "H5Sclose_f")
   end subroutine add_attribute

   subroutine add_solution_description(id)
      implicit none
      integer (hid_t)  :: id
      integer(hid_t)   :: attr_id, aspace_id, atype_id ! Attribute foo
      integer(SIZE_t)  :: attrlen
      integer          :: ierr, i, n
      integer(HSIZE_t) :: num(1)

      n = size(msg)
      do i = 1,n
         if (msg(i) == " ") then
            n = i
            exit
         end if
      end do

      attrlen = len(msg(1))

      call dateZ(msg(n)) ! overwrite line with time in Zulu.
      n = n + 1
      call dateL(msg(n)) ! overwrite last line with local time.

      call H5Tcopy_f(H5T_NATIVE_CHARACTER, atype_id, ierr)
      ASSERT(ierr == 0, "H5Tcopy_f")
      call H5Tset_size_f(atype_id, attrlen, ierr)
      ASSERT(ierr == 0, "H5Tset_size_f")

      num(1) = n
      call H5Screate_simple_f(1, num, aspace_id, ierr)
      ASSERT(ierr == 0, "H5Screate_simple_f")

      call H5Acreate_f(id, "Description", atype_id, aspace_id, attr_id, ierr)
      ASSERT(ierr == 0, "H5Acreate_f")

      call H5Awrite_f(attr_id, atype_id, msg, num, ierr)
      ASSERT(ierr == 0, "H5Awrite_f")

      call H5Aclose_f(attr_id,ierr)
      ASSERT(ierr == 0, "H5Aclose_f")
      call H5Sclose_f(aspace_id,ierr)
      ASSERT(ierr == 0, "H5Sclose_f")

   end subroutine add_solution_description
#endif

end module writer
