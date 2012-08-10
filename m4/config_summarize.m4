# SYNOPSIS
#
#   Summarizes configuration settings.
#
#   AX_SUMMARIZE_CONFIG([, ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND]]])
#
# DESCRIPTION
#
#   Outputs a summary of relevant configuration settings.
#
# LAST MODIFICATION
#
#   2009-07-16
#

AC_DEFUN([AX_SUMMARIZE_CONFIG],
[

echo
echo '----------------------------------- SUMMARY -----------------------------------'
echo
echo Package version............... : $PACKAGE-$VERSION
echo
echo Fortran compiler.............. : $FC
echo Fortran compiler flags........ : $FCFLAGS
echo C compiler.................... : $CC
echo C compiler flags.............. : $CFLAGS
echo Install dir................... : $prefix 
echo Build user.................... : $USER
echo Build host.................... : $BUILD_HOST
echo Configure date................ : $BUILD_DATE
echo Build architecture............ : $BUILD_ARCH
echo Program Version............... : $BUILD_VERSION
echo Lustre Filesystems............ : $AX_LUSTRE_FS
echo Nodal Memory Size in MB....... : $MEMSIZE

echo
echo Optional Features:
if test "$USE_PHDF5" -eq 0 ; then
   echo '   'Link with Parallel HDF5.... : no
else
   echo '   'Link with Parallel HDF5.... : yes
   echo '   'PHDF5_DIR.................. : $PHDF5_DIR
fi

echo
echo '-------------------------------------------------------------------------------'

echo
echo Configure complete, now type \'make\' and then \'make install\'.
echo

])

