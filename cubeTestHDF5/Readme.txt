The file t3pio/README describes how to build the t3pio library and the
two test codes: cubeTestHDF5 and unstructTestHDF5.  This file is an
overview of the cubeTestHDF5 program.  This program allows for easy
testing of writing structured rectangle (2-D grid) or structured
bricks (3-D grids).  It uses parallel HDF5 to write a single file in
parallel.

Files Description
-----------------

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
--------------

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

Another small issue is that HDF5 writes knows what the integer and
float point format is on the local machine (BIG/little endian, IEEE,
etc).  The documentation describes have you the source code make a
choice of which format you want to write the data in.  These days,
little endian is the most comment format, you should chose native
format (i.e. "H5T_NATIVE_DOUBLE") for your data.  In the case, where
you need to read your data on a big endian machine, HDF5 will
automatically convert the little endian format if it is ever
necessary.


An overview of writer.F90 and h5_writer routine:
------------------------------------------------

The comment in the routine explain the individual step.  An HDF5 file
can be viewed a directory tree stored in a single file. The overall
structure of the solution file written by this test code is:

/
/Solution
/Solution/T
/Solution/u
/Solution/v
/Solution/w

The "/" is the root of all HDF5 files.  The "Solution" group in HDF5
lingo can be viewed as a directory.  Finally the solution variables
are written out (T,u,v,w).  Each is a scalar field. HDF5 calls each of
these entities a "dataset". HDF5 support vector fields as well.  The
code uses a random number generator in each solution vector so that no
two vectors had exactly the same values.  By using "hyperslabs", each
task has a piece of the dataset and HDF5 combines the values into a
single dataset as if it was written by a single task.

Hyperslabs are the name that HDF5 (and others) use to tell how each
piece of the "dataset" is divided across tasks.  For a 3-D partition
of a cube, each hyperslab is just the offset from the origin and the
local size.  For a 3-D partition this is 6 integers, 3 points for the
offset and 3 points for the local size.


The test code also writes out a unique attribute for "Solution" and each of
the datasets.  A group or a dataset can have as many attributes as one
is willing to add.  This is convenient way to add information about a
computation such as the time of the run, the version of the code or
anything else.  The nice feature is that adding a new attribute to
your standard solution format won't break your codes that read the
data in. This is because reader code will open the file then the group
and finally the dataset.  This is uneffected by the number of
attributes attached to any group or dataset.



