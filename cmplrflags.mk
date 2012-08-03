.SUFFIXES:
.SUFFIXES: .c .d .h .o 

ifeq ($(compiler),)
  ifneq ($(TARG_COMPILER_FAMILY),)
    compiler := $(TARG_COMPILER_FAMILY)
  endif
endif

ifeq ($(METHOD),)
  ifneq ($(TARG_METHOD),)
    METHOD := $(TARG_METHOD)
  endif
endif

DEPENDENCY_FLAG   := -MM
RANLIB := ranlib
########################################################################
OPTNAME := opt
ifneq (,$(findstring x86_64-linux-gnu,$(MACHINE)-$(OS)))

  ifeq ($(compiler),lonestar)
    compiler := intel
  endif

  ifeq ($(compiler),)
    compiler := intel
  endif


  ifeq ($(compiler),intel)
    FC	        := mpif90
    CC          := mpicc
    OPTLVL      := -g -O3 -xHost
    ifeq ($(METHOD),dbg)
      F_OPTLVL  :=
      OPTLVL    := -g -O0 -traceback -DDEBUG
      OPTNAME   := dbg
    endif
    ifeq ($(METHOD),mdbg)
      F_OPTLVL  := -CB -check uninit -fpe0 -check arg_temp_created -check pointers
      OPTLVL    := -g  -O0 -traceback -DDEBUG
      OPTNAME   := mdbg
    endif
    COMMON_FLGS := $(OPTLVL) $(F_OPTLVL) 
    IMODS	:=  -module
  endif


  ifeq ($(compiler),pgi)
    FC	        :=  mpif90
    CC          :=  mpicc
    OPTLVL      := -gopt -tp barcelona-64 -fast
    ifeq ($(METHOD),dbg)
      F_OPTLVL  :=
      OPTLVL    := -g  -O0   -DDEBUG
      OPTNAME   := dbg
    endif
    ifeq ($(METHOD),mdbg)
      F_OPTLVL  :=
      OPTLVL    := -g  -O0  -DDEBUG
      OPTNAME   := mdbg
    endif
    COMMON_FLGS := $(OPTLVL) $(F_OPTLVL)  $(EPPFLAG) -Mfree 
    IMODS	:=  -module
  endif

  ifeq ($(compiler),gcc)
    FC          := mpif90
    CC          := mpicc
    COMMON_FLGS := -g  -O0 $(PRECISION) -ffree-form -DNDEBUG -ffree-line-length-none
  endif	
endif


########################################################################
# Compiler flags for apple
#
ifneq (,$(findstring x86_64-darwin,$(MACHINE)-$(OS)))
  FC          := mpif90
  CC          := mpicc
  OPTLVL      := -O2
  ifeq ($(METHOD),dbg)
    OPTNAME   := dbg
    OPTLVL    := -g  -O0
    F_OPTLVL  :=
  endif
  ifeq ($(METHOD),mdbg)
    OPTNAME   := mdbg
    OPTLVL    := -g  -O0 -fbounds-check
    F_OPTLVL  :=
  endif
  COMMON_FLGS := $(F_OPTLVL) $(OPTLVL) $(EPPFLAG) $(PRECISION) -ffree-form  $(PETSC_FLAGS) -ffree-line-length-none

endif


override FFLAGS := $(FFLAGS) $(COMMON_FLGS) $(FC_FLAGS)
override CFLAGS := $(CFLAGS) $(OPTLVL) -I$(TOPDIR)/src

%.o %.mod : %.f90
	$(COMPILE.F) -I $(O_DIR) -o $(O_DIR)$(*F).o  $<

%.o : %.c
	$(COMPILE.c) -I $(O_DIR) -o $(O_DIR)$(*F).o $<

%.d: %.c
	$(SHELL) -c '$(CC) $(CFLAGS) -I. $(DEPENDENCY_FLAG) $<                     \
        | sed -e '\''s|/[^ ][^ ]*/||g'\''                                          \
              -e '\''s|mpi.h||g'\''                                                \
              -e '\''s|mpio.h||g'\''                                               \
        > $@; [ -s $@ ] || rm -f $@'
