dnl ######################################################################
dnl $Id: configure.ac,v 1.3 2004-01-21 22:13:29 mclay Exp $
dnl ######################################################################
dnl Process this file with autoconf to produce a configure script.
dnl This is for MGF
AC_PREREQ([2.69])
AC_INIT([t3pio],[2.4],[mclay@tacc.utexas.edu])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADER(config.h)
AC_CONFIG_AUX_DIR([build-aux])

AM_CONDITIONAL(SHARED_LIBRARIES, test x$enable_shared != xno )

AC_SUBST(PATH_TO_GIT)
AC_PATH_PROG(PATH_TO_GIT, git, "")
AM_INIT_AUTOMAKE
AC_PROG_CC
AC_PROG_CXX
AC_PROG_FC
AC_PROG_F77
AC_F77_WRAPPERS
AC_PROG_LIBTOOL
AC_FC_SRCEXT(f90)
AC_LANG(Fortran)
AC_LANG(C)
AX_COMPILER_VENDOR
if test "x${ax_cv_compiler_vendor}" = "xintel" ; then
   echo Compiler vendor... : $ax_cv_compiler_vendor
fi

PP_CC_VERSION_OPTION
AC_HEADER_STDC
AC_CHECK_HEADERS(lustre/lustreapi.h)
AC_CHECK_LIB(lustre,llapi_file_create)
AC_CHECK_LIB(lustreapi,llapi_file_create)

AC_ARG_WITH(phdf5, [ --with-phdf5            use Parallel HDF5 with test programs],
            with_phdf5=$withval, with_phdf5=no)
USE_PHDF5=0
if test x$with_phdf5 != xno; then
   USE_PHDF5=1
   PHDF5_DIR=$with_phdf5
fi
AC_SUBST(PHDF5_DIR)

#Constants used here:
Max_Stripes_Small=160
Max_Stripes_Big=2000
GOOD_CITZENSHIP=80
#End Constants used here:

MAX_STRIPES_POSSIBLE=$Max_Stripes_Small
# find lustre version
LUSTRE_VERSION=0.0.0
if test -f /proc/fs/lustre/version; then
  V=$(cat  /proc/fs/lustre/version | grep 'lustre:')
  V=$(expr "$V" : 'lustre: *\(.*\)')
  LUSTRE_VERSION=$V

  a=$(expr "$V" : '\(@<:@^.@:>@*\)\..*')
  r=$(expr "$V" : '@<:@^.@:>@*\.\(.*\)')
  b=$(expr "$r" : '\(@<:@^.@:>@*\)\..*')
  c=$(expr "$r" : '@<:@^.@:>@*\.\(.*\)')

  if test -z "$b" ; then
     b=$r
  fi

  if test -z "$c"; then
    c=0
  fi

  V=$( expr $a \* 1000000 + $b \* 1000 + $c )

  if test "$V" -ge 2004000; then
    MAX_STRIPES_POSSIBLE=$Max_Stripes_Big
  fi
fi
AC_DEFINE(LUSTRE_VERSION, $LUSTRE_VERSION)

AC_DEFINE(LUSTRE_MAX_STRIPES_PER_FILE, $MAX_STRIPES_POSSIBLE, [Max stripes possible with lustre])
AC_ARG_WITH(lustreMaxStripesPerFile,
    AC_HELP_STRING([--with-lustreMaxStripesPerFile=ans],[Max stripes possible with lustre, Lustre 2.1 ==> 160, Lustre 2.4 ==> 2000 [[160]]]),
    LUSTRE_MAX_STRIPES_PER_FILE="$withval"
    AC_MSG_RESULT([LUSTRE_MAX_STRIPES_PER_FILE=$with_lustreMaxStripesPerFile])
    AC_DEFINE_UNQUOTED(LUSTRE_MAX_STRIPES_PER_FILE,$with_lustreMaxStripesPerFile)dnl
    ,
    withval="$MAX_STRIPES_POSSIBLE"
    AC_MSG_RESULT([LUSTRE_MAX_STRIPES_PER_FILE=$withval])
    LUSTRE_MAX_STRIPES_PER_FILE="$withval"
    AC_DEFINE_UNQUOTED(LUSTRE_MAX_STRIPES_PER_FILE, $withval))dnl


AC_DEFINE(GOOD_CITZENSHIP_STRIPES, $GOOD_CITZENSHIP, [Max number of stripes in T3PIO automatic mode])
AC_ARG_WITH(goodCitzenshipStripes,
    AC_HELP_STRING([--with-goodCitzenshipStripes=ans],[Max number of stripes in automatic mode [[80]]]),
    GOOD_CITZENSHIP_STRIPES="$withval"
    AC_MSG_RESULT([GOOD_CITZENSHIP_STRIPES=$with_goodCitzenshipStripes])
    AC_DEFINE_UNQUOTED(GOOD_CITZENSHIP_STRIPES,$with_goodCitzenshipStripes)dnl
    ,
    withval="$GOOD_CITZENSHIP"
    AC_MSG_RESULT([GOOD_CITZENSHIP_STRIPES=$withval])
    GOOD_CITZENSHIP_STRIPES="$withval"
    AC_DEFINE_UNQUOTED(GOOD_CITZENSHIP_STRIPES, $withval))dnl

AC_DEFINE(MAX_STRIPES_PER_NODE, 4, [Max number of stripes for a single node])
AC_ARG_WITH(maxStripesPerNode,
    AC_HELP_STRING([--with-maxStripesPerNode=ans],[Max number of stripes for a single node [[4]]]),
    MAX_STRIPES_PER_NODE="$withval"
    AC_MSG_RESULT([MAX_STRIPES_PER_NODE=$with_maxStripesPerNode])
    AC_DEFINE_UNQUOTED(MAX_STRIPES_PER_NODE,$with_maxStripesPerNode)dnl
    ,
    withval="4"
    AC_MSG_RESULT([MAX_STRIPES_PER_NODE=$withval])
    MAX_STRIPES_PER_NODE="$withval"
    AC_DEFINE_UNQUOTED(MAX_STRIPES_PER_NODE, $withval))dnl

AC_ARG_WITH(lustre, [ --with-lustre      lustre filesystem string: /scratch:90:/work:30:],
with_lustre=$withval, with_lustre=no)
if test x$with_lustre != xno; then
   AX_LUSTRE_FS=$with_lustre
   AC_DEFINE_UNQUOTED([AX_LUSTRE_FS], "$with_lustre", [A colon string of file system names and OSTs])
else
  AX_HOW_MANY_OSTs
fi

AM_MAINTAINER_MODE([disable])
AM_CONDITIONAL(PHDF5_ENABLED, test x$USE_PHDF5 = x1)


AC_OUTPUT([Makefile
           libt3pio/Makefile
           include/Makefile
	   cubeTest/Makefile
           unstructTest/Makefile])

AX_SUMMARIZE_ENV
AX_SUMMARIZE_CONFIG


rm -f conftest*
