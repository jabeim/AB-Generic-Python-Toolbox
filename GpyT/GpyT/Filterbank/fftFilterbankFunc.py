# -*- coding: utf-8 -*-
"""
Created on Thu Sep  5 15:44:51 2019

@author: beimx004
"""
import numpy as np

def fftFilterbankFunc(par,buf):
    nFft = par['parent']['nFft']
    X = np.fft.fft(buf,nFft,axis=0)
       
    if par['combineDcNy']:
        NF = X[nFft//2+1,:];
        DC = X[0,:];
        X[0,:] = (np.real(DC)+np.real(NF))+1j*(np.real(DC)-np.real(NF));
        X[nFft//2+1,:] = 0;
        
    if par['includeNyquistBin']:
        X = X[0:nFft//2+1,:];
    else:
        X = X[0:nFft//2,:];
        
    if par['compensateFftLength']:
        X = X/(nFft/2)
    
    return X