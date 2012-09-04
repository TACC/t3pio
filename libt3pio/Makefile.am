lib_LTLIBRARIES = libt3pio.la
libt3pio_la_SOURCES = set_info.c pfs.c f2c_internal.c t3pio.f90
libt3pio_la_CPPFLAGS = -I$(top_srcdir)/include

moduledir   = @prefix@/include
module_DATA = t3pio.mod

CLEANFILES = *.mod Makefile.dep1 Makefile.dep2 Makefile.dep3 Makefile.dep

.f90.lo:
	module=$(*F)                                            ;\
	MODULE=$$(echo $$module | tr '[:lower:]' '[:upper:]' )  ;\
	$(LTFCCOMPILE) -c -o $@ $(FCFLAGS_f90) $<               ;\
	if [ -f $$MODULE.mod ]; then cp $$MODULE.mod $$module.mod; fi
