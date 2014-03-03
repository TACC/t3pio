AUTOMAKE_OPTIONS = foreign

SUBDIRS = .

CXXFLAGS += -I$(top_srcdir)/libt3pio 

unstructTest_SOURCES        = main.C comm.C cmdLineOptions.C parallel_io.C measure.C
unstructTest_CXXFLAGS       = -I$(top_srcdir)/include
unstructTest_DEPENDENCIES  := ../libt3pio/libt3pio.la
unstructTest_LDADD          = -L../libt3pio -lt3pio

standalonedir               = @prefix@/bin
standalone_PROGRAMS         = unstructTest

if PHDF5_ENABLED
   CXXFLAGS                 += -DUSE_HDF5  -I$(PHDF5_DIR)/include
   unstructTest_LDADD   += -L$(PHDF5_DIR)/lib -lhdf5_hl -lhdf5  -lz 
if SHARED_LIBRARIES	
   unstructTest_LDFLAGS  = -Wl,-rpath,$(PHDF5_DIR)/lib -Wl,-rpath,@prefix@/lib
endif
endif


