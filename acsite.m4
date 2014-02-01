dnl PP_CC_VERSION_STRING
AC_DEFUN([PP_CC_VERSION_OPTION],
[dnl Get compiler version string if possible.
AC_MSG_CHECKING(Get compiler version option)
AC_CACHE_VAL(ac_cv_pp_cc_version_flag,
[
AC_TRY_RUN(
[#include <stdio.h>
main()
{
#if (defined(__GNUC__))
  printf("--version\n");   return 0;
#elif (defined(__PGI) || defined(CRAY) || defined(__sun))
  printf("-V\n");   return 0;
#elif (defined(__linux__) && defined(__alpha__))
  printf("-V\n");   return 0;
#elif (defined(__sgi))
  printf("-version\n");    return 0;
#else
  printf("NONE\n"); return 1;
#endif
}],ac_cv_pp_cc_version_flag=`./conftest`,ac_cv_pp_cc_version_flag=NONE,:)
])
CC_VERSION_FLAG=$ac_cv_pp_cc_version_flag
AC_SUBST(CC_VERSION_FLAG)
AC_MSG_RESULT($ac_cv_pp_cc_version_flag)
])
