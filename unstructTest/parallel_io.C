#include "h5test.h"
#include "parallel_io.h"
#include "parallel.h"
#include "cmdLineOptions.h"
#include <stdlib.h>
#include <iostream>
#include <string.h>
#include "measure.h"
#include "t3pio.h"

struct Var_t
{
  const char * name;
  const char * descript;
};

Var_t varT[] =
  {
    {"T", "Temp in K"},
    {"p", "Pressure in N/m^2"},
    {"u", "X Velocity in m/s"},
    {"v", "Y Velocity in m/s"},
    {"w", "Z Velocity in m/s"},
    {"a", "A Velocity in m/s"},
    {"b", "B Velocity in m/s"},
    {"c", "C Velocity in m/s"},
    {"d", "D Velocity in m/s"},
    {"e", "E Velocity in m/s"},
  };

ParallelIO::ParallelIO()
  : m_t(0.0), m_rate(0.0), m_totalSz(1.0), m_nStripes(1),
    m_nIOUnits(1), m_stripeSz(-1), m_numvar(1)
{}


#ifndef USE_HDF5
void ParallelIO::h5writer(CmdLineOptions& cmd)
{
  if (P.myProc == 0) 
    printf("This program requires HDF5 which is not available => quitting\n");
}

void ParallelIO::add_attribute(hid_t id, const char* descript, const char* value)
{
}

