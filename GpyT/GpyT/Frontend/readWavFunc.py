# -*- coding: utf-8 -*-
"""
Created on Thu Sep  5 11:04:47 2019

@author: beimx004
"""
import numpy as np
from scipy.io.wavfile import read as wavread
from nnresample import resample


def readWavFunc(par):
    name = par['wavFile']
    stratFs = par['parent']['fs']
    
    [srcFs,signalIn] = wavread(name);
    # rescale from integer words to float for audio processing
    
    if signalIn.dtype == 'uint8':
        raise TypeError('8 bit PCM wav format not supported')
    elif signalIn.dtype == 'int16':
        bits = 16
        maxBit = 2.**(bits-1)
    elif signalIn.dtype == 'int32':
        bits = 32 
        maxBit = 2.**(bits-1)
    elif signalIn.dtype == 'float32':  # dont rescale 32bit float data
        maxBit = 0;
        
    signalIn = signalIn/(maxBit+1) 
    
        
    if len(signalIn.shape) > 1:
        signalIn = signalIn[:,par['iChannel']-1]
    else:
        signalIn = signalIn
    
    
    
    if len(par['tStartEnd']) > 0:
        iStartEnd = np.round(par['tStartEnd']*srcFs+np.array([1,0]));
        signalIn = signalIn[iStartEnd[0]:iStartEnd[1]];
        
    
    
    if srcFs != stratFs:
        if len(signalIn.shape) > 1:
            resampledSig = np.zeros((signalIn.shape[0],np.round(stratFs*signalIn.shape[1]/srcFs)))
            for iCh in np.arange(signalIn.shape[0]):
                resampledSig[iCh,:] = resample(signalIn[iCh,:],stratFs,srcFs)
        else:
            signalIn = np.squeeze(resample(signalIn,stratFs,srcFs))
            
        
    
    return signalIn
    
        
    