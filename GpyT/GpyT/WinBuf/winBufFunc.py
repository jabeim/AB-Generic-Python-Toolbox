# -*- coding: utf-8 -*-
"""
Created on Thu Sep  5 12:17:46 2019

@author: beimx004
"""

import numpy as np
from .buffer import buffer

def winBufFunc(par,signalIn):
    
    strat = par['parent']   
    [M,N] = signalIn.shape
    
    
    if N>M:
        signalIn = signalIn.T;
        N = M;
        
#    signalIn = (np.arange(signalIn.size)+1).reshape(signalIn.shape)    
    
    b = buffer(signalIn[:,0],strat['nFft'],strat['nFft']-strat['nHop'],par['bufOpt'])  
    b = b*strat['window'].T
#    if N > 1
#        temp = b;
#        b = np.zeros((b.shape[0],b.shape[1],N))
#        b[:,:,0] = temp
#        for n in np.arange(1,N):
#            b[:,:,n] = buffer(signalIn[:,n],strat['nFft'],strat['nFft']-strat['nHop'],par['bufOpt'])
#            b[:,:,n] = np.multiply(b[:,:,n],strat['window'].T)


#    N = signalIn.size
#    b = buffer(signalIn,strat['nFft'],strat['nFft']-strat['nHop'],par['bufOpt'])
#    b = np.multiply(b,strat['window'].T)
#        b = b*strat['window'].T
    
#    b = b.squeeze()  # remove singleton dimension
    return b