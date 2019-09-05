# -*- coding: utf-8 -*-
"""
Created on Thu Sep  5 16:24:58 2019

@author: beimx004
"""
import numpy as np

def channEnergyFunc(par,X,gAgc):
    strat = par['parent'];
    startBin = strat['startBin']
    nBinLims = strat['nBinLims'];
    nHop = strat['nHop']
    
    nFrames = X.shape[1];
    nChan = nBinLims.size
    
    assert isinstance(gAgc,np.ndarray) or gAgc.size == 0,'gAgc, if supplied, must be a vector!'
    
    # determine if AGC is sample-based and deciimate to frame rate if necessary
    lenAgcIn = gAgc.size
    if lenAgcIn > nFrames:
        gAgc = gAgc[np.arange(nHop,lenAgcIn,nHop)]
        assert np.abs(gAgc.size-nFrames) <= 2,'Length of sample-based gAgc input incompatable with nr. frames in STFT matrix: length/nHop must = approx nFrames.'
        if gAgc.size < nFrames:
            gAgc = np.concatenate(gAgc,gAgc[-1]*np.ones(nFrames-gAgc.size));
            gAgc = gAgc[0:nFrames];
        elif lenAgcIn > 0 and lenAgcIn < nFrames:
            raise ValueError('Length of gAgc input incompatible with number of frames in STFT matrix: length must be >= nr. frames.')
            