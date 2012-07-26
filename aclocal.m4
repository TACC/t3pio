dnl
dnl *************************************************************************
dnl
AC_DEFUN(PP_SET_OUTPUT_DIR_BY_CMD,
[
pp_output_dir=`$1`
AC_MSG_CHECKING([for output directory: $pp_output_dir])
if test "x$pp_output_dir" = "x"; then
  pp_output_dir='.'
fi
if test ! -d $pp_output_dir; then
  AC_MSG_RESULT([not found, making it])
  mkdir -p $pp_output_dir
else
  AC_MSG_RESULT([yes])  
fi
CONFIG_STATUS=${CONFIG_STATUS="./$pp_output_dir/config.status"}
])
