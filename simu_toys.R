simu_toys <- function(n, p) {
##### Function description ----------------------------------------------------
# Function that generates the simulated data as described in 
# (Weston et al., 2003)
# The argument 'p' controls the distribution of the generated 'n' observations
# in the two submodels. In our experiments, 'p' was set to 0.7. 
# The data are then sequentially generated: the first pn observations from the 
# first submodel and the remaining observations from the second submodel.
##### -------------------------------------------------------------------------

  y <- 2 * rbinom(n, 1, 0.5) - 1
  x <- matrix(NA, n, p)
  q <- floor(7*n/10)
  z <- 1:q
  for (i in 1:3) {
    x[z, i] <- y[z] * rnorm(q, i, 1)
    x[-z, i] <- y[-z] * rnorm(n - q, 0, 1)
  }
  for (i in 4:6) {
    x[z, i] <- y[z] * rnorm(q, 0, 1)
    x[-z, i] <- y[-z] * rnorm(n - q, i - 3, 1)
  }
  x[, 7:p] <- rnorm(n*(p - 6), 0, 20)
  x <- scale(x)
  y <- as.factor(y)
  output <- data.frame('x' = x,'y' = y)
}

##### Data generation ---------------------------------------------------------
# The data are generated in parallel (with 15 cores) using the package
# 'parallel' with 15 cores (training) and 10 cores (test)
# 'n' was set to 15,000,000 for the training dataset and to 150,000 for the test
# dataset
# reproducibility is ensured through the definition of seeds
##### -------------------------------------------------------------------------

library(parallel)

## training dataset 'n' = 15,000,000
# define seeds for all cores
set.seed(2906) 
allseeds = round(runif(15)*5000)

# n = 15,000,000 => 1,000,000 observations in each of the 15 cores
alldata = mclapply(1:15, function(ind) {
  set.seed(allseeds[ind])
  simu_toys(1e6, 7)
}, mc.cores=15)

# merge all results
alldata = do.call("rbind", alldata)
# export (text format)
write.table(alldata, file="alldata2.txt", row.names=FALSE)

##### Data are permuted to avoid x-biais in MRRF (this part is not reproducible)
library(dplyr)
alldata <- arrange(alldata, y)
tab <- table(alldata$y)
nbone <- tab[2]
nbminusone <- tab[1]
prop <- rep(0.5, 15)
nbobs <- nrow(alldata)
sizechunk <- round(nbobs / 15)
nbonechunk <- floor(prop * sizechunk)
nbonechunk <- c(nbonechunk, nbone - sum(nbonechunk))
nbminusonechunk <- sizechunk - nbonechunk

permalldata <- alldata
for (ind in 1:nbchunks) {
  permalldata[(1 + sizechunk*(ind-1)):
                  (sizechunk*(ind-1) + nbonechunk[ind]), ] <-
    alldata[(1 + nbminusone + ifelse(ind > 1, cumsum(nbonechunk)[ind-1], 0)):
                (nbminusone + cumsum(nbonechunk)[ind]), ]
  permalldata[(1 + sizechunk*(ind-1) + nbonechunk[ind]):
                  (sizechunk*ind), ] <- 
    alldata[(1 + ifelse(ind > 1, cumsum(nbminusonechunk)[ind-1], 0)):
                cumsum(nbminusonechunk)[ind], ]
  permalldata[(1 + sizechunk*(ind-1)):(sizechunk*ind), ] <-
    sample_n(permalldata[(1 + sizechunk*(ind-1)):(sizechunk*ind), ],
             size = sizechunk)
}
# export (text format)
write.table(permalldata, file="alldata2_randperm.txt", row.names=FALSE)

## test dataset 'n' = 150,000
# define seeds for all cores
set.seed(1912) 
allseeds <- round(runif(10)*5000)

alldata <- mclapply(1:10, function(ind) {
  set.seed(allseeds[ind])
  simu_toys(1.5e4, 7)
}, mc.cores=10)

# merge all results
alldata <- do.call("rbind", alldata)
# export (text format)
write.table(alldata, file="alldata_test.txt", row.names=FALSE)
