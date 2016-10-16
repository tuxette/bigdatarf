##### Script description ------------------------------------------------------
# Script that trains a random forest on a subsample. The forest is trained in 
# parallel using ncores
# The script uses the packages 'readr', 'parallel', 'dplyr' and 'randomForest'
##### -------------------------------------------------------------------------

library(readr)
library(parallel)
library(randomForest)

##### Set parameters ----------------------------------------------------------
nbchunks <- 10 # number of chunks
nbtrees <- 100 # number of trees in each subforest
ncores <- 10 # number of cores

##### Loading the data --------------------------------------------------------
myTimeLoad <- system.time({
  print("loading...")
  # reading the data...
  simulated <- read_delim("alldata2_randperm.txt", " ")
  
  # cleaning the data
  print("cleaning...")
  simulated <- as.data.frame(simulated)
  simulated$y <- as.factor(simulated$y)
})
nbobs <- nrow(simulated)

##### Spliting the data and building the forest (in parallel) -----------------
print("training...")
sizechunk <- round(nbobs / nbchunks)
myTimeTrain <- system.time({
  simulated_mrrf <- mclapply(1:nbchunks, function(ind) {
    if (ind < nbchunks) {
      sel_ind <- (1+sizechunk*(ind-1)):(sizechunk*ind)
    } else sel_ind <- (1+sizechunk*(ind-1)):nbobs
    subsimulated <- simulated[sel_ind, ]
    res <- randomForest(y~., data=subsimulated, ntree=nbtrees, maxnodes=500)
    return(res)
  }, mc.cores = ncores)
})

##### Computing BDerrForest ---------------------------------------------------
print("computing training OOB errors...")
estOOB <- sum(unlist(lapply(simulated_mrrf, function(aforest) 
  tail(aforest$err.rate[,1], 1))) *
    c(rep(sizechunk,nbchunks-1), nbobs-(nbchunks-1)*sizechunk)
) / nbobs
# BDerrForest is: estOOB

##### Computing errForest -----------------------------------------------------
errOOB <- mclapply(1:nbchunks, function(ind) {# loop over chunks
  if (ind < nbchunks) {
    sel_ind <- (1+sizechunk*(ind-1)):(sizechunk*ind)
  } else sel_ind <- (1+sizechunk*(ind-1)):nbobs
  
  # prediction (standard for out-of-the-chunk observations, OOB for 
  # in-the-chunk observations)
  predOOB <- lapply(simulated_mrrf, function(aforest)
    predict(aforest, simulated[sel_ind, ], type="vote")*nbtrees)
  predOOB[[ind]] <- predict(simulated_mrrf[[ind]], type="vote")*nbtrees
  # set to 0 all observations with NA (this will not be used while computing the 
  # majority vote law)
  predOOB <- lapply(predOOB, function(amatrix) {
    newmatrix <- amatrix
    newmatrix[is.na(newmatrix)] <- 0
    return(newmatrix)
  })
  # combine all predictions
  predOOB <- Reduce("+", predOOB)
  predOOB <- levels(simulated$y)[unlist(apply(predOOB, 1, which.max))]
  errOOB <- (predOOB != simulated$y[sel_ind])
  return(errOOB)
}, mc.cores = ncores)
errOOB <- sum(unlist(errOOB)) / nbobs
# errForest is: errOOB

##### Computing test error ----------------------------------------------------
print("computing test error...")
# loading and cleaning test data
simulated <- read_delim("alldata_test.txt", " ")
simulated <- as.data.frame(simulated)
simulated$y <- as.factor(simulated$y)
nbobs <- nrow(simulated)

# test error is computed sequentially
predTest <- lapply(simulated_mrrf, function(aforest)
  predict(aforest, simulated, type="vote")*nbtrees[ind])
predTest <- Reduce("+", predTest)
predTest <- levels(simulated$y)[unlist(apply(predTest, 1, which.max))]
errTest <- mean(predTest != simulated$y)
# Test error is: errTest