! -*- f90 -*-

module cmdline
   use parallel
   use t3pio
   implicit none
   integer :: Stripes       ! number of possible stripes
   integer :: StripeSz      ! Stripe size in MB.
   integer :: nDim          ! number of dimension (2, 3)
   integer :: LocalSz       ! local size
   integer :: GblSz         ! Global size
   integer :: GblFileSz     ! Global File Size in GB.
   integer :: Numvar        ! number of variables
   integer :: MaxWriters    ! the max number of writers.
   logical :: UseT3PIO      ! if true then use T3PIO (on by default).
   logical :: VersionFlag   ! if true then report version and quit.
   logical :: HelpFlag      ! if true then print usage and quit
   logical :: HDF5Flag      ! if true then use HDF5 instead of MPI I/O
   logical :: H5chunk       ! if true then use HDF5 w/ chunks
   logical :: H5slab        ! if true then use HDF5 w/ slabs
   logical :: Collective    ! if true then use collective,
                            ! otherwise do independent.
   logical :: ROMIO         ! if true then use MPI I/O
   logical :: LuaOutput     ! if true then write output in a Lua
                            ! table format.
   logical :: TableOutput   ! if true then write output in table format.

contains

   subroutine parse()

      integer        :: count, i, iargc, ierr
      character(160) :: arg, optarg
      
      count = iargc()
      
      
      MaxWriters    = T3PIO_UNSET
      Numvar        = 1
      Stripes       = T3PIO_UNSET
      nDim          = 2
      LocalSz       = 5
      GblSz         = 0
      StripeSz      = T3PIO_UNSET
      GblFileSz     = T3PIO_UNSET
      
      Collective    = .true.
      UseT3PIO      = .true.
      VersionFlag   = .false.
      HelpFlag      = .false.
      ROMIO         = .true.
      HDF5Flag      = .false.
      LuaOutput     = .false.
      TableOutput   = .true.
      
#ifdef USE_HDF5
      ROMIO         = .false.
      H5chunk       = .false.
      H5slab        = .true.
      HDF5Flag      = .true.
#endif

      i = 0
      do
         i = i + 1
         if (i > count) exit
         call getarg(i,arg)
         
         if (arg == "-g" .or. arg == "--global") then
            i = i + 1
            call getarg(i,optarg)
            read(optarg,*, err=11) GblSz
         elseif (arg == "-G") then
            i = i + 1
            call getarg(i,optarg)
            read(optarg,*, err=11) GblFileSz
         elseif (arg == "-l" .or. arg == "--local") then
            i = i + 1
            call getarg(i,optarg)
            read(optarg,*, err=11) LocalSz
         elseif (arg == "-n" .or. arg == "--dim") then
            i = i + 1
            call getarg(i,optarg)
            read(optarg,*, err=11) nDim
         elseif (arg == "--lua") then
            LuaOutput   = .true.
            TableOutput = .false.
         elseif (arg == "--all" .or. arg == "--both" ) then
            LuaOutput   = .true.
            TableOutput = .true.
         elseif (arg == "--independent") then
            Collective  = .false.
         elseif (arg == "--mwriters") then
            i = i + 1
            call getarg(i,optarg)
            read(optarg,*, err=11) MaxWriters
         elseif (arg == "--numvar") then
            i = i + 1
            call getarg(i,optarg)
            read(optarg,*, err=11) Numvar
         elseif (arg == "--stripes" .or. arg == "--nstripes") then
            i = i + 1
            call getarg(i,optarg)
            read(optarg,*, err=11) Stripes
         elseif (arg == "--stripeSz") then
            i = i + 1
            call getarg(i,optarg)
            read(optarg,*, err=11) StripeSz
         elseif (arg(1:2) == '-v' .or. arg == '--version') then
            VersionFlag = .TRUE.
         elseif (arg == '--romio') then
            ROMIO    = .true.
            HDF5Flag = .false.
         elseif (arg == '--noT3PIO') then
            UseT3PIO = .false.
         elseif (arg == '--h5chunk') then
            ROMIO    = .false.
            HDF5Flag = .true.
            H5chunk  = .true.
            H5slab   = .false.
         elseif (arg == '--h5slab') then
            ROMIO    = .false.
            HDF5Flag = .true.
            H5chunk  = .false.
            H5slab   = .true.
         else if (arg(1:2) == '-H' .or. arg(1:2) == '-h' .or. &
              arg == '--help') then
            HelpFlag = .true.
         end if
      end do
      
      Numvar = max(1,Numvar)
      Numvar = min(9,Numvar)
      
      if (ROMIO) Numvar = 1
      
      return
11    continue
      if (p % myProc == 0) then
         print *, "Illegal argument for option: ", trim(arg)
         print *, "Terminating."
      end if
      call MPI_Finalize(ierr)
      call exit()
   end subroutine parse

   subroutine usage()
      implicit none
      character(10) :: romioDft, h5slabDft

      
      if (ROMIO) then
         h5slabDft = ''
         romioDft  = ' (default)'
      else
         h5slabDft = ' (default)'
         romioDft  = ''
      endif


      if (p % myproc > 0) return


      print *, "Usage: cubeTestHDF5 [options]"
      print *, "options:"
      print *, "  -v                : version"
      print *, "  -H                : This message and quit"
      print *, "  --help            : This message and quit"
      print *, "  --dim num         : number of dimension (2, or 3)"
      print *, "  -g num            : number of points in each direction globally"
      print *, "                      (no default)"
      print *, "  -l num            : number of points in each direction locally"
      print *, "                      (default = 5)"
      print *, "  -G num            : Total File size in GB"
      print *, "  --both            : Report results in both a lua table and regular table"
      print *, "  --noT3PIO         : turn off t3pio"
      print *, "  --nstripes num    : Allow no more than num stripes "
      print *, "                      (file system limit by default)"
      print *, "  --stripeSz num    : Stripe Size in MB (1 to 256)"
      print *, "  --h5chunk         : use HDF5 with chunks",h5slabDft
      print *, "  --romio           : use MPI I/O",romioDft
      print *, "  --h5slab          : use HDF5 with slab"
      print *, "  --independent     : Use independent writes instead of collective"
      print *, "  --numvar num      : number of variables 1 to 9"
      print *, "  --mwriters    num : Total number of writers"
      print *, " "
      print *, " Defaults are:"
      print *, "    Dim is 2"
      print *, "    l   is 5"
      print *, "    Use HDF5 hyperslab"
      print *, "    numvar is 1"
      print *, " "

   end subroutine usage

end module cmdline

