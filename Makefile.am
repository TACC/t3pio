SUBDIRS = include libt3pio cubeTestHDF5 unstructTestHDF5
ACLOCAL_AMFLAGS = -I m4
VERSION_SRC = .version


gittag:
        ifneq ($(TAG),)
	  @git status -s > /tmp/t3pio$$$$;                                             \
          if [ -s /tmp/t3pio$$$$ ]; then                                               \
	    echo "All files not checked in => try again";                              \
	  else                                                                         \
	    $(RM)                                                      $(VERSION_SRC); \
	    echo $(TAG)                                             >  $(VERSION_SRC); \
	    perl -p -i -e 's/AC_INIT\(\[t3pio\],\[[^,]*,[mclay@tacc\.utexas\.edu]\)/AC_INIT([t3pio],[$(TAG)],[mclay@tacc.utexas.edu])/' configure.ac; \
            autoreconf;                                                                \
            #git commit -m "moving to TAG_VERSION $(TAG)"               $(VERSION_SRC); \
            #git tag -a $(TAG) -m 'Setting TAG_VERSION to $(TAG)'                     ; \
	    #git push --tags                                                          ; \
          fi;                                                                          \
          rm -f /tmp/t3pio$$$$
        else
	  @echo "To git tag do: make gittag TAG=?"
        endif

t3pio-dist:  
	git archive --prefix=t3pio-`cat .version`/ master | bzip2 > t3pio-`cat .version`.tar.bz2

echoMe:
	@echo AX_LUSTRE_FS: @AX_LUSTRE_FS@
