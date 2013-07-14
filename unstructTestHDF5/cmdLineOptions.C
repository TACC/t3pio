#include "parallel.h"
#include <iostream>
#include <limits.h>
#include <stdlib.h>
#include <unistd.h>
#include "cmdLineOptions.h"
#include "h5test.h"

void printVersion(const char* execName)
{
  if (P.myProc == 0)
    std::cerr << execName << " Version: " << H5TEST_VERSION << std::endl;
}

void printUsage(const char* execName)
{
  printVersion(execName);

  if (P.myProc == 0)
    std::cerr << "\nUsage:\n"
              << execName << " [options]\n\n"
              << "Options:\n"
              << " -h, -?        : Print Usage\n"
              << " -v            : Print Version\n"
              << " -C            : use h5 chunk\n"
              << " -S            : use h5 slab (default)\n"
              << " -n nvar       : nvar  (default=4)\n"
              << " -l num        : local size is num (default=10)\n"
              << " -g num        : global size is num\n"
              << " -f factor     : number of stripes per writer (default=2)\n"
              << " -s num        : maximum number of stripes\n"
              << " -z num        : maximum stripe size in MB\n"
              << " -p num        : maximum number of writers per node\n"
              << " -w num        : Total number of writers\n"
              << std::endl;
}



CmdLineOptions::CmdLineOptions(int argc, char* argv[])
  : m_state(iBAD)
{
  int  opt;
  bool version, help, illegal;

  maxWritersPer  = INT_MAX;

  maxWriters     = -1;
  version        = false;
  help           = false;
  localSz        = -1;
  globalSz       = -1;
  h5chunk        = false;
  h5slab         = false;
  factor         = 1;
  stripes        = -1;
  stripeSz       = -1;
  h5style        = "h5slab";
  luaStyleOutput = false;

  while ( (opt = getopt(argc, argv, "s:hCSLf:p:w:l:g:n:?v")) != -1)
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
          h5chunk = true;
          break;
        case 'L':
          luaStyleOutput = true;
          break;
        case 'f':
          factor  = strtol(optarg, (char **) NULL, 10);
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
        case 'p':
          maxWritersPer = strtol(optarg, (char **) NULL, 10);
          break;
        case 'w':
          maxWriters    = strtol(optarg, (char **) NULL, 10);
          break;
        case 'S':
          h5slab = true;
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

  if (! h5chunk && ! h5slab)
    h5slab = true;

  if ( h5chunk )
    h5style = "h5chunk";

  if (localSz < 0)
    {
      if (globalSz < 0)
        localSz = 10;
      else
        {
          int rem = globalSz % P.nProcs;
          localSz = globalSz/P.nProcs + (P.myProc < rem);
        }
    }

  if (globalSz < 0)
    globalSz = localSz * P.nProcs;

  m_state = iGOOD;
}

