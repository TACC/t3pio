AUTOMAKE_OPTIONS = foreign

SUBDIRS = .

CXXFLAGS += -I$(top_srcdir)/libt3pio 

unstructTestHDF5_SOURCES        = main.C parallel.C cmdLineOptions.C h5writer.C measure.C
unstructTestHDF5_CXXFLAGS       = -I$(top_srcdir)/include
unstructTestHDF5_DEPENDENCIES  := ../libt3pio/libt3pio.la
unstructTestHDF5_LDADD          = -L../libt3pio -lt3pio

standalonedir               = @prefix@/bin
standalone_PROGRAMS         = unstructTestHDF5

if PHDF5_ENABLED
   CXXFLAGS                 += -DUSE_HDF5  -I$(PHDF5_DIR)/include
   unstructTestHDF5_LDADD   += -L$(PHDF5_DIR)/lib -lhdf5hl_fortran -lhdf5_hl -lhdf5_fortran -lhdf5  -lz 
if SHARED_LIBRARIES	
   unstructTestHDF5_LDFLAGS  = -Wl,-rpath,$(PHDF5_DIR)/lib -Wl,-rpath,@prefix@/lib
endif
endif


