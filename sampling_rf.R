##### Script description ------------------------------------------------------
# Script that trains a random forest on a subsample. The forest is trained in 
# parallel using ncores
# The script uses the packages 'readr', 'parallel' and 'randomForest'
##### -------------------------------------------------------------------------

library(readr)
library(parallel)
library(randomForest)

##### Set parameters ----------------------------------------------------------
propSample <- 1e-1 # sampling fraction
ncores <- 10 # number of cores used for training the forest
total_nbtrees <- 100 # total number of trees in the forest

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

# Sampling then building the forest (in parallel) -----------------------------
print("sampling...")
myTimeSampling <- system.time({
  # subsample in class Y=1 (half of the observations)
  mySample <- sample(which(simulated$y == 1),
                     round(0.5 * propSample * nrow(simulated)), 
                     replace = FALSE)
  # subsample in class Y != 1 (half of the observations)
  mySample <- c(mySample,
               sample(which(simulated$y != 1),
                      round(0.5 * propSample * nrow(simulated)),
                      replace = FALSE))
  # final subsample
  sampSimulated <- simulated[mySample, ]
})

print("training...")
nbtrees <- total_nbtrees/ncores
myTimeTrain <-system.time({
  rfSamp_simulated <- mclapply(1:ncores, function(ind) {
    res <- randomForest(y~., data=sampSimulated, ntree=nbtrees, maxnodes=500)
    return(res)
  }, mc.cores = ncores)
})

##### Computing errForest -----------------------------------------------------
print("computing training OOB errors...")
predOOB <- mclapply(1:ncores, function(ind) {
  # prediction (standard for out of subsample observations and OOB for subsample
  # observations)
  res <- predict(rfSamp_simulated[[ind]], simulated, type="vote")*nbtrees
  res[mySample, ] <- predict(rfSamp_simulated[[ind]], type="vote")*nbtrees
  return(res)
}, mc.cores = ncores)

# set to 0 all observations with NA (this will not be used while computing the 
# majority vote law)
predOOB <- mclapply(predOOB, function(amatrix) {
  newmatrix <- amatrix
  newmatrix[is.na(newmatrix)] <- 0
  return(newmatrix)
}, mc.cores = ncores)

# combine all predictions that were obtained in parallel
predOOB <- Reduce("+", predOOB)
predOOB <- levels(simulated$y)[unlist(apply(predOOB, 1, which.max))]
errOOB <- (predOOB != simulated$y)
errOOB <- sum(errOOB) / length(errOOB)
# BDerrForest is: errOOB

##### Computing BDerrForest ---------------------------------------------------
estOOB <- (predOOB != simulated$y)[mySample]
estOOB <-  sum(estOOB)/length(estOOB)
# BDerrForest is: estOOB

##### Computing test error ----------------------------------------------------
print("computing test error...")
# loading and cleaning test data
simulated <- read_delim("alldata_test.txt", " ")
simulated <- as.data.frame(simulated)
simulated$y <- as.factor(simulated$y)
nbobs <- nrow(simulated)

# test error is computed sequentially
predTest <- lapply(rfSamp_simulated, function(aforest) 
  predict(aforest, simulated, type="vote") * nbtrees[ind]
)
predTest <- Reduce("+", predTest)
predTest <- levels(simulated$y)[unlist(apply(predTest, 1, which.max))]
errTest <- mean(predTest != simulated$y)
# Test error is: errTest