# -*- coding: utf-8 -*-
"""
Created on Thu Sep  5 12:12:04 2019

@author: beimx004
"""
import numpy as np
from scipy.signal import lfilter

def tdFilterFunc(par,x):
    nCh = par['coeffNum'].shape[0]
    Y = np.zeros((nCh,x.size))
    
    for iCh in np.arange(0,nCh):
        Y[iCh,:] = lfilter(par['coeffNum'][iCh,:],par['coeffDenom'][iCh,:],x)
        
    return Y
    
    