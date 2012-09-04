AUTOMAKE_OPTIONS = foreign

SUBDIRS = .

all-local: Makefile.dep1 


AM_FCFLAGS = -I ../libt3pio 
AM_CFLAGS  = 
AM_LIBTOOLFLAGS = 

#----------------------------
# cubeTestHDF5 Binaries
#----------------------------

fc_sources                 := master.F90  assert.F90 cmdline.F90 grid.F90 parallel.F90 writer.F90
c_sources                  := measure.c

cubeTestHDF5_SOURCES       := $(fc_sources) $(c_sources)
cubeTestHDF5_FFLAGS        := -I$(top_srcdir)/include
cubeTestHDF5_DEPENDENCIES  := ../libt3pio/libt3pio.la
cubeTestHDF5_LDADD         := -L../libt3pio -lt3pio
cubeTestHDF5_LDFLAGS       := -Wl,-rpath,$(PHDF5_DIR)/lib 

standalonedir               = @prefix@/bin
standalone_PROGRAMS         = cubeTestHDF5


if PHDF5_ENABLED
   AM_FCFLAGS           += -DUSE_HDF5  -I $(PHDF5_DIR)/include
   cubeTestHDF5_LDADD   += -L$(PHDF5_DIR)/lib -lhdf5hl_fortran -lhdf5_hl -lhdf5_fortran -lhdf5  -lz -lm
   cubeTestHDF5_LDFLAGS += -Wl,-rpath,@prefix@/lib
endif

#IGNORED_MODULES = --ignore mpi --ignore hdf5 --ignore t3pio
IGNORED_MODULES = -i mpi -i hdf5 -i t3pio
PARSE_OPTIONS = -I $(top_srcdir)/include $(IGNORED_MODULES)


Makefile.dep1: $(fc_sources)
	$(top_srcdir)/utils/sfmakedepend.pl $(PARSE_OPTIONS) $^ > $@


-include Makefile.dep1

CLEANFILES = *.mod Makefile.dep1
