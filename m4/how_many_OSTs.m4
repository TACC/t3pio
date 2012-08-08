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
  local df=`lfs df $dir`

  for line in $df; do
    case "$line" in
      *[OST*)
        j=$((j+1));;
    esac
  done
  echo $j
}
OLDIFS=$IFS

AX_df=`df`
AX_lustreDir=""
j=0
for i in $df; do
  j=$((j+1))

  case "$i" in
    *o2ib*)
      dir=`expr $i : '.*:\(.*\)'`
      AX_lustreDir="$dir:$AX_lustreDir"
      ;;
  esac
done

IFS=":"

AX_LUSTRE_FS=""

for dir in $lustreDir; do
  ost=`howManyOSTs $dir`
  AX_LUSTRE_FS="$dir:$ost:$AX_LUSTRE_FS"
done


AC_SUBST(AX_LUSTRE_FS)

IFS=$OLDIFS
])
