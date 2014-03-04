#ifndef PARALLELIO_H
#define PARALLELIO_H

#include "cmdLineOptions.h"

#ifdef USE_HDF5
#  include "hdf5.h"
#else
typedef int hid_t;
#endif

class ParallelIO
{
public:
  ParallelIO();
  ~ParallelIO() {}
  void h5writer(CmdLineOptions& cmd);
  void MPIIOwriter(CmdLineOptions& cmd);
  void add_attribute(hid_t id, const char* descript, const char* value);
  double rate()        { return m_rate;}
  double time()        { return m_t;}
  double totalTime()   { return m_totalTime;}
  double totalSz()     { return m_totalSz;}
  int    nStripes()    { return m_nStripes;}
  int    nIOUnits()    { return m_nIOUnits;}
  int    aggregators() { return m_aggregators;}
  int    numvar()      { return m_numvar;}
  int    stripeSz()    { return m_stripeSz;}
  int    nWriters()    { return m_nWriters; }
  int    stripeSzMB()  { return m_stripeSz/(1024*1024);}

private:
  double m_t;
  double m_totalTime;
  double m_rate;
  double m_totalSz;
  int    m_nStripes;
  int    m_nIOUnits;
  int    m_stripeSz;
  int    m_numvar;
  int    m_nWriters;
  int    m_aggregators;
};

#endif // PARALLELIO_H

