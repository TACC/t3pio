AUTOMAKE_OPTIONS = foreign
SHELL := bash

SUBDIRS = .

all-local: Makefile.dep1 


AM_FCFLAGS = -I ../libt3pio 
AM_CFLAGS  = 
AM_LIBTOOLFLAGS = 

#----------------------------
# cubeTest Binaries
#----------------------------

fc_sources             := master.F90  assert.F90 cmdline.F90 grid.F90 \
                          parallel.F90 writer.F90
c_sources              := measure.c numaggregators.c

cubeTest_SOURCES       := $(fc_sources) $(c_sources)
cubeTest_FFLAGS        := -I$(top_srcdir)/include
cubeTest_CFLAGS        := -I$(top_srcdir)/include
cubeTest_DEPENDENCIES  := ../libt3pio/libt3pio.la
cubeTest_LDADD         := -L../libt3pio -lt3pio
cubeTest_LDFLAGS       := -Wl,-rpath,$(PHDF5_DIR)/lib 

standalonedir               = @prefix@/bin
standalone_PROGRAMS         = cubeTest


if PHDF5_ENABLED
   AM_FCFLAGS       += -DUSE_HDF5  -I $(PHDF5_DIR)/include
   AM_CFLAGS        += -DUSE_HDF5  -I $(PHDF5_DIR)/include
   cubeTest_LDADD   += -L$(PHDF5_DIR)/lib -lhdf5hl_fortran -lhdf5_hl -lhdf5_fortran -lhdf5  -lz -lm
   cubeTest_LDFLAGS += -Wl,-rpath,@prefix@/lib
endif

#IGNORED_MODULES = --ignore mpi --ignore hdf5 --ignore t3pio
IGNORED_MODULES = -i mpi -i hdf5 -i t3pio
PARSE_OPTIONS = -I $(top_srcdir)/include $(IGNORED_MODULES)


Makefile.dep1: $(fc_sources)
	$(top_srcdir)/utils/sfmakedepend.pl $(PARSE_OPTIONS) $^ > $@


-include Makefile.dep1

CLEANFILES = *.mod Makefile.dep1

.F90.o:
	module=$(*F)                                            ;\
	MODULE=$$(echo $$module | tr '[:lower:]' '[:upper:]' )  ;\
	$(PPFCCOMPILE) -c -o $@ $<                              ;\
	if [ -f $$MODULE.mod ]; then cp $$MODULE.mod $$module.mod; fi
