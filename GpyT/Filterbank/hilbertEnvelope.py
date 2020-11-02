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
    startBin = strat['startBin']-1;    # correcting for matlab base-1 indexing
    nBinLims = strat['nBinLims'];    # correcting for matlab base-1 indexing
    upperBound = par['outputUpperBound']
    lowerBound = par['outputLowerBound']
    

    Y = np.zeros(X.shape,dtype=complex);
    
    
    Y[np.arange(0,X.shape[0]-1,2),:] = -X[np.arange(0,X.shape[0]-1,2),:];
    
    Y[np.arange(0,X.shape[0]-1,2)+1,:] = X[np.arange(0,X.shape[0]-1,2)+1,:];
    

    

    L = Y.shape[1]
    env = np.zeros((nChan,L))
    envNoLog = np.zeros((nChan,L))
    currentBin = startBin; 
    
    numFullFrqBin = np.floor(nBinLims/4);
    numPartFrqBin = np.mod(nBinLims,4);
    logFiltCorrect = np.array([2233,952,62,0])/(2**10)
    
    logCorrect = logFiltCorrect+par['outputOffset']+16
    
    for i in np.arange(nChan):
        for j in np.arange(numFullFrqBin[i]):
            sr = np.sum(np.real(Y[currentBin:currentBin+4,:]),axis=0)
            si = np.sum(np.imag(Y[currentBin:currentBin+4,:]),axis=0)
            env[i,:] = env[i,:]+sr**2+si**2
            currentBin +=4 
        sr = np.sum(np.real(Y[currentBin:currentBin+numPartFrqBin[i],:]),axis = 0)
        si = np.sum(np.imag(Y[currentBin:currentBin+numPartFrqBin[i],:]),axis = 0)
        
        env[i,:] = env[i,:]+sr**2+si**2
        
        envNoLog[i,:] = env[i,:];
        env[i,:] = np.log2(env[i,:]);
        
        if nBinLims[i] > logCorrect.size-1:
            env[i,:] = env[i,:] +logCorrect[-1:]
        else:
            env[i,:] = env[i,:]+logCorrect[nBinLims[i]-1];   # correcting here for matlab base-1 indexing
        currentBin+= numPartFrqBin[i]
    
    ix = ~np.isfinite(env)
    env[ix] = 0;
    
    
    env = np.maximum(np.minimum(env,upperBound),lowerBound);
    return env
    