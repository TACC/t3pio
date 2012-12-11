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
  int         factor;
  int         stripes;
  int         maxWritersPer;
  int         maxWriters;
  bool        luaStyleOutput;
  bool        h5chunk;
  bool        h5slab;
  std::string h5style;
 private:
  state_t      m_state;
};

#endif /* CMDLINEOPTIONS_H */