#else
void ParallelIO::h5writer(CmdLineOptions& cmd)
{

  hid_t   file_id;       //file      identifier
  hid_t   group_id;      //group     identifier
  hid_t   dset_id;       //Dataset   identifier
  hid_t   filespace;     //Dataspace id in file
  hid_t   memspace;      //Dataspace id in memory.
  hid_t   plist_id;      //Property List id
  hsize_t sz[1], gsz[1], starts[1], count[1], block[1], h5stride[1], rem;
  hsize_t is, num;
  H5FD_mpio_xfer_t  xfer_mode;   // HDF5 transfer mode (indep or collective)
  const char * fn = "unstruct.h5";

  // compute size info

  rem = cmd.globalSz % P.nProcs;
  if (P.myProc < rem)
    is = P.myProc * cmd.localSz;
  else
    is = (cmd.localSz + 1)*rem + cmd.localSz*(P.myProc - rem);

  double lSz     = 1.0;

  m_numvar    = cmd.nvar;
  num         = cmd.localSz;
  lSz         = num;
  count[0]    = 1;
  h5stride[0] = 1;
  starts[0]   = is;
  sz[0]       = num;
  gsz[0]      = cmd.globalSz;
  m_totalSz   = cmd.globalSz*m_numvar*sizeof(double);

  
  int iTotalSz = m_totalSz/(1024*1024);
  

  // Initialize data buffer
  double xk = num*P.myProc;

  double *data = new double[num];
  for (int i = 0; i < num; ++i)
    data[i] = xk++;


  double t0, t1, t2;

  // Delete old file
  if (P.myProc == 0)
    MPI_File_delete((char * )fn, MPI_INFO_NULL);
  MPI_Barrier(P.comm);


  // Build MPI info;
  MPI_Info info = MPI_INFO_NULL;
  MPI_Info_create(&info);


  T3PIO_results_t results;

  if (cmd.useT3PIO)
    {
      int ierr = t3pio_set_info(P.comm, info, "./",
                                T3PIO_GLOBAL_SIZE,         iTotalSz,
                                T3PIO_STRIPE_COUNT,        cmd.stripes,
                                T3PIO_STRIPE_SIZE_MB,      cmd.stripeSz,
                                T3PIO_MAX_AGGREGATORS,     cmd.maxWriters,
                                T3PIO_RESULTS,             &results);
  

      m_nStripes    = results.numStripes;
      m_nIOUnits    = results.numIO;
      m_stripeSz    = results.stripeSize;
    }

  xfer_mode = (cmd.collective) ? H5FD_MPIO_COLLECTIVE : H5FD_MPIO_INDEPENDENT;

  t0 = walltime();

  plist_id = H5Pcreate(H5P_FILE_ACCESS);
  H5Pset_fapl_mpio(plist_id, P.comm, info);

  
  // Create file collectively
  file_id = H5Fcreate(fn, H5F_ACC_TRUNC, H5P_DEFAULT, plist_id);
  H5Pclose(plist_id);

  // Create Group
  group_id = H5Gcreate(file_id, "Solution", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
  
  std::string timeZ, timeL;
  dateZ(timeZ);
  add_attribute(group_id,"Zulu Time", timeZ.c_str());

  dateL(timeL);
  add_attribute(group_id,"Local Time", timeL.c_str());


  for (int ivar = 0; ivar < m_numvar; ++ivar)
    {

      // Create the dataspace for the dataset
      filespace = H5Screate_simple(1, &gsz[0], NULL);
      memspace  = H5Screate_simple(1, sz,      NULL);

      if (cmd.h5chunk) 
        {
          plist_id = H5Pcreate(H5P_DATASET_CREATE);
          H5Pset_chunk(plist_id,1, sz);
          
          dset_id = H5Dcreate(group_id, varT[ivar].name, H5T_NATIVE_DOUBLE, filespace,
                              H5P_DEFAULT, plist_id, H5P_DEFAULT);
          H5Pclose(plist_id);
          H5Sclose(filespace);
            
          filespace = H5Dget_space(dset_id);
          H5Sselect_hyperslab(filespace, H5S_SELECT_SET, starts, h5stride, count, sz);
        }
      else if (cmd.h5slab)
        {
          // Create the dataset w/ default properties and close filespace
          dset_id = H5Dcreate(group_id, varT[ivar].name, H5T_NATIVE_DOUBLE, filespace,
                              H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
          H5Sclose(filespace);
  
          // Select hyperslab in the file.
          filespace = H5Dget_space(dset_id);
          H5Sselect_hyperslab(filespace, H5S_SELECT_SET, starts, NULL, sz , NULL);
        }

      plist_id = H5Pcreate(H5P_DATASET_XFER);
      H5Pset_dxpl_mpio(plist_id, xfer_mode);

      add_attribute(dset_id, "Variable Description", varT[ivar].descript);

      t1   = walltime();

      herr_t status = H5Dwrite(dset_id, H5T_NATIVE_DOUBLE, memspace, filespace,
                               plist_id, data);
      t2   = walltime();
      m_t += (t2 - t1);

      H5Dclose(dset_id);
      H5Sclose(filespace);
      H5Sclose(memspace);
      H5Pclose(plist_id);
    }

  m_totalTime = walltime() - t0;
  m_rate      = m_totalSz /(m_totalTime * 1024.0 * 1024.0);
  free(data);
  H5Gclose(group_id);
  H5Fclose(file_id);
}

void ParallelIO::add_attribute(hid_t id, const char* descript, const char* value)
{
  hid_t attr_id, aspace_id, atype_id;
  hsize_t attrlen, num[1];


  attrlen = strlen(value);
  num[0]  = 1;

  atype_id = H5Tcopy(H5T_C_S1);
  H5Tset_size(atype_id, attrlen);

  aspace_id = H5Screate_simple(1,num, NULL);

  attr_id   = H5Acreate(id, descript, atype_id, aspace_id, H5P_DEFAULT, H5P_DEFAULT);
  H5Awrite(attr_id, atype_id, value);
  H5Aclose(attr_id);
  H5Sclose(aspace_id);
}
#endif

void ParallelIO::MPIIOwriter(CmdLineOptions& cmd)
{

  MPI_File     fh;
  MPI_Offset   is, rem, offset;
  MPI_Datatype coreData, gblData, my_vector;
  MPI_Status   status;
  int          iTotalSz, ierr, nDim;
  int          sz[2], gsz[2], starts[2];
  const char*  fn = "UNSTRUCT.mpiio";

  rem = cmd.globalSz % P.nProcs;
  if (P.myProc < rem)
    is = P.myProc * cmd.localSz;
  else
    is = (cmd.localSz + 1)*rem + cmd.localSz*(P.myProc - rem);
  

  m_numvar      = 1;
  m_totalSz     = cmd.globalSz*m_numvar*sizeof(double);
  iTotalSz      = m_totalSz/(1024*1024);
  int    num    = cmd.localSz;
  double *data  = new double[num];
  double xk     = is;

  
  for (int i = 0; i < num; ++i)
    data[i] = xk++;

  double t0, t1, t2;

  // Delete old file
  if (P.myProc == 0)
    MPI_File_delete((char * )fn, MPI_INFO_NULL);
  MPI_Barrier(P.comm);


  // Build MPI info;
  MPI_Info info = MPI_INFO_NULL;
  MPI_Info_create(&info);


  T3PIO_results_t results;

  if (cmd.useT3PIO)
    {
      int ierr = t3pio_set_info(P.comm, info, "./",
                                T3PIO_GLOBAL_SIZE,         iTotalSz,
                                T3PIO_STRIPE_COUNT,        cmd.stripes,
                                T3PIO_STRIPE_SIZE_MB,      cmd.stripeSz,
                                T3PIO_MAX_AGGREGATORS,     cmd.maxWriters,
                                T3PIO_RESULTS,             &results);

      m_nStripes    = results.numStripes;
      m_nIOUnits    = results.numIO;
      m_stripeSz    = results.stripeSize;
    }

  //nDim = 1;
  //offset = is*sizeof(double);
  //ierr = MPI_Type_contiguous(num, MPI_DOUBLE, &my_vector);
  //ierr = MPI_Type_commit(&my_vector);
  //ierr = MPI_File_set_view(fh, offset, MPI_DOUBLE, my_vector, "native", info);

  offset    = 0;
  nDim      = 2;
  sz[0]     = cmd.localSz/cmd.xwidth;
  sz[1]     = cmd.xwidth;
  gsz[0]    = cmd.globalSz/cmd.xwidth;
  gsz[1]    = cmd.xwidth;
  starts[0] = 0;
  starts[1] = 0;
    
  ierr = MPI_Type_create_subarray(nDim, sz, sz, starts, MPI_ORDER_C, MPI_DOUBLE, &coreData);
  ierr = MPI_Type_commit(&coreData);
  starts[0] = sz[0]*P.myProc;
  ierr = MPI_Type_create_subarray(nDim, gsz, sz, starts, MPI_ORDER_C, MPI_DOUBLE, &gblData);
  ierr = MPI_Type_commit(&gblData);


  t0 = walltime();
  
  ierr = MPI_File_open(P.comm, (char *) fn, MPI_MODE_WRONLY | MPI_MODE_CREATE, info, &fh);
  if (ierr)
    MPI_Abort(P.comm, -1);

  ierr = MPI_File_set_view(fh, offset, MPI_DOUBLE, gblData, "native", info);

  ierr = MPI_File_write_all(fh, &data[0], 1, coreData, &status);
  ierr = MPI_File_close(&fh);

  m_totalTime = walltime() - t0;
  m_rate      = m_totalSz/(m_totalTime * 1024.0 * 1024.0);
}

