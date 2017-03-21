# Content description

*scripts made by Robin Genuer, Jean-Michel Poggi, Christine Tuleau-Malot & Nathalie Villa-Vialaneix*

## R scripts (in directory 'RLib')

Data are generated using the script 'simu_toys.R' whose reproducibility has 
been ensured through the definition of random seeds.

* A random forest from these data is obtained sequentially with the script
'seqRF.R' (100 trees, maximal number of leaves is set to 500, test error is 
obtained using parallel computation on 10 cores).

* A random forest obtained from a balanced subsample of the data is trained in
parallel with the script 'sampRF.R' (maximal number of leaves is set to 500, 
test error is obtained sequentially)

The sampling ratio, 'propSample', the number of cores, 'ncores' and the total 
number of trees in the forest, 'total_nbtrees', are all set at the beginning of
the file

* A random forest obtained with dacRF approach is trained in parallel with the
script 'dacRF.R' (maximal number of leaves is set to 500, test error is obtained
sequentially)

The number of data chunks, 'nchunks', the number of cores, 'ncores' and the 
number of trees in all forests computed in the chunks, 'nbtrees', are all set
at the beginning of the file

* A random forest obtained with blbRF approach is trained in parallel with the
script 'blbRF.R' (maximal number of leaves is set to 500, test error is obtained
sequentially)

The number of subsamples, 'nbsub', the number of cores, 'ncores' and the 
number of bootstrap samples (hence the number of trees) in all forests
computed for each subsample, 'nbboot', are all set at the beginning of the file

* A random forest obtained with moonRF approach is trained in parallel with the
script 'moonRF.R' (maximal number of leaves is set to 500, test error is
obtained sequentially)

The sampling ratio for each subsamples, 'propSample', the number of cores,
'ncores' and the total number of trees in the forest, 'total_nbtrees',
are all set at the beginning of the file

## python scripts (in directory 'RFTK')

Use Random Forest Toolkit https://github.com/david-matheson/rftk


