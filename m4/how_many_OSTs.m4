# SYNOPSIS
#

AC_DEFUN([AX_HOW_MANY_OSTs],
[
howManyOSTs()
{
  local j=0
  local dir=$1
  local IFS='
'
  local df=$(lfs df $dir)

  for line in $df; do
    case "$line" in
      *@<:@OST*)
        j=$((j+1));;
    esac
  done
  echo $j
}

AX_lustre_df=$(df)


AX_lustreDir=""

j=0
for i in $AX_lustre_df; do
  j=$((j+1))

  case "$i" in
    *o2ib*)
      dir=$(expr $i : '.*:\(.*\)')
      AX_lustreDir="$dir:$AX_lustreDir"
      ;;
  esac
done


IFS=":"

AX_LUSTRE_FS=""
for dir in $AX_lustreDir; do
  ost=`howManyOSTs $dir`
  AX_LUSTRE_FS="$dir:$ost:$AX_LUSTRE_FS"
done

AC_CACHE_CHECK([for lustre file systems],[my_lustre_fs],
[
  if test -n $AX_LUSTRE_FS ; then
     my_lustre_fs=$AX_LUSTRE_FS
     AC_DEFINE([AX_LUSTRE_FS],$my_lustre_fs,[A colon string of file system names and OSTs])
  fi
])


OLDIFS=$IFS
IFS=$OLDIFS
])
