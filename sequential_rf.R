##### Script description ------------------------------------------------------
# Script that trains a random forest on sequential data and obtain OOB and 
# test errors
# The script uses the packages 'readr','parallel' and 'randomForest'
##### -------------------------------------------------------------------------

library(readr)
library(randomForest)

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

##### Building the forest (sequentially...) -----------------------------------
print("training...")
myTimeTrain <-system.time({
  rfseq_simulated <- randomForest(y~., data=simulated, ntree=100, maxnodes=500)
})
# OOB error is: rfseq_simulated$err.rate[100]

##### Computing test error ----------------------------------------------------
print("computing test error...")
# loading and cleaning test data
simulated <- read_delim("alldata_test.txt", " ")
simulated <- as.data.frame(simulated)
simulated$y <- as.factor(simulated$y)
nbobs <- nrow(simulated)

# test error is computed in parallel (10 cores)
library(parallel)
test_seq <- mclapply(1:ncores, function(ind) {
  indexes <- ((ind-1)*nbobs/ncores+1):(ind*nbobs/ncores)
  predTest <- predict(rfseq_simulated, simulated[indexes, ], type="vote")
  predTest <- levels(simulated$y)[unlist(apply(predTest, 1, which.max))]
  errTest <- sum(predTest != simulated$y[indexes])
  return(errTest)
}, mc.cores = 10)
test_seq <- sum(unlist(test_seq))/nbobs
# Test error is: test_seq