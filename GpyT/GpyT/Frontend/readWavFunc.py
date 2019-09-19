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
    
        
    if len(signalIn.shape) > 1:
        signalIn = signalIn[:,par['iChannel']-1]
    else:
        signalIn = signalIn
    
    
    
    if len(par['tStartEnd']) > 0:
        iStartEnd = np.round(par['tStartEnd']*srcFs+np.array([1,0]));
        signalIn = signalIn[iStartEnd[0]:iStartEnd[1]];
        
        
    if srcFs != stratFs:
        if len(signalIn.shape) > 1:
            for iCh in np.arange(signalIn.shape[0]):
                resampledSig[iCh,:] = resample(signalIn[iCh,:],stratFs,srcFs)
        else:
            signalIn = np.squeeze(resample(signalIn,stratFs,srcFs))
            
        
    print(signalIn.shape)
    return signalIn
    
        
    