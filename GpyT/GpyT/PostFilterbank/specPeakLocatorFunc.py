# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 15:22:02 2019

@author: beimx004
"""
import numpy as np

def specPeakLocatorFunc(par,stftIn):
    strat = par['parent']
    nFft = strat['nFft']
    fs = strat['fs']
    nBinLims = strat['nBinLims']
    binToLoc = par['binToLocMap']
    startBin = strat['startBin']
    
    fftBinWidth = fs/nfft
    
    nBins,nFrames = stftIn.shape
    
    maxBin = np.zeros((nChan,nFrames))
    freqInterp = np.zeros((nChan,nFrames))
    loc = np.zeros((nChan,nFrames))
    binCorrection = np.zeros((nChan,nFrames))
    
    PSD = np.real(stftIn*np.conj(stftIn))/2
    PSD = np.maximum(PSD,10**(-120/20))
    
    currentBin = startBin
    
    for i in np.arange(nChan):
        currBinIdx = np.arange(currentBin,currentBin+nBinLims[i])
        argMaxPsd = np.argmax(PSD[currBinIdx,:],axis=0)
        maxBin[i,:] = currentBin+argMaxPsd-1
        
    for i in np.arange(nChan):
        ind_m = np.ravel_multi_index(np.array([maxBin[i,:],np.arange(nFrames)]),PSD.shape)
    