#include "comm.h"
#include <iostream>
#include <limits.h>
#include <stdlib.h>
#include <unistd.h>
#include <ctype.h>
#include "cmdLineOptions.h"
#include "h5test.h"
#include "t3pio.h"

void printVersion(const char* execName)
{
  if (P.myProc == 0)
    std::cerr << execName << " Version: " << H5TEST_VERSION << std::endl;
}

void printUsage(const char* execName)
{
  printVersion(execName);
  
  std::string romioDft, h5slabDft;
  #ifdef USE_HDF5
    h5slabDft = " (default)";
    romioDft  = "";
  #else
    h5slabDft = "";
    romioDft  = " (default)";
  #endif

  if (P.myProc == 0)
    std::cerr << "\nUsage:\n"
              << execName << " [options]\n\n"
              << "Options:\n"
              << " -h, -?        : Print Usage\n"
              << " -v            : Print Version\n"
              << " -R            : use ROMIO" <<  romioDft  << "\n"
              << " -C            : use h5 chunk\n"
              << " -S            : use h5 slab"<< h5slabDft << "\n"
              << " -I            : use independent instead of collective(collective is default)\n"
              << " -N            : no T3PIO\n"
              << " -O type       : output type (l: lua, t: table, b: both (default: table))\n"
              << " -n nvar       : nvar  (default=4)\n"
              << " -l num        : local size is num (default=10)\n"
              << " -g num        : global size in GBytes\n"
              << " -s num        : maximum number of stripes\n"
              << " -z num        : maximum stripe size in MB\n"
              << " -w num        : Total number of writers\n"
              << " -x num        : xwidth\n"
              << std::endl;
}



CmdLineOptions::CmdLineOptions(int argc, char* argv[])
  : m_state(iBAD)
{
  int  opt;
  bool version, help, illegal;
  char choice;

  useT3PIO         = true;
  maxWriters       = T3PIO_UNSET;
  version          = false;
  help             = false;
  localSz          = -1;
  globalSz         = -1;
  h5chunk          = false;
  h5slab           = false;
  romio            = true;
  stripes          = T3PIO_UNSET;
  stripeSz         = T3PIO_UNSET;
  luaStyleOutput   = false;
  tableStyleOutput = true;
  collective       = true;
  xwidth           = 1;
  xferStyle        = "Collective";
  wrtStyle         = "Romio";

#ifdef USE_HDF5
  h5slab           = true;
  romio            = false;
  wrtStyle         = "h5slab";
#endif



  while ( (opt = getopt(argc, argv, "s:hNCSRLO:w:l:g:n:x:z:?v")) != -1)
    {
      switch (opt)
        {
        case 'v':
          version = true;
          break;
        case '?':
        case 'h':
          help = true;
          break;
        case 'C':
          h5chunk  = true;
          h5slab   = false;
          romio    = false;
          wrtStyle = "h5chunk";
          break;
        case 'R':
          h5chunk  = false;
          h5slab   = false;
          romio    = true;
          wrtStyle = "Romio";
          break;
        case 'S':
          h5slab   = true;
          h5chunk  = false;
          romio    = false;
          wrtStyle = "h5slab";
          break;
        case 'I':
          collective = false;
          xferStyle = "Independent";
          break;
        case 'N':
          useT3PIO = false;
          break;
        case 'x':
          xwidth  = strtol(optarg, (char **) NULL, 10);
          break;
        case 's':
          stripes = strtol(optarg, (char **) NULL, 10);
          break;
        case 'z':
          stripeSz = strtol(optarg, (char **) NULL, 10);
          break;
        case 'g':
          globalSz = strtoll(optarg, (char **) NULL, 10);
          break;
        case 'l':
          localSz = strtoll(optarg, (char **) NULL, 10);
          break;
        case 'n':
          nvar =    strtol(optarg, (char **) NULL, 10);
          break;
        case 'O':
          choice         = tolower(optarg[0]);
          luaStyleOutput = ( choice == 'b' || choice == 'l');
          break;
        case 'w':
          maxWriters    = strtol(optarg, (char **) NULL, 10);
          break;
        default:
          illegal = true;
          ;
        }
    }

  if (version)
    {
      m_state = iHELP;
      printVersion(argv[0]);
      return;
    }

  if (help)
    {
      m_state = iHELP;
      printUsage(argv[0]);
      return;
    }

  if (localSz < 0)
    {
      if (globalSz < 0)
        localSz = 10;
      else
        {
          globalSz *= 128*1024*1024;  // in GBytes
          int rem = globalSz % P.nProcs;
          localSz = globalSz/P.nProcs + (P.myProc < rem);
        }
    }

  if (xwidth != 1)
    {
      localSz  = (localSz/xwidth)*xwidth;
      globalSz = localSz * P.nProcs; 
    }


  if (globalSz < 0)
    globalSz = localSz * P.nProcs;

  m_state = iGOOD;
}

