# -*- coding: utf-8 -*-
"""
Created on Wed Sep 18 11:16:36 2019

@author: beimx004
"""
import numpy as np

def f120MappingFunc(par,carrier,env,weights,idxAudioFrame):
    strat = par['parent']
    M = par['mapM']
    T = par['mapT']
    IDR = par['mapIdr']
    gain = par['mapGain']
    mapClip = par['mapClip']
    chanToEl = par['chanToElecPair']
    carrierMode = par['carrierMode']
    
    nChan = strat['nChan']
    nFtFrames = len(idxAudioFrame)
    
    mSat = 30*10*np.log(2)/np.log(10)
    mapA = (M-T)/IDR
    mapK = M+(M-T)/IDR*(-mSat+12+gain)

    env = env*10*np.log(2)/np.log(10) 
    
    ampWords = np.zeros((30,nFtFrames))
    
    for iChan in np.arange(nChan):
        iElLo = chanToEl[iChan]
        iElHi = iElLo+1
        iAmpLo = iElLo*2    # remove+1 for 0 base indexing
        iAmpHi = iAmpLo+1
        if carrierMode == 0:
            mappedLo = mapA[iElLo]*env[iChan,idxAudioFrame]+mapK[iElLo]
            mappedHi = mapA[iElHi]*env[iChan,idxAudioFrame]+mapK[iElHi]
        elif carrierMode == 1:
            mappedLo = mapA[iElLo]*env[iChan,idxAudioFrame]*carrier[iChan,:]+mapK[iElLo]
            mappedHi = mapA[iElHi]*env[iChan,idxAudioFrame]*carrier[iChan,:]+mapK[iElHi]
        elif carrierMode == 2:
            mappedLo = (mapA[iElLo]*env[iChan,idxAudioFrame]+mapK[iElLo])*carrier[iChan,:]
            mappedHi = (mapA[iElHi]*env[iChan,idxAudioFrame]+mapK[iElHi])*carrier[iChan,:]
            
        mappedLo = np.maximum(np.minimum(mappedLo,mapClip[iElLo]),0)
        mappedHi = np.maximum(np.minimum(mappedHi,mapClip[iElHi]),0)
        
        ampWords[iAmpLo,:] = mappedLo*weights[iChan,idxAudioFrame]
        ampWords[iAmpHi,:] = mappedHi*weights[iChan+nChan,idxAudioFrame]
        
    return ampWords