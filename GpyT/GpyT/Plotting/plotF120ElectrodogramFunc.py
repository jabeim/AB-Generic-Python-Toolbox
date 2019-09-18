# -*- coding: utf-8 -*-
"""
Created on Wed Sep 18 11:29:37 2019

@author: beimx004
"""

import numpy as np
import matplotlib.pyplot as plt

def plotF120ElectrodogramFunc(par,amps):
    
    if ~par['enable']:
        handles = {}
        return handles
    
    strat = par['parent']
    nChan = strat['nChan']
    
    M = np.max(amps)
    amps = amps/(2*M+0.01)
    
    units = par['timeUnits'].lower()
    
    if units == 's' | units == 'sec':
        timeFactor = 1e-6
        timeLabel = 's'
    elif units == 'ms':
        timeFactor = 1e-3
        timeLabel = 'ms'
    elif units == 'us' | units == 'mus':
        timeFactor = 1
        timeLabel  = r'$\mu\s'
    else:
        raise ValueError('Unknown value for timeUnits; should be s,ms, or us; current value: ', par['timeUnits'])
        
    strat = par['parent']
    
    nElec = 16
    nAmpChannels = 30
    nPulseSamples = amps.shape[1]
    pDur = 2*strat['pulseWidth']*timeFactor
    frameDur = pDur*nChan
    stimDur = nPulseSamples*pDur*nChan
    pairOffs = par['pairOffset']
    
    
    # create a figure using matplotlib.pyplot (similar to matlab conventions)
    
    hFig = plt.figure()
    hAx = plt.axes()
    
#    xTick = np.arange(0,stimDur+par['xTickInterval'],par['xTickInterval'])
    
    timeFrameStart = np.arange(0,stimDur,frameDur)
    
    # pre-allocate empty list-of-lists to replace matlab cell
    tPulse = [[] for i in range(nElec)]
    ampPulse = [[] for i in range(nElec)]
    hLines = [[] for i in range(nElec)]

    
    for iCh in np.arange(1,nAmpChannels+1):
        iPair = np.ceil(iCh/2)
        timeOffset = pairOffs[iPair]*pDur
        iEl = np.floor(iCh/2)
        
        nonZeroInd = amps[iCh,:] != 0
        
        if np.all(nonZeroInd == False):
            nonZeroInd = 1
            
        tPulse[iEl] = np.concatenate((tPulse[iEl],timeFrameStart[nonZeroInd]+timeOffset))
        ampPulse[iEl] = np.concatenate((ampPulse[iEl],amps[iCh,nonZeroInd]))
        
    for iEl in np.arange(nElec):
        
        # not sure why NANs are attached to this
        nanMatrix = np.zeros(ampPulse[iEl].shape)
        nanMatrix.fill(np.nan)
        
        xx = np.repeat(tPulse[iEl],3,axis = 0)        
        yy = np.concatenate((iEl+np.zeros(ampPulse[iEl].shape),iEl+ampPulse[iEl],nanMatrix))
        
        hLines[iEl] = plt.plot(np.concatenate((xx,stimDur,0)),np.concatenate((yy,iEl,iEl)))
    
    
    xlab = plt.xlabel('Time [%s]' % timeLabel)
    ylab = plt.ylabel('Electrode')
    
    handles = {'hFig' : hFig,'hAx' : hAx,'hLines' : hLines,'hXLabel' : xlab,'hYLabel' : ylab}

    return handles