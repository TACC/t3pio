dnl ######################################################################
dnl $Id: configure.ac,v 1.3 2004-01-21 22:13:29 mclay Exp $
dnl ######################################################################
dnl Process this file with autoconf to produce a configure script.
dnl This is for MGF
AC_PREREQ([2.67])
AC_INIT([t3pio],[1.0])
AC_CONFIG_SRCDIR(Build.in)
AC_CHECK_PROG(OBJ_DIR_NAME,targ,[`targ`],[OBJ])
if test x$OBJ_DIR_NAME = xOBJ ; then
  pp_output_dir=OBJ
  export OBJ_DIR_NAME="OBJ"
  mkdir -p $pp_output_dir
  CONFIG_STATUS=${CONFIG_STATUS="./$pp_output_dir/config.status"}
else
  PP_SET_OUTPUT_DIR_BY_CMD(targ)
fi
AC_CHECK_PROG(have_fdepend, fdepend, yes, no)
AC_CONFIG_HEADER($pp_output_dir/config.h:config.h.in)
AC_F77_WRAPPERS
AC_PROG_CC
AC_HEADER_STDC
AC_CHECK_HEADERS(lustre/liblustreapi.h)
AC_CHECK_LIB(lustreapi,llapi_file_create)
AC_CONFIG_FILES($OBJ_DIR_NAME/build.mk:Build.in)
AC_CONFIG_COMMANDS([timestamp], [date > stamp-h])
AC_OUTPUT()
rm -f conftest*
