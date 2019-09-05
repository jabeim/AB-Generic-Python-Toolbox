# -*- coding: utf-8 -*-
"""

[env, envNoLog] = hilbertEnvelopeFunc(par, X)
INPUT
  - par: parameter object/struct
  - X : short-time fft coefficient matrix, nFreq x nFrames

FIELDS FOR PAR:
  - outputOffset : scalar offset added to all channel outputs [log2]
  - parent.nChan : number of analysis channels
  - parent.startBin  : lowest fft-bin of the lowest analysis channel 
  - parent.nBinLims  : number of FFT bins per analysis channel

OUTPUT:
  - env : hilbert envelopes, one row per channel

Change log:
2012, MM - created
24/11/2014, PH - removed mandatory "scale" argument
08/01/2015, PH - renamed extractEnvelopeFunc -> hilbertEnvelopeFunc  
29/05/2015, PH - adapted to May 2015 framework: shared props removed
17/07/2019, PH - added par.outputOffset, removed scale input entirely,
                 cleaned up / explained log correction constant

05/09/2019, JB - initial python port
"""
import numpy as np

def hilbertEnvelopeFunc(par,X):
    
    strat = par['parent'];
    nChan = strat['nChan'];
    startBin = strat['startBin'];
    nBinLims = strat['nBinLims'];
    upperBound = par['outputUpperBound']
    lowerBound = par['outputLowerBound']
    
    X[np.arange(0,X.shape[1],2),:] = -X[np.arange(0,X.shape[1],2),:];
    L = X.shape[1]
    env = np.zeros((nChan,L))
    envNoLog = np.zeros((nChan,L))
    currentBin = startBin;
    
    numFullFrqBin = np.floor(nBinLims/4);
    numPartFrqBin = np.mod(nBinLims,4);
    logFiltCorrect = np.array([2233,952,62,0])/(2**10)
    
    logCorrect = logFiltCorrect+par['outputOffset']+16
    
    for i in np.arange(nChan-1):
        for j in np.arange(numFullFrqBin[i]-1):
            sr = np.sum(np.real(X[np.arange(currentBin,currentBin+4),:]))
            si = np.sum(np.imag(X[np.arange(currentBin,currentBin+4),:]))
            env[i,:] = env[i,:]+sr**2+si**2
            currentBin +=4 
        sr = np.sum(np.real(X[np.arange(currentBin,currentBin+numPartFrqBin[i]),:]))
        si = np.sum(np.imag(X[np.arange(currentBin,currentBin+numPartFrqBin[i]),:]))
        env[i,:] = env[i,:]+sr**2+si**2
        envNoLog[i,:] = env[i,:];
        env[i,:] = np.log2(env[i,:]);
        
        if nBinLims[i] > 4:
            env[i,:] = env[i,:] +logCorrect[4]
        else:
            env[i,:] = env[i,:]+logCorrect[nBinLims[i]];
        currentBin+= numPartFrqBin[i]
    ix = ~np.isfinite(env)
    env[ix] = 0;
    
    env = np.maximum(np.minimum(env,upperBound),lowerBound);
    return env
    