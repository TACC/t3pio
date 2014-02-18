dnl ######################################################################
dnl $Id: configure.ac,v 1.3 2004-01-21 22:13:29 mclay Exp $
dnl ######################################################################
dnl Process this file with autoconf to produce a configure script.
dnl This is for MGF
AC_PREREQ([2.69])
AC_INIT([t3pio],[1.4],[mclay@tacc.utexas.edu])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADER(config.h)
AC_CONFIG_AUX_DIR([build-aux])

AM_CONDITIONAL(SHARED_LIBRARIES, test x$enable_shared != xno )

AC_SUBST(PATH_TO_GIT)
AC_PATH_PROG(PATH_TO_GIT, git, "")
AM_INIT_AUTOMAKE
AC_PROG_F77
AC_F77_WRAPPERS
AC_PROG_CC
AC_PROG_FC
AC_PROG_LIBTOOL
AC_FC_SRCEXT(f90)
AC_LANG(Fortran)
AC_LANG(C)
AX_COMPILER_VENDOR
if test "x${ax_cv_compiler_vendor}" = "xintel" ; then
   echo Compiler vendor... : $ax_cv_compiler_vendor
fi

PP_CC_VERSION_OPTION
AC_PROG_CXX
AC_HEADER_STDC
AC_CHECK_HEADERS(lustre/lustreapi.h)
AC_CHECK_LIB(lustre,llapi_file_create)

AC_ARG_WITH(phdf5, [ --with-phdf5            use Parallel HDF5 with test programs],
            with_phdf5=$withval, with_phdf5=no)
USE_PHDF5=0
if test x$with_phdf5 != xno; then
   USE_PHDF5=1
   PHDF5_DIR=$with_phdf5
fi
AC_SUBST(PHDF5_DIR)

AC_ARG_WITH(node-memory, [ --with-node-memory      Set nodal memory in MB],
with_node_memory=$withval, with_node_memory=no)
NODE_MEMORY=0
if test x$with_node_memory != xno; then
   NODE_MEMORY=1
   MEMSIZE=$with_node_memory
   AC_DEFINE_UNQUOTED(MEMSIZE, $MEMSIZE, [nodal memory size in MB])
fi

AC_ARG_WITH(numcores, [ --with-numcores      The number of cores per node],
with_numcores=$withval, with_numcores=no)
if test x$with_numcores != xno; then
   NUMCORES=$with_numcores
   AC_DEFINE_UNQUOTED(NUMCORES, $with_numcores, [The number of cores per node])
fi

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
