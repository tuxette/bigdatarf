# -*- coding: utf-8 -*-
"""
Created on Tue Feb  7 16:37:03 2017

@author: Nathalie Villa-Vialaneix

"""

import sys
import argparse
sys.path.append("/opt/rftk/")
import rftk
import numpy as np
import time
import random

# argument definitions
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Online RF experiments')
    parser.add_argument('-x', '--input_x', type=str, required=True)
    parser.add_argument('-y', '--input_y', type=str, required=True)
    parser.add_argument('-t', '--number_of_trees', type=int, required=True)
    parser.add_argument('-d', '--max_depth', type=int, required=True)
    parser.add_argument('-s', '--sampling_rate', type=float, required=True)
    args = parser.parse_args()

## data importation and preparation
# training data importation
time_start = time.clock()
X_train = np.loadtxt(args.input_x)
Y_train = np.loadtxt(args.input_y)
time_elapsed = (time.clock() - time_start)
print("training data importation")
print(time_elapsed)
# training data preparation
X_train = np.array(X_train, dtype=np.float32)
Y_train = np.array(Y_train, dtype=np.int32)

# subsampling
if args.sampling_rate < 1:
    nbobs = X_train.shape[0]
    idxr = random.sample(range(nbobs), int(args.sampling_rate * nbobs))
    X_train = X_train[idxr, ]
    Y_train = Y_train[idxr, ]

# test data importation
X_test = np.loadtxt('../data/Xtest_alldata.txt')
Y_test = np.loadtxt('../data/Ytest_alldata.txt')
# test data preparation
X_test = np.array(X_test, dtype=np.float32)
Y_test = np.array(Y_test, dtype=np.int32)

## learning
# setting parameters
learner = rftk.learn.create_online_two_stream_consistent_classifier(
                            number_of_features=1,
                            number_of_trees=args.number_of_trees,
                            max_depth=args.max_depth,
                            number_of_splitpoints=10,
                            min_impurity=0.001,
                            number_of_data_to_split_root=1,
                            number_of_data_to_force_split_root=100,
                            split_rate_growth=1.1,
                            probability_of_impurity_stream=0.5,
                            max_frontier_size=50000)
# learning
time_start = time.clock()
predictor = learner.fit(x=X_train, classes=Y_train)
time_elapsed = (time.clock() - time_start)
print("computational time")
print(time_elapsed)

## result analysis
# training accuracy
Y_prob = predictor.predict(x=X_train)
Y_pred = Y_prob.argmax(axis=1)
accuracy = np.mean(Y_train == Y_pred)
print("training accuracy")
print(accuracy)

# test prediction
time_start = time.clock()
Y_prob = predictor.predict(x=X_test)
Y_pred = Y_prob.argmax(axis=1)
time_elapsed = (time.clock() - time_start)
print("computational time for prediction")
print(time_elapsed)

# test accuracy
test_accuracy = np.mean(Y_test == Y_pred)
print("test accuracy")
print(test_accuracy)

## misc
# forest stats
forest = predictor.get_forest()
stats = forest.GetForestStats()
print("average depth")
print(stats.GetAverageDepth())
print("mean depth")
print(stats.mMinDepth)
print("max depth")
print(stats.mMaxDepth)
print("number of leaves")
print(stats.mNumberOfLeafNodes)
