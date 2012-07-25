#include "config.h"
#include "mpi.h"
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
#include "t3pio_internal.h"

#if (defined(HAVE_LIBLUSTREAPI) && defined(HAVE_LUSTRE_LIBLUSTREAPI_H))
#   define HAVE_LUSTRE 1
#   include "lustre/liblustreapi.h"
#   include "lustre/lustre_user.h"
#endif

void t3pio_init(T3pio_t* t3)
{
  t3->globalSz   = -1;
  t3->maxStripes = -1;
  t3->factor     = -1;
  t3->numNodes   = -1;
  t3->numIO      = -1;
  t3->numStripes = -1;
  t3->stripeSz   = -1;
  t3->fn         = NULL;
}

int t3pio_usingLustreFS()
{
  static int onLustre = 0;
#ifdef HAVE_LUSTRE
  #define RW_USER (S_IRUSR | S_IWUSR)  /* creation mode for open() */
  struct lov_user_md lum = {0};
  int fdDir = open(".", O_RDONLY);
  if (fdDir != -1 && ioctl(fdDir, LL_IOC_LOV_GETSTRIPE, (void *) &lum) != -1)
    {
      close(fdDir);
      onLustre = 1;
    }
#endif
  return onLustre;
}

static int t3pio_compare (const void * a, const void * b)
{
  /* The pointers point to offsets into "array", so we need to
     dereference them to get at the strings. */

  return strcmp (*(const char **) a, *(const char **) b);
}



int t3pio_numComputerNodes(MPI_Comm comm, int nProc)
{
  static int numNodes = 0;
  int ierr, iproc, icore;
  struct utsname u;
  char * hostNm;
  char * hostNmBuf;
  char ** hostNmA;
  char * p;
  int nlenL, nlen;


  if (numNodes != 0)
    return numNodes;


  uname(&u);
  nlenL = strlen(u.nodename);
  ierr = MPI_Allreduce(&nlenL, &nlen, 1, MPI_INT, MPI_MAX, comm);

  hostNm = (char *) malloc(nlen+1);
  strcpy(hostNm, u.nodename);

  hostNmBuf = (char*)  malloc((nlen+1)*nProc);
  hostNmA   = (char**) malloc(nProc*sizeof(char*));

  ierr = MPI_Allgather(&hostNm[0],    nlen+1, MPI_CHAR,
                       &hostNmBuf[0], nlen+1, MPI_CHAR, comm);

  p = &hostNmBuf[0];
  
  for (iproc = 0; iproc < nProc; ++iproc)
    {
      hostNmA[iproc] = p;
      p += nlen + 1;
    }
  

  qsort (hostNmA, nProc, sizeof (const char *), t3pio_compare);
  numNodes = 1;
  p        = hostNmA[0];

  for (iproc = 1; iproc < nProc; ++iproc)
    {
      if (strcmp(hostNmA[iproc], p) != 0)
        {
          numNodes++;
          p = hostNmA[iproc];
        }
    }
  free(hostNm);
  free(hostNmBuf);
  free(hostNmA);
  return numNodes;
}


