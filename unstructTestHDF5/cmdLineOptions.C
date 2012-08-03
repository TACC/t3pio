#include <iostream>
#include <stdlib.h>
#include "cmdLineOptions.h"
#include "parallel.h"
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
              << " -l num        : local size is num (default=10)\n"
              << " -f factor     : number of stripes per writer (default=2)\n"
              << " -s num        : maximum number of stripes\n"
              << std::endl;
}



CmdLineOptions::CmdLineOptions(int argc, char* argv[])
  : m_state(iBAD)
{
  int  opt;
  bool version, help, illegal;

  version      = false;
  help         = false;
  localSz      = 10;
  h5chunk      = false;
  h5slab       = false;
  factor       = 2;
  stripes      = -1;
  h5style      = "h5slab";

  while ( (opt = getopt(argc, argv, "s:hCSf:l:?v")) != -1)
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
        case 'f':
          factor  = strtol(optarg, (char **) NULL, 10);
          break;
        case 's':
          stripes = strtol(optarg, (char **) NULL, 10);
          break;
        case 'l':
          localSz = strtol(optarg, (char **) NULL, 10);
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

  m_state = iGOOD;
}

