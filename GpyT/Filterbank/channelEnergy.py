# -*- coding: utf-8 -*-
"""
Created on Thu Sep  5 16:24:58 2019

@author: beimx004
"""
import numpy as np

def channelEnergyFunc(par,X,gAgc):
    strat = par['parent'];
    startBin = strat['startBin']-1 # subtract 1 for python indexing
    nBinLims = strat['nBinLims'];
    nHop = strat['nHop']
    
    nFrames = X.shape[1];
    nChan = nBinLims.size
    
    assert isinstance(gAgc,np.ndarray) or gAgc.size == 0,'gAgc, if supplied, must be a vector!'
    
    # determine if AGC is sample-based and deciimate to frame rate if necessary
    lenAgcIn = gAgc.shape[1]
    if lenAgcIn > nFrames:
        gAgc = gAgc[:,nHop-1:-1:nHop]
        assert np.abs(gAgc.shape[1]-nFrames) <= 3,'Length of sample-based gAgc input incompatable with nr. frames in STFT matrix: length/nHop must = approx nFrames.'
        if gAgc.size < nFrames:
            gAgc = np.concatenate((gAgc,gAgc[:,-1:]*np.ones((gAgc.shape[0],nFrames-gAgc.shape[1]))),axis=1);
            gAgc = gAgc[:,0:nFrames];
        elif lenAgcIn > 0 and lenAgcIn < nFrames:
            raise ValueError('Length of gAgc input incompatible with number of frames in STFT matrix: length must be >= nr. frames.')
        
    # compute roo-sum-squared FFT magnitudes per channel
    engy = np.zeros((nChan,nFrames))
    currentBin = startBin;
    for iChan in np.arange(nChan):
        currBinIdx = np.arange(currentBin,currentBin+nBinLims[iChan])
        engy[iChan,:] = np.sum(np.abs(X[currBinIdx,:])**2,axis=0)
        currentBin +=nBinLims[iChan]
        
    engy = np.sqrt(engy)
    
    # compensate AGC gain, if applicable
    if lenAgcIn > 0:
        if par['gainDomain'].lower() == 'linear' or par['gainDomain'].lower() == 'lin':
            pass
        elif par['gainDomain'].lower() == 'log' or par['gainDomain'].lower() == 'log2':
            gAgc = 2**(gAgc/2);
        elif par['gainDomain'].lower() == 'db':
            gAgc = 10**(gAgc/20);
        else:
            raise ValueError('Illegal value for parameter ''gainDomain''')
        gAgc = np.maximum(gAgc,np.finfo(float).eps)
        engy = np.divide(engy,gAgc)
        
    return engy
        