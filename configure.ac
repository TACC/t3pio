dnl ######################################################################
dnl $Id: configure.ac,v 1.3 2004-01-21 22:13:29 mclay Exp $
dnl ######################################################################
dnl Process this file with autoconf to produce a configure script.
dnl This is for MGF
AC_PREREQ([2.68])
AC_INIT([t3pio],[1.0],[mclay@tacc.utexas.edu])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_HEADER(config.h)
AM_INIT_AUTOMAKE()

AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADER(config.h:config.h.in)
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

AC_PROG_CXX

AC_HEADER_STDC
AC_CHECK_HEADERS(lustre/liblustreapi.h)
AC_CHECK_LIB(lustreapi,llapi_file_create)
AC_CONFIG_MACRO_DIR([m4])
AM_PROG_LIBTOOL

AC_CONFIG_COMMANDS([timestamp], [date > stamp-h])
AC_CONFIG_FILES([Makefile
                 libt3pio/Makefile
		 include/Makefile
		 cubeTestHDF5/Makefile])

AC_OUTPUT()

rm -f conftest*
