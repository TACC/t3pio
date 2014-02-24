#include <mpi.h>
#include "config.h"
#include <assert.h>
#include <limits.h>
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

#if (defined(HAVE_LUSTREAPI) && defined(HAVE_LUSTRE_LUSTREAPI_H))
#   define HAVE_LUSTRE 1
#   include "lustre/lustreapi.h"
#   include "lustre/lustre_user.h"
#endif
#define MAXLINE 4096

void t3pio_init(T3Pio_t* t3)
{
  char *p;
  int  v;
  t3->globalSz   = -1;
  t3->maxStripes = -1;
  t3->factor     = -1;
  t3->numNodes   = -1;
  t3->numIO      = -1;
  t3->numStripes = -1;
  t3->nodeMem    = -1;
  t3->stripeSz   = -1;
  t3->maxWriters = -1;
  t3->dir        = NULL;
  t3->fn         = NULL;

  if ((p=getenv("T3PIO_STRIPE_COUNT")) != NULL)
    t3->maxStripes = strtol(p, (char **) NULL, 10);
  
  if ((p=getenv("T3PIO_MAX_AGGREGATORS")) != NULL)
    t3->maxWriters = strtol(p, (char **) NULL, 10);
  
  if ((p=getenv("T3PIO_STRIPE_SIZE_MB")) != NULL)
    t3->stripeSz = strtol(p, (char **) NULL, 10);
}

int t3pio_usingLustreFS(const char * dir)
{
  static int onLustre = 0;
#ifdef HAVE_LUSTRE
  #define RW_USER (S_IRUSR | S_IWUSR)  /* creation mode for open() */
  struct lov_user_md lum = {0};
  int fdDir = open(dir, O_RDONLY);
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



int t3pio_maxStripesPossible(void)
{
  const int lustreMax = 160;
  return lustreMax;
}


void t3pio_numComputerNodes(MPI_Comm comm, int nProc, int* numNodes, int* numCoresPer, int* numCoresMax)
{
  int ierr, iproc, icore;
  struct utsname u;
  char * hostNm;
  char * hostNmBuf;
  char ** hostNmA;
  char * p;
  int nlenL, nlen, nCores;
  int nNodes, nCoresMax, myProc;

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
  nNodes    = 1;
  p         = hostNmA[0];
  nCores    = 1;
  nCoresMax = 0;


  for (iproc = 1; iproc < nProc; ++iproc)
    {
      if (strcmp(hostNmA[iproc], p) == 0)
        nCores++;
      else
        {
          if (nCores > nCoresMax)
            nCoresMax = nCores;
          nNodes++;
          p = hostNmA[iproc];
          nCores = 0;
        }
    }
  if (nCoresMax == 0)
    nCoresMax = nCores;
  free(hostNm);
  free(hostNmBuf);
  free(hostNmA);
  *numCoresPer = nCoresMax;
  *numNodes    = nNodes;

#ifdef NUMCORES
  *numCoresMax = NUMCORES;
#else
#ifdef __linux__
  MPI_Comm_rank(comm, &myProc);
  if (myProc == 0)
    {
      char buffer[MAXLINE];
      FILE* fp = fopen("/proc/cpuinfo","r");
      char* eof;
      
      while( (eof = fgets(&buffer[0], MAXLINE, fp)) != 0)
        {
          if (strncasecmp(&buffer[0],"processor", 9) == 0)
            {
              char* p = strchr(&buffer[0], ':');
              if (p == NULL)
                continue;
              ++p;
              nCoresMax = (int) strtol(p, (char**) NULL, 10) + 1;
            }
        }
    }
  ierr = MPI_Bcast(&nCoresMax, 1, MPI_INTEGER, 0, comm);
#endif  /* __linux__ */
  *numCoresMax = nCoresMax;
#endif /* NUMCORES */
}

int t3pio_asklustre(MPI_Comm comm, int myProc, const char* dir)
{
  int        ierr;
  int        stripes = t3pio_maxStripesPossible();
  
#ifdef HAVE_LUSTRE
  if (myProc == 0 && t3pio_usingLustreFS(dir))
    {

      char line[MAXLINE];
      int stripe_size        = 0;
      int stripe_offset      = -1;
      int stripe_pattern     = 0;
      int stripes_max        = -1;
      int flags              = (O_WRONLY | O_CREAT | O_EXCL);
      // Create a Lustre Striped Test File
      char fn[MAXLINE];
      sprintf(&fn[0], "%s/foo_%d.bar", dir, getpid());
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
          fclose(fp);
        }
      unlink(fn);
    }
  ierr = MPI_Bcast(&stripes, 1, MPI_INTEGER, 0, comm);
#endif
  return stripes;
}


int t3pio_maxStripes(MPI_Comm comm, int myProc, const char* dir)
{
  const char *p, *p0;
  int  ierr;
  int  matchLen    = 0;
  int  stripes;
  int  stripesMax  = t3pio_maxStripesPossible();
  char abspath[PATH_MAX];
  
  stripes = stripesMax;

#ifdef HAVE_LUSTRE
#ifdef AX_LUSTRE_FS
  /* Find realpath of dir */
  if ( dir == NULL)
    return stripes;

  if ( dir[0] == '/' )
    realpath(dir,abspath);
  else
    {
      size_t len, dlen;
      char path[PATH_MAX];
      getcwd(path,PATH_MAX);
      len = strlen(path);
      memcpy(&path[len],"/",1); len++;

      dlen = strlen(dir);
      memcpy(&path[len],dir,dlen); len += dlen;
      path[len] = '\0';
      realpath(path,abspath);
    }

  
  p0 = AX_LUSTRE_FS;

  while((p = strchr(p0,':')) != NULL)
    {
      size_t len = p - p0;
      if (strncmp(abspath,p0,len) == 0   &&
          abspath[len]            == '/' &&
          len          > matchLen)
        {
          matchLen = len;
          sscanf(p+1,"%d",&stripes);
          break;
        }
      p0 = strchr(p+1,':')+1;
    }

  stripes = (stripes > stripesMax) ? stripesMax : stripes;
#else
  stripes = t3pio_asklustre(comm, myProc, dir);
#endif  /* AX_LUSTRE_FS */
#endif  /* HAVE_LUSTRE */
  return stripes;
}



int t3pio_nodeMemory(MPI_Comm comm, int myProc)
{
  char  line[MAXLINE];
  int   memSz;

#ifdef MEMSIZE
  memSz = MEMSIZE;
#else
  if (myProc == 0)
    {
      FILE* fp;
      if ( (fp = popen("free -m","r")) == NULL)
        {
          fprintf(stderr,"Unable to popen \"free -m\"\n");
          abort();
        }
      
      while ( fgets(line, MAXLINE, fp) != NULL)
        {
          if (strncmp(line,"Mem:",4) == 0)
            {
              sscanf(&line[4],"%d", &memSz);
              break;
            }
        }
      fclose(fp);
    }
  int ierr = MPI_Bcast(&memSz, 1, MPI_INTEGER, 0, comm);
#endif
  return memSz;
}



int t3pio_readStripes(MPI_Comm comm, int myProc, const char * fn)
{
  int count   = 0;
  int stripes = 4;
  int ierr;
#ifdef HAVE_LUSTRE
  char dir[PATH_MAX];
  char *p;
  strcpy(dir,fn);
  p = strrchr(dir,'/');
  if (p == NULL)
    strcpy(dir,"./");
  else
    *p = '\0';
  
  if (myProc == 0 && t3pio_usingLustreFS(dir))
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
  ierr = MPI_Bcast(&stripes, 1, MPI_INTEGER, 0, comm);
#endif
  return stripes;
}
