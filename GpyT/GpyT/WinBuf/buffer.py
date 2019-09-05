# -*- coding: utf-8 -*-
"""
Created on Thu Sep  5 15:40:17 2019

@author: beimx004
"""

def buffer(X, n, p=0):
    import numpy as np
    
    '''
    Parameters
    ----------
    x: ndarray
        Signal array
    n: int
        Number of data segments
    p: int
        Number of values to overlap
    
    Returns
    -------
    result : (n,m) ndarray
        Buffer array created from X
    '''
    
    d = n - p
    m = len(X)//d
    
    if m * d != len(X):
        m = m + 1
    
    Xn = np.zeros(d*m)
    Xn[:len(X)] = X
    
    Xn = np.reshape(Xn,(m,d))
    Xne = np.concatenate((Xn,np.zeros((1,d))))
    Xn = np.concatenate((Xn,Xne[1:,0:p]), axis = 1)
    
    return np.transpose(Xn[:-1])