.SUFFIXES:
.SUFFIXES:

SRCDIR := $(CURDIR)/

ifneq ($(TARG),)
  override TARG  := $(TARG)/
  override TARG  := $(subst //,/,$(TARG))
  override O_DIR := $(TARG)
else
  TARG  := OBJ/
  O_DIR := OBJ/
endif

MYMAKE.targ = +@[ -f $(TARG)build.mk ] || F77=mpif90 CC=mpicc ./configure  ; \
	    MyMakeCmd="$(MAKE) -C $(TARG) -f build.mk -I $(SRCDIR) TOPDIR=$(SRCDIR) O_DIR=$(SRCDIR)$(O_DIR)" ; \
            echo $$MyMakeCmd $@; \
            $$MyMakeCmd

all::

%:
	$(MYMAKE.targ) $@

