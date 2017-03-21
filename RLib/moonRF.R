##### Script description ------------------------------------------------------
# Script that trains a random forest with the m-out-of-n bootstrap approach
# (moonRF). The forest is trained in parallel using ncores.
# The script uses the packages 'readr', 'parallel' and 'randomForest'
##### -------------------------------------------------------------------------

library(readr)
library(parallel)
library(randomForest)

##### Set parameters ----------------------------------------------------------
propSample <- 1e-4 # fraction of the total number of observations used to
# build subsamples
nbtrees <- 100 # number of trees in the forest
ncores <- 10 # number of cores

##### Loading the data --------------------------------------------------------
myTimeLoad <- system.time({
  print("loading...")
  # reading the data...
  simulated <- read_delim("alldata2.txt", " ")
  
  # cleaning the data
  print("cleaning...")
  simulated <- as.data.frame(simulated)
  simulated$y <- as.factor(simulated$y)
})
  
##### Drawing subsamples and building the forest (in parallel) -----------------
print("training...")
myTimeTrain <-system.time({
  moonRF <- mclapply(1:nbtrees, function(ind) {
    if (ind <= nbtrees/2) {
      mySample = sample(which(simulated$y==1),
                        round(unbalance_prop*propSample*nrow(simulated)), FALSE)
      mySample = c(mySample,
                   sample(which(simulated$y!=1),
                          round((1-unbalance_prop)*propSample*nrow(simulated)), FALSE))
    }
    else {
      mySample = sample(which(simulated$y!=1),
                        round(unbalance_prop*propSample*nrow(simulated)), FALSE)
      mySample = c(mySample,
                   sample(which(simulated$y==1),
                          round((1-unbalance_prop)*propSample*nrow(simulated)), FALSE))
    }
    sampSimulated = simulated[mySample, ]
    res = randomForest(y~., data=sampSimulated, ntree=1, maxnodes=500,
                       replace=FALSE, sampsize=nrow(sampSimulated))
    return(list(forest=res, mySample=mySample))
  }, mc.cores=ncores)
})

##### Computing BDerrForest ---------------------------------------------------
print("computing OOB errors...")
myTimeBDErr <- system.time({
  allSamples <- lapply(moonRF, "[[", 2)
  allUnique <- unique(unlist(allSamples))
  nbofUnique <- length(allUnique)
  predOOB = mclapply(1:nbtrees, function(ind) {
    OOBvotes <- matrix(0, ncol = 2, nrow = nbofUnique)
    rownames(OOBvotes) <- sort(allUnique)
    OOBunique <- sort(unique(unlist(allSamples[-ind])))
    OOBvotes[which(rownames(OOBvotes) %in% OOBunique),] = predict(moonRF[[ind]]$forest, simulated[OOBunique,], type="vote")
    return(OOBvotes)
  }, mc.cores=ncores)
  predOOB = Reduce("+", predOOB)
  predOOB = levels(simulated$y)[unlist(apply(predOOB, 1, which.max))]
  estOOB = (predOOB != simulated[sort(allUnique),]$y)
  estOOB = sum(estOOB)/length(estOOB)
})
# BDerrForest is: estOOB

##### Computing errForest -----------------------------------------------------
# errForest is computed sequentially
myTimeErrOOB <- system.time({
  predOOB = lapply(1:nbtrees, function(ind) {
    print(ind)
    res = predict(moonRF[[ind]]$forest, simulated, type="vote")
    res[moonRF[[ind]]$mySample,] = 0
    return(res)
  })
  predOOB = Reduce("+", predOOB)
  predOOB = levels(simulated$y)[unlist(apply(predOOB, 1, which.max))]
  errOOB = (predOOB != simulated$y)
  errOOB = sum(errOOB)/length(errOOB)
})
# errForest is: errOOB

##### Computing test error ----------------------------------------------------
print("computing test error...")
# loading and cleaning test data
simulated <- read_delim("alldata_test.txt", " ")
simulated <- as.data.frame(simulated)
simulated$y <- as.factor(simulated$y)
nbobs <- nrow(simulated)

# test error is computed in parallel
myTimeTest <- system.time({
  predTest = mclapply(1:nbtrees, function(ind) {
    predict(moonRF[[ind]]$forest, simulated_test, type="vote")},
    mc.cores = ncores)
  predTest = Reduce("+", predTest)
  
  predTest = levels(simulated_test$y)[unlist(apply(predTest, 1, which.max))]
  errTest = mean(predTest != simulated_test$y)
})
# Test error is: errTest