! -*- f90 -*-

module cmdline
   use parallel
   implicit none
   integer :: Stripes       ! number of possible stripes
   integer :: Factor        ! number of stripes per writer
   integer :: nDim          ! number of dimension (2, 3)
   integer :: LocalSz       ! local size
   integer :: GblSz         ! Global size
   integer :: Numvar        ! number of variables
   logical :: VersionFlag   ! if true then report version and quit.
   logical :: HelpFlag      ! if true then print usage and quit
   logical :: HDF5Flag      ! if true then use HDF5 instead of MPI I/O
   logical :: H5chunk       ! if true then use HDF5 w/ chunks
   logical :: H5slab        ! if true then use HDF5 w/ slabs
   logical :: ROMIO         ! if true then use MPI I/O



contains

   subroutine parse()

   integer        :: count, i, iargc
   character(160) :: arg

   count = iargc()

   Numvar      = 4
   Stripes     = 0
   nDim        = 2
   Factor      = 4
   LocalSz     = 5
   GblSz       = 0
   VersionFlag = .false.
   HelpFlag    = .false.
   ROMIO       = .true.
   HDF5Flag    = .false.

#ifdef USE_HDF5
   ROMIO       = .false.
   H5chunk     = .false.
   H5slab      = .true.
   HDF5Flag    = .true.
#endif

   i = 0
   do
      i = i + 1
      if (i > count) exit
      call getarg(i,arg)

      if (arg == "-f" .or. arg == "--factor") then
         i = i + 1
         call getarg(i,arg)
         read(arg,*) factor
      elseif (arg == "-g" .or. arg == "--global") then
         i = i + 1
         call getarg(i,arg)
         read(arg,*) GblSz
      elseif (arg == "-l" .or. arg == "--local") then
         i = i + 1
         call getarg(i,arg)
         read(arg,*) LocalSz
      elseif (arg == "-n" .or. arg == "--dim") then
         i = i + 1
         call getarg(i,arg)
         read(arg,*) nDim
      elseif (arg == "--numvar") then
         i = i + 1
         call getarg(i,arg)
         read(arg,*) Numvar
      elseif (arg == "--stripes") then
         i = i + 1
         call getarg(i,arg)
         read(arg,*) Stripes
      elseif (arg(1:2) == '-v' .or. arg == '--version') then
         VersionFlag = .TRUE.
      elseif (arg == '--romio') then
         ROMIO    = .true.
         HDF5Flag = .false.
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

end subroutine parse

   subroutine usage()
      implicit none

      if (p % myproc > 0) return

      print *, "Usage: mpiio [options]"
      print *, "options:"
      print *, "  -v            : version"
      print *, "  -H            : This message and quit"
      print *, "  --help         : This message and quit"
      print *, "  --dim num     : number of dimension (2, or 3)"
      print *, "  -g num        : number of points in each direction globally"
      print *, "  -l num        : number of points in each direction locally"
      print *, "  -f num        : number of stripes per writer (4 default)"
      print *, "  --stripes num : Allow no more than num stripes "
      print *, "                  (file system limit by default)"
      print *, "  --h5chunk     : use HDF5 with chunks"
      print *, "  --h5slab      : use HDF5 with slab"
      print *, "  --romio       : use MPI I/O"
      print *, "  --numvar num  : number of variables 1 to 9"
      print *, " "
      print *, " Defaults are:"
      print *, "    Dim is 2"
      print *, "    l   is 5"
      print *, "    f   is 4"
      print *, "    Use HDF5 hyperslab"
      print *, "    numvar is 4"
      print *, " "

   end subroutine usage

end module cmdline

