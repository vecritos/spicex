# -*- coding: utf-8 -*-
"""
Demo of 10-fold cross-validation using Gaussian naive Bayes on spam data

@author: Kevin S. Xu
"""

import numpy as np
import matplotlib.pyplot as pl
from sklearn.model_selection import cross_val_score
from sklearn.metrics import roc_auc_score,roc_curve
from sklearn.ensemble import RandomForestClassifier

def aucCV(features,labels):
    # Create the model with 100 trees
    model = RandomForestClassifier(n_estimators=100,
                                   bootstrap=True,
                                   max_features='sqrt')
    scores = cross_val_score(model, features, labels, cv=10,scoring='roc_auc')

    return scores

def predictTest(trainFeatures,trainLabels,testFeatures):
    # Create the model with 100 trees
    model = RandomForestClassifier(n_estimators=100,
                                   bootstrap=True,
                                   max_features='sqrt',
                                   class_weight={0:.5, 1:.5})
    model.fit(trainFeatures,trainLabels)

    # Use predict_proba() rather than predict() to use probabilities rather
    # than estimated class labels as outputs
    testOutputs = model.predict_proba(testFeatures)[:,1]

    return testOutputs

def tprAtFPR(labels,outputs,desiredFPR):
    fpr,tpr,thres = roc_curve(labels,outputs)
    # True positive rate for highest false positive rate < 0.01
    maxFprIndex = np.where(fpr<=desiredFPR)[0][-1]
    fprBelow = fpr[maxFprIndex]
    fprAbove = fpr[maxFprIndex+1]
    # Find TPR at exactly desired FPR by linear interpolation
    tprBelow = tpr[maxFprIndex]
    tprAbove = tpr[maxFprIndex+1]
    tprAt = ((tprAbove-tprBelow)/(fprAbove-fprBelow)*(desiredFPR-fprBelow)
             + tprBelow)
    return tprAt,fpr,tpr


# Run this code only if being used as a script, not being imported
if __name__ == "__main__":
    desiredFPR = 0.01

    data = np.loadtxt('spamTrain1.csv',delimiter=',')
    # Randomly shuffle rows of data set then separate labels (last column)
    shuffleIndex = np.arange(np.shape(data)[0])
    np.random.shuffle(shuffleIndex)
    data = data[shuffleIndex,:]
    features = data[:,:-1]
    labels = data[:,-1]
    
    # Evaluating classifier accuracy using 10-fold cross-validation
    print("10-fold cross-validation mean AUC: ", np.mean(aucCV(features,labels)))
    
    # Arbitrarily choose all odd samples as train set and all even as test set
    # then compute test set AUC for model trained only on fixed train set
    trainFeatures = features[0::2,:]
    trainLabels = labels[0::2]
    testFeatures = features[1::2,:]
    testLabels = labels[1::2]

    # Probabilities for each class
    testOutputs = predictTest(trainFeatures,trainLabels,testFeatures)

    # Calculate roc auc
    roc_value = roc_auc_score(testLabels, testOutputs)

    # testOutputs = predictTest(trainFeatures,trainLabels,testFeatures)
    print("Test set AUC: ", roc_auc_score(testLabels, testOutputs))
    
    # Examine outputs compared to labels
    sortIndex = np.argsort(testLabels)
    nTestExamples = testLabels.size
    pl.subplot(2,1,1)
    pl.plot(np.arange(nTestExamples),testLabels[sortIndex],'b.')
    pl.xlabel('Sorted example number')
    pl.ylabel('Target')
    pl.subplot(2,1,2)
    pl.plot(np.arange(nTestExamples),testOutputs[sortIndex],'r.')
    pl.xlabel('Sorted example number')
    pl.ylabel('Output (predicted target)')

    # From here down is TPR at FPR 1%
    tprAtDesiredFPR, fpr, tpr = tprAtFPR(testLabels, testOutputs, desiredFPR)

    pl.figure()
    pl.plot(fpr, tpr)

    print(f'Mean TPR at FPR = {desiredFPR}: {tprAtDesiredFPR}')
    pl.xlabel('False positive rate')
    pl.ylabel('True positive rate')
    pl.title('ROC curve for spam detector')
    pl.show()

    pl.show()
