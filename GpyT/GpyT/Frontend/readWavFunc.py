# -*- coding: utf-8 -*-
"""
Created on Thu Sep  5 11:04:47 2019

@author: beimx004
"""
import numpy as np
from scipy.io.wavfile import read as wavread
from nnresample import resample


def readWavFunc(par):
    name = par['WavFile']
    stratFs = par['parent']['fs']
    
    srcFs,signalIn = wavread(name);
    
    signalIn = signalIn[:,par['iChannel']]
    
    if par['tStartEnd'].size() > 0:
        iStartEnd = np.round(par['tStartEnd']*srcFs+np.array([1,0]));
        signalIn = signalIn[iStartEnd[0]:iStartEnd[1]];
        
        
    if srcFs != stratFs:
        signalIn = resample(signalIn,stratFs,srcFs)
    return(signalIn)
    
        
    