#define MAXLINE 2048
int t3pio_maxStripes(MPI_Comm comm, int myProc, const char* dir)
{
  static int stripes = 0;
  int        ierr;

  if (stripes != 0)
    return stripes;

  stripes = 4;
#ifdef HAVE_LUSTRE
  if (myProc == 0 && t3pio_usingLustreFS())
    {
      char line[MAXLINE];
      int stripe_size        = 0;
      int stripe_offset      = -1;
      int stripe_pattern     = 0;
      int stripes_max        = -1;
      int flags              = (O_WRONLY | O_CREAT | O_EXCL);
      // Create a Lustre Striped Test File
      char fn[MAXLINE];
      sprintf(&fn[0], "foo_%d.bar", getpid());
      int rc = llapi_file_create(fn, stripe_size, stripe_offset, stripes_max,
                                 stripe_pattern);
      if (rc == 0)
        {
          flags |= O_LOV_DELAY_CREATE;
          flags &= ~O_EXCL;
          int fd = open(fn, flags, RW_USER);
          FILE* fp = fdopen(fd,"w");
          fprintf(fp, "foo.bar\n");
          fclose(fp);
          sprintf(&line[0],"lfs getstripe -q %s",fn);


          if ( (fp = popen(line, "r")) == NULL)
            {
              fprintf(stderr,"unable to popen\n");
              abort();
            }

          int count = 0;
          while (fgets(line, MAXLINE, fp) != NULL)
            {
              size_t k = strspn(&line[0], " \t");
              if (isdigit(line[k]))
                count++;
            }
          stripes = count;
        }
      unlink(fn);
    }
  ierr = MPI_Bcast(&stripes, 1, MPI_INTEGER, 0, comm);
#endif
  return stripes;
}

#define f_numStripesIOunits F77_FUNC(numstripesiounits,NUMSTRIPESIOUNITS)


void f_numStripesIOunits(int* factor, int* Stripes, int * nStripes, int * nIO)
{
  static int numNodes   = 0;
  static int numIO      = 0;
  static int numStripes = 0;
  int nProc, myProc, mStripes;
  int f = *factor;

  if (numNodes != 0)
    {
      *nStripes = numStripes;
      *nIO      = numIO;
      return;
    }

  MPI_Comm_rank(MPI_COMM_WORLD, &myProc);
  MPI_Comm_size(MPI_COMM_WORLD, &nProc);

  numNodes  = numComputerNodes(nProc);

  numStripes = maxStripes(myProc);
  if (numNodes*f < numStripes) numStripes = numNodes*f;

  if (*Stripes > 0)
    {
      numIO = *Stripes/f;
      if (numIO > 2*numNodes) numIO = 2*numNodes;
      numStripes = numIO*f;
    }

  numIO      = numStripes/f;
  *nStripes  = numStripes;
  *nIO       = numIO;
  return;
}

int readStripes(int myProc, const char * fn)
{
  int count   = 0;
  int stripes = 4;
  int ierr;
#ifdef HAVE_LUSTRE
  if (myProc == 0 && usingLustreFS())
    {
      FILE* fp;
      char  line[MAXLINE];
      sprintf(&line[0],"lfs getstripe -q %s",fn);
      if ( (fp = popen(line, "r")) == NULL)
        {
          fprintf(stderr,"unable to popen\n");
          abort();
        }

      while (fgets(line, MAXLINE, fp) != NULL)
        {
          size_t k = strspn(&line[0], " \t");
          if (isdigit(line[k]))
            count++;
        }
      stripes = count;
    }
  ierr = MPI_Bcast(&stripes, 1, MPI_INTEGER, 0, MPI_COMM_WORLD);
#endif
  return stripes;
}

#define f_readStripesIOunits F77_FUNC(readstripesiounits,READSTRIPESIOUNITS)

void f_readStripesIOunits(const char * fn, int factor, int* nStripes, int * nIO, int fnLen)
{
  char *p;
  char fnZ[MAXLINE];
  int myProc, nProc, numIO, numStripes, numNodes;

  MPI_Comm_rank(MPI_COMM_WORLD, &myProc);
  MPI_Comm_size(MPI_COMM_WORLD, &nProc);

  assert(MAXLINE >= fnLen);
  memcpy(&fnZ[0], fn, fnLen);
  fnZ[fnLen] = '\0';
  p = strchr(&fnZ[0],' ');
  *p = '\0';

  numStripes = readStripes(myProc, fn);
  numNodes   = numComputerNodes(nProc);
  assert(fn != NULL);
  if (numNodes*factor < numStripes) numStripes = numNodes*factor;

  if (factor < 1 || factor > 4) factor = 4;
  numIO     = numStripes/factor;
  *nStripes = numStripes;
  *nIO      = numIO;
}

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
