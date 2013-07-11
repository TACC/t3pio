#!/bin/bash
# -*- shell-script -*-

#SBATCH -J CUBE               # Job name
#SBATCH -o CUBE.%j.out        # Name of stdout output file (%j expands to jobId)
#SBATCH -p normal             # Queue name
#SBATCH -N 80                 # Total number of nodes requested (16 cores/node)
#SBATCH -n 1280
#SBATCH -t 12:00:00   

#SBATCH -A A-ccsc

hostname
echo TARG: $TARG
module list

factor=1
nvar=1

for lSz in 10 20 30 37 40 50 60 70 80 90 100 110 120; do
   for i in $(seq 1 40) ; do  
       echo
       t=$( echo " ( $RANDOM * 13 ) / 32768 " | bc -q )
       sleep $t
       ibrun tacc_affinity `pwd`/cubeTestHDF5  --lua --h5slab --numvar $nvar --dim 3 -l $lSz -f $factor
    done
done
