# SYNOPSIS
#

AC_DEFUN([AX_HOW_MANY_OSTs],
[
OLDIFS=$IFS
AX_OST_NUMBER=0
howManyOSTs()
{
  local j=0
  local dir=[${1}]
  local IFS='
'
  local df=$(lfs df $dir)

  for line in $df; do
    case "$line" in
      *@<:@OST*)
        j=$((j+1));;
    esac
  done
  AX_OST_NUMBER=$j
}

AX_lustre_mount=$(mount)


AX_lustreDir=""

j=0
IFS='
'
for i in $AX_lustre_mount; do
  j=$((j+1))

  case "$i" in
    *type\ *lustre* )
       dir=$(expr "$i" : '.* on \(/@<:@^ @:>@@<:@^ @:>@*\) ')
       AX_lustreDir="$dir:$AX_lustreDir"
       ;;
  esac
done


IFS=":"

AX_LUSTRE_FS=""
for dir in $AX_lustreDir; do
  howManyOSTs $dir
  AX_LUSTRE_FS="$dir:$AX_OST_NUMBER:$AX_LUSTRE_FS"
done

IFS=$OLDIFS

AC_CACHE_CHECK([for lustre file systems], [my_cv_lustre_fs],
[
  if test -n $AX_LUSTRE_FS ; then
     my_cv_lustre_fs=$AX_LUSTRE_FS
  fi
])

AC_DEFINE_UNQUOTED([AX_LUSTRE_FS],"$my_cv_lustre_fs",[A colon string of file system names and OSTs])

])
