# -*- coding: utf-8 -*-
"""
Created on Mon Oct 14 13:29:42 2019

@author: beimx004
"""

import numpy as np

from scipy.signal import lfilter
from scipy.interpolate import interp1d

def f120ElectrodogramFunc(par,ampIn):
    strat = par['parent']
    fsOut = par['outputFs']
    # rOut = par['resistance']
    nFrameFt = ampIn.shape[1]
    nChan = strat['nChan']
    pulseWidth = strat['pulseWidth']
    phasesPerCyc = 2*nChan
    dtIn = phasesPerCyc*pulseWidth*1e-6
    durIn = nFrameFt*dtIn
    chanOrder = par['channelOrder']
    
    assert nChan == 15, 'only 15-channel strategies are supported.'
    assert chanOrder.shape[0] == nChan,'length(channelOrder) must match nChan'
    
    
    nFrameOut = nFrameFt*phasesPerCyc
    
    
    idxLowEl = np.arange(nChan)
    idxHighEl = np.arange(nChan)+1
    nEl = 16
    
    
    elGram = np.zeros((nEl,nFrameOut))
    
    for iCh in np.arange(nChan):
        phaseOffset = 2*(chanOrder[iCh]-1)
        elGram[idxLowEl[iCh],phaseOffset::phasesPerCyc] = ampIn[2*iCh,:]
        elGram[idxHighEl[iCh],phaseOffset::phasesPerCyc] = ampIn[2*iCh+1,:]
        
    if par['cathodicFirst']:
        kernel = np.array([-1,1])
    else:
        kernel = np.array([1,-1])
        
    elGram = lfilter(kernel,1,elGram)
    
    if fsOut:
        dtOut = 1/fsOut
        tPhase = np.arange(nFrameOut)*pulseWidth*1e-6
        tOut = np.arange(np.floor(durIn/dtOut))*dtOut
        fElGram = interp1d(tPhase,elGram,kind='previous',fill_value='extrapolate')
        elGram = fElGram(tOut);
    else:
        tOut = np.arange(nFrameOut)*pulseWidth*1e-6
        
    # if rOut:
    #     elGram = elGram*1e-6*rOut
        
    # lets skip the step of making the elGram sparse first
    
    if par['enablePlot']:
        # skipping figure generation for now
        pass
        
    return elGram
            
        