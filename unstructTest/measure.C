#include "measure.h"
#include <time.h>
#include <sys/time.h>

double walltime(void)
{
  double t1;
  struct timezone z;
  struct timeval  tv;
  gettimeofday(&tv, &z);
  t1 = tv.tv_sec + tv.tv_usec * 1.0e-6;
  return t1;
}
void dateZ(std::string& timeZ)
{
  time_t t;
  time(&t);
  char * d;
  d = asctime(gmtime(&t));

  //0123456789 123456789 123456789
  //Sat Dec 10 13:47:29 2011

  timeZ = d;
  size_t pos = timeZ.find_first_of("\n");
  timeZ.erase(pos);
  timeZ.insert(19,"Z");
}

void dateL(std::string& timeL)
{
  
  int len ;
  char * a;
  time_t t;
  char * d;

  time(&t);
  d = asctime(localtime(&t));
  timeL = d;
  size_t pos = timeL.find_first_of("\n");
  timeL.erase(pos);
}
