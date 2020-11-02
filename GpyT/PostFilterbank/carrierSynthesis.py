# -*- coding: utf-8 -*-
"""
Created on Wed Sep 18 11:02:24 2019

@author: beimx004
"""

import numpy as np

def carrierSynthesisFunc(par,fPeak):
    strat = par['parent']
    nChan = strat['nChan']
    nFrame = fPeak.shape[1]
    fs = strat['fs']
    pw = strat['pulseWidth']
    
    durFrame = strat['nHop']/fs
    durStimCycle = 2*pw*nChan*1e-6
    rateFt = np.round(1/durStimCycle)
    
    nFtFrame = np.ceil(durFrame*nFrame/durStimCycle)-1
    tFtFrame = np.arange(nFtFrame)*durStimCycle
    
    idxAudFrame = (np.floor(tFtFrame/durFrame)).astype(int) # +1 removed for 0 based indexing
    fPeakPerFtFrame = fPeak[:,idxAudFrame]
    
    deltaPhiNorm = np.minimum(fPeakPerFtFrame/rateFt,par['deltaPhaseMax'])
    phiNorm = np.mod(np.cumsum(deltaPhiNorm,axis=1),1)
    
    maxMod = par['maxModDepth']
    fModOn = rateFt*par['fModOn']
    fModOff = rateFt*par['fModOff']
    modDepth = maxMod*(fModOff-np.minimum(np.maximum(fPeakPerFtFrame,fModOn),fModOff))/(fModOff-fModOn)
    
    carrier = 1-(modDepth*(phiNorm < 0.5))
    
    tFtFrame = idxAudFrame
    
    return carrier,tFtFrame