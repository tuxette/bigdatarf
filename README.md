# Content description

*scripts made by Robin Genuer, Jean-Michel Poggi, Christine Tuleau-Malot & Nathalie Villa-Vialaneix*

## simulated data (in directory 'simulated')

Data are generated using the script 'simu_toys.R' whose reproducibility has 
been ensured through the definition of random seeds.

* A random forest from these data is obtained sequentially with the script
'sequential_rf.R' (100 trees, maximal number of leaves is set to 500, test 
error is obtained using parallel computation on 10 cores).

* A random forest obtained from a balanced subsample of the data is trained in
parallel with the script 'sampling_rf.R' (maximal number of leaves is set to 
500, test error is obtained sequentially)

The sampling ratio, 'propSample', the number of cores, 'ncores' and the total 
number of trees in the forest, 'total_nbtrees', are all set at the beginning of
the file

* A random forest obtained with a MR approach is trained in parallel with the
script 'mrrf.R' (maximal number of leaves is set to 500, test error is obtained
sequentially)

The number of data chunks, 'nchunks', the number of cores, 'ncores' and the 
number of trees in all forests computing in the Map jobs, 'nbtrees', are all set
at the beginning of the file
