#include "measure.h"
#include <sys/time.h>

double f_walltime(void)
{
  double t1;
  struct timezone z;
  struct timeval  tv;
  gettimeofday(&tv, &z);
  t1 = tv.tv_sec + tv.tv_usec * 1.0e-6;
  return t1;
}

#include "config.h"
#include <assert.h>
#include <time.h>
#include <ctype.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/utsname.h>

#define f_dateZ F77_FUNC(datez, DATEZ)
#define f_dateL F77_FUNC(datel, DATEL)

void f_dateZ(char *timeZ, int datelen)
{

  char * a, * b;
  time_t t;
  time(&t);
  char * d;
  d = asctime(gmtime(&t));

  memcpy(timeZ,d, 19);
  b    = &d[19];
  a    = &timeZ[19];
  *a++ = 'Z';
  memcpy(a, b, 5);
  a += 5;

  for (; a < &timeZ[datelen]; ++a)
    *a = ' ';
}

void f_dateL(char *timeL, int datelen)
{

  int len ;
  char * a;
  time_t t;
  char * d;

  time(&t);
  d = asctime(localtime(&t));
  len = strlen(d);
  if (d[len-1] == '\n')
    len--;
  memcpy(timeL,d, len);
  a   = &timeL[len];
  for (; a < &timeL[datelen]; ++a)
    *a = ' ';
}
