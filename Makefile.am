SUBDIRS = include libt3pio cubeTest unstructTest
ACLOCAL_AMFLAGS = -I m4
VERSION_SRC = .version
SHELL := bash


world_update:
	@git status -s > /tmp/rtm$$$$;                                             \
        if [ -s /tmp/rtm$$$$ ]; then                                               \
            echo "All files not checked in => try again";                          \
        else                                                                       \
            git push origin;                                                       \
            git push --tags origin;                                                \
            git push github;                                                       \
            git push --tags github;                                                \
        fi;                                                                        \
        rm -f /tmp/rtm$$$$

gittag:
        ifneq ($(TAG),)
	  @git status -s > /tmp/t3pio$$$$;                                             \
          if [ -s /tmp/t3pio$$$$ ]; then                                               \
	    echo "All files not checked in => try again";                              \
	  else                                                                         \
	    $(RM)                                                      $(VERSION_SRC); \
	    echo $(TAG)                                             >  $(VERSION_SRC); \
	    perl -p -i -e 's/AC_INIT\(\[t3pio\],\[[^,]+,/AC_INIT([t3pio],[$(TAG)],/' configure.ac; \
            autoreconf;                                                                \
            git commit -am "moving to TAG_VERSION $(TAG)"                            ; \
            git tag -a $(TAG) -m 'Setting TAG_VERSION to $(TAG)'                     ; \
	    git push --tags                                                          ; \
          fi;                                                                          \
          rm -f /tmp/t3pio$$$$
        else
	  @echo "To git tag do: make gittag TAG=?"
        endif

t3pio-dist:  
	git archive --prefix=t3pio-`cat .version`/ master | bzip2 > t3pio-`cat .version`.tar.bz2

echoMe:
	@echo AX_LUSTRE_FS: @AX_LUSTRE_FS@

tags:
	find . \( -regex '.*~$$\|.*/\.git\|.*/\.git/' -prune \)  \
               -o -type f > file_list.1
	sed -e 's|.*/.git.*||g'                                  \
            -e 's|.*/TAGS||g'                                    \
            -e 's|.*/a.out||g'                                   \
            -e 's|.*/makefile||g'                                \
            -e 's|.*/Makefile||g'                                \
            -e 's|.*/Makefile.in||g'                             \
            -e 's|.*/configure$$||g'                             \
            -e 's|.*/.DS_Store$$||g'                             \
            -e 's|.*\.tgz$$||g'                                  \
            -e 's|.*\.tar\.gz$$||g'                              \
            -e 's|.*\.tar\.bz2$$||g'                             \
            -e 's|.*/?^#.*||g'                                   \
            -e 's|.*/?#.*||g'                                    \
            -e 's|.*/?\.#.*||g'                                  \
            -e 's|./.*\.log$$||g'                                \
            -e 's|./testreports/.*||g'                           \
            -e 's|./config\.status$$||g'                         \
            -e 's|.*\~$$||g'                                     \
            -e 's|./file_list\..*||g'                            \
            -e '/^\s*$$/d'                                       \
	       < file_list.1 > file_list.2
	etags  `cat file_list.2`
	$(RM) file_list.*
