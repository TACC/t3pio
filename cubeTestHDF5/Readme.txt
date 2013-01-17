The file t3pio/README describes how to build the t3pio library and the
two test codes: cubeTestHDF5 and unstructTestHDF5.  This file is an
overview of the cubeTestHDF5 program.  This program allows for easy
testing of writing structured rectangle (2-D grid) or structured
bricks (3-D grids).  It uses parallel HDF5 to write a single file in
parallel.

Files Description

master.F90:   The main program
cmdline.F90:  The routine that parses the command line arguments
parallel.F90: This is the "parallel" module which partitions the
              processor (or tasks) into a 2-D or 3-D grid.
grid.F90:     This is the "grid" module which partitions the grid.
              The important data structure is the derived type
              "grid_t".  Each processor had a "global" and "local"
              grid_t.  The "global" var has the global size of the
              domain.  The "local" var has the local size of the
              domain and it knows what the offset the local grid is
              in relation to the global grid

writer.F90:   This module is what actually writes the HDF5 file.
              Depending on the command line arguments, the program
              will write out the results into a MPIIO file, HDF5
              file using hyperslabs, or HDF5 file using the chunks.
              Testing shows that HDF5 using hyperslabs gets the best
              performance.

assert.F90:
assert.hf:    Implements the ASSERT macro
measure.c:    Timer routines.


Learning HDF5:

The best way to learn HDF5 is to work through the tutorial at
http://www.hdfgroup.org/HDF5/Tutor/index.html.  The user guide and
other documentation at the site are not written for novice users of
HDF5.   Once you have worked through the tutorial, you'll see that
writer.F90 is a straight forward use of HDF5.


There is one thing that the tutorial does not explain well is how to
write attributes in parallel. HDF5 uses the word "dataset" to describe
the data you wish to write in parallel (i.e. the solution vector).
The text used to describe the dataset is called an attribute.  The one
notion that is confusing is that all tasks writing the dataset also
write out the attribute even though all the tasks have exactly the
same text information.
