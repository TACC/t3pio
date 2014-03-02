#ifndef CMDLINEOPTIONS_H
#define CMDLINEOPTIONS_H
#include <string>

class CmdLineOptions
{
 public:
  CmdLineOptions(int argc, char* argv[]);
  enum state_t { iBAD = 1, iHELP, iGOOD };


  state_t state() {return m_state;}

 private:
  char cleanup(const char* s);

 public:
  long long   globalSz;
  long long   localSz;
  int         nvar;
  int         stripes;
  int         stripeSz;  // in MB
  int         maxWriters;
  int         xwidth;
  bool        collective;
  bool        useT3PIO;
  bool        luaStyleOutput;
  bool        tableStyleOutput;
  bool        h5chunk;
  bool        h5slab;
  bool        romio;
  std::string wrtStyle;
  std::string xferStyle;
 private:
  state_t      m_state;
};

#endif /* CMDLINEOPTIONS_H */
