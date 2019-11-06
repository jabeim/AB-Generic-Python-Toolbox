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
    nChan = strat['nChan']
    nBinLims = strat['nBinLims']
    binToLoc = par['binToLocMap']
    startBin = strat['startBin']
    
    fftBinWidth = fs/nFft
    
    nBins,nFrames = stftIn.shape
    
    maxBin = np.zeros((nChan,nFrames),dtype=int)
    freqInterp = np.zeros((nChan,nFrames))
    loc = np.zeros((nChan,nFrames))
    binCorrection = np.zeros((1,nFrames))
    
    PSD = np.real(stftIn*np.conj(stftIn))/2
    PSD = np.maximum(PSD,10**(-120/20))
    

    
    currentBin = startBin-1  # account for matlab indexing
    
    for i in np.arange(nChan):
        currBinIdx = np.arange(currentBin,currentBin+nBinLims[i])      
        argMaxPsd = np.argmax(PSD[currBinIdx,:],axis=0)     
        maxBin[i,:] = currentBin+argMaxPsd
        currentBin+=nBinLims[i]
        
        
    for i in np.arange(nChan):        
        midVal = np.log2(PSD[maxBin[i,:],np.arange(nFrames)])
        leftVal = np.log2(PSD[maxBin[i,:]-1,np.arange(nFrames)])
        rightVal = np.log2(PSD[maxBin[i,:]+1,np.arange(nFrames)])               

        maxLeftRight = np.maximum(leftVal,rightVal)
        midIsMax = midVal > maxLeftRight
        
        binCorrection[:,midIsMax] = 0.5 * (rightVal[midIsMax]-leftVal[midIsMax])/(2*midVal[midIsMax]-leftVal[midIsMax]-rightVal[midIsMax])        
        binCorrection[:,~midIsMax] = 0.5*(rightVal[~midIsMax]==maxLeftRight[~midIsMax])-.5*(leftVal[~midIsMax]==maxLeftRight[~midIsMax])        

        freqInterp[i,:] = fftBinWidth * (maxBin[i,:]+binCorrection) # removing -1 to return same frequencies at matlab (because bin numbers are 1 off)
        deltaLocIdx = maxBin[i,:] + np.sign(binCorrection).astype(int)

        loc[i,:] = binToLoc[maxBin[i,:]]+binCorrection*np.abs(binToLoc[maxBin[i,:]]-binToLoc[deltaLocIdx])
        
    return freqInterp, loc
        
        
        