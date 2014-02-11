CC_VERSION_FLAG := @CC_VERSION_FLAG@
VDATE           := $(shell date +'%F %H:%M')
GIT_PROG        := @PATH_TO_GIT@
GIT_VERSION     := $(shell if [ -n "$(GIT_PROG)" -a -d ../.git ]; then prgV=`git describe --always`; echo "$$prgV"; else echo "@git@"; fi)

lib_LTLIBRARIES = libt3pio.la
libt3pio_la_SOURCES = set_info.c pfs.c f2c_internal.c t3pio.f90 qa.c
libt3pio_la_CPPFLAGS = -I$(top_srcdir)/include
BUILT_SOURCES = qaversion.h
moduledir   = @prefix@/include
module_DATA = t3pio.mod

CLEANFILES = *.mod Makefile.dep1 Makefile.dep2 Makefile.dep3 Makefile.dep qaversion.h

.f90.lo:
	module=$(*F)                                            ;\
	MODULE=$$(echo $$module | tr '[:lower:]' '[:upper:]' )  ;\
	$(LTFCCOMPILE) -c -o $@ $(FCFLAGS_f90) $<               ;\
	if [ -f $$MODULE.mod ]; then cp $$MODULE.mod $$module.mod; fi

.PHONY: qaversion.h
qaversion.h:
	if [ "x$(CC_VERSION_FLAG)" != xNONE ]; then                  	 	 \
          $(CC) $(CC_VERSION_FLAG) > conftmp.0 2>&1;                	 	 \
          sed -e '/^ *$$/d' < conftmp.0 > conftmp.1;           	      	 	 \
          sed -n -e 1p < conftmp.1 > conftmp.2;                	      	 	 \
          CC_VERSION_STRING=`cat conftmp.2`;                  	      	 	 \
        else                                                   	      	 	 \
          CC_VERSION_STRING=UNKNOWN;                         	      	 	 \
        fi;                                                    	      	 	 \
	echo '#define COMPILER_NAME "${CC}"'                  	  >  conftmp.0 ; \
	echo '#define COMPILER_VERSION' '"'$$CC_VERSION_STRING'"' >> conftmp.0 ; \
        echo '#define MPI_VERSION_STR'  '"'${MPI_VERSION_STR}'"'  >> conftmp.0 ; \
	echo '#define BUILD_DATE'       '"'$(VDATE)'"'            >> conftmp.0 ; \
        echo '#define T3PIO_GIT_VERSION' '"''$(GIT_VERSION)''"'   >> conftmp.0 ; \
	cat conftmp.0 > $@;                                                      \
	$(RM) conftmp.[012];
