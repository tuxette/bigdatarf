##### Script description ------------------------------------------------------
# Script that trains a random forest with Bag-of-Little-Bootstrap approach
# (blbRF). The forest is trained in parallel using ncores.
# The script uses the packages 'readr', 'parallel' and 'randomForest'.
# In addition, it uses function myrandomForest() in the script myrandomForest.R,
# which is a slight modification of the randomForest() function allowing
# bootstraping more observations than the total of observations given to the
# 'data' parameter of randomForest().
##### -------------------------------------------------------------------------

library(readr)
library(parallel)
library(randomForest)
source("myrandomForest.R")

##### Loading the data --------------------------------------------------------
myTimeLoad <- system.time({
  print("loading...")
  # reading the data...
  simulated <- read_delim("../data/alldata2.txt", " ")
  
  # cleaning the data
  print("cleaning...")
  simulated <- as.data.frame(simulated)
  simulated$y = as.factor(simulated$y)
})
nbobs <- nrow(simulated)

##### Set parameters ----------------------------------------------------------
sizesub <- floor(nbobs^0.7) # number of observations in each subsample
nbsub <- 10 # number of subsamples
nbboot <- 50 # number of bootstrap (and hence number of trees) in each subforest
ncores <- 10 # number of cores

##### Drawing subsamples and building the forest (in parallel)
print("training...")
indavail <- 1:nbobs
subsample <- vector("list", nbsub)
myTimeSubsampling <-system.time({
  for(j in 1:nbsub) {
    subsample[[j]] <- c(
      sample(rownames(simulated)[which(simulated$y[indavail]==1)],
             0.5*sizesub, replace = FALSE),
      sample(rownames(simulated)[which(simulated$y[indavail]!=1)],
             (1-0.5)*sizesub, replace = FALSE))
    indavail <- which(!(1:nbobs %in% unlist(subsample[1:j])))
  }
})
myTimeTrain <-system.time({
  blbrf <- mclapply(1:nbsub, function(j) {
    print(j)
    rf <- myrandomForest(y~., data = simulated[subsample[[j]], ],
                         ntree = nbboot, maxnodes = 500,
                         sampsize = nbobs, replace = TRUE)
  }, mc.cores = ncores)
})

##### Computing BDerrForest ---------------------------------------------------
print("computing OOB errors...")
myTimeBDErr <-system.time({
  estOOB <- sum(unlist(mclapply(1:nbsub, function(j) {
    indtest <- subsample[[j]]
    rftrain <- do.call("combine", blbrf[-j])
    err <- sum(simulated$y[indtest] != predict(rftrain, simulated[indtest, ]))
  }, mc.cores = ncores))) / (nbsub * sizesub)
})
# BDerrForest is: estOOB

##### Computing errForest -----------------------------------------------------
myTimeErrOOB <-system.time({
  errOOBloop <- mclapply(1:(nbsub+1), function(ind) {
    if (ind <= nbsub) {
      sel_ind = subsample[[ind]]
    } else {
      sel_ind <- which(!(1:nbobs %in% unlist(subsample)))
    }
    
    predOOB = lapply(blbrf, function(aforest)
      predict(aforest, simulated[sel_ind, ], type="vote")*nbboot)
    
    if (ind <= nbsub) {
      predOOB[[ind]] = predict(blbrf[[ind]], type="vote")*nbboot
      predOOB[[ind]][is.na(predOOB[[ind]])] = 0
    }
    
    predOOB = Reduce("+", predOOB)
    predOOB = levels(simulated$y)[unlist(apply(predOOB, 1, which.max))]
    errOOBlocal = (predOOB != simulated$y[sel_ind])
    return(errOOBlocal)
  }, mc.cores=ncores)
  errOOB = sum(unlist(errOOBloop))/nbobs
})
# errForest is: errOOB

##### Computing test error ----------------------------------------------------
print("computing test error...")
# loading and cleaning test data
simulated_test <- read_delim("../data/alldata_test.txt", " ")
simulated_test <- as.data.frame(simulated_test)
simulated_test$y = as.factor(simulated_test$y)
  
# test error is computed sequentially
myTimeTest <- system.time({
  predTest = lapply(blbrf, function(aforest)
    predict(aforest, simulated_test, type="vote")*nbboot)
  predTest = Reduce("+", predTest)
  
  predTest = levels(simulated_test$y)[unlist(apply(predTest, 1, which.max))]
  errTest = mean(predTest != simulated_test$y)
})
# Test error is: errTest