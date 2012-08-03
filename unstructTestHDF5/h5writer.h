#ifndef H5WRITER_H
#define H5WRITER_H

#include "cmdLineOptions.h"
#include "hdf5.h"

class H5
{
public:
  H5();
  ~H5() {}
  void writer(CmdLineOptions& cmd);
  void add_attribute(hid_t id, const char* descript, const char* value);
  double rate()       { return m_rate;}
  double time()       { return m_t;}
  double totalSz()    { return m_totalSz;}
  int    nStripes()   { return m_nStripes;}
  int    nIOUnits()   { return m_nIOUnits;}
  int    factor()     { return m_factor;}
  int    stripeSz()   { return m_stripeSz;}
  int    stripeSzMB() { return m_stripeSz/(1024*1024);}

private:
  double m_t;
  double m_rate;
  double m_totalSz;
  int    m_nStripes;
  int    m_nIOUnits;
  int    m_factor;
  int    m_stripeSz;
};

#endif // H5WRITER_H
