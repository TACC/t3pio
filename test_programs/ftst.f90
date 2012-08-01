program ftst
   use t3pio
   use mpi
   implicit none 
   
   character(256) :: key, value
   integer        :: ierr, myProc, nProcs, gblSz, nkeys
   integer        :: info, valuelen,i
   logical        :: flag

   call MPI_init(ierr)

  
   call MPI_Comm_rank(MPI_COMM_WORLD, myProc, ierr)
   call MPI_Comm_size(MPI_COMM_WORLD, nProcs,  ierr)

   call MPI_Info_create(info, ierr)

   gblSz = 789 ! in MB
   

   call t3pio_set_info(MPI_COMM_WORLD, info, "./", ierr,   &
                       global_size=gblSz)
   

   if (myProc == 0) then
      call MPI_Info_get_nkeys(info, nkeys, ierr)

      do i = 0, nkeys - 1
         call MPI_Info_get_nthkey(info, i, key, ierr)
         call MPI_Info_get_valuelen(info, key, valuelen, flag, ierr)
         call MPI_Info_get(info, key, valuelen+1, value, flag, ierr)

         write(*,'(''Key: '',a,'' value: '', a)') trim(key), trim(value)
      end do

   end if

   call MPI_Finalize(ierr);

end program ftst
