# -*- coding: utf-8 -*-
"""
Created on Wed Sep 18 10:28:16 2019

@author: beimx004
"""

import numpy as np

def currentSteeringWeightsFunc(par,loc):
    nChan = par['parent']['nChan']
    nSteps = par['nDiscreteSteps']
    
    assert np.isscalar(nSteps) & np.mod(nSteps,1) == 0, 'nSteps must be an integer scalar.'
    
    steeringRange = par['steeringRange']
    
    if np.isscalar(steeringRange):
        steeringRange = 0.5+0.5*steeringRange*np.concatenate((-np.ones((1,nChan)),np.ones((1,nChan))))
    elif len(steeringRange) > 1:
        assert len(steeringRange) == nChan, 'Length of vector "steeringRange" must equal # of channels.'
        steeringRange = 0.5+0.5*np.concatenate((-steeringRange,steeringRange))
        
    assert steeringRange.shape[1] == nChan & steeringRange.shape[0] == 2, 'Matrix "steeringRange" must have dimensions 2xnChan.'
    assert np.all(steeringRange >= 0) & np.all(steeringRange <= 1), 'Values in "steeringRange" must lie in [0,1]'
    assert np.all(np.diff(steeringRange,axis=0)), 'range[:,2] >= range[:,1] must be true for all channels'
    
    nFrames = loc.shape[1]
    weights = np.zeros(nChan*2,nFrames)
    
    for iCh in np.arange(nChan):
        weightHiRaw = np.max([np.min([loc[iCh,:]-iCh+1,1]),0])
        
        if nSteps == 1:
            weightHiRaw = 0.5
        elif nSteps > 1:
            weightHiRaw = np.round(weightHiRaw*(nSteps-1)/(nSteps-1))
            
        weightHi = steeringRange[1,iCh]+weightHiRaw*np.diff(steeringRange[:,iCh])

        weights[iCh,:] = 1-weightHi
        weights[iCh+nChan,:] = weightHi
        
    return weights