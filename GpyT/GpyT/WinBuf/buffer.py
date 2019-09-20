# -*- coding: utf-8 -*-
"""
Created on Thu Sep  5 15:40:17 2019

@author: beimx004
"""

def buffer(X, n, p=0,opt=None):
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
    
    
    if 0 < p & p < n:  # overlapping buffer, pad with p zeros at the beginning
        if opt is None:
            opt = np.zeros((p))
            Xb = np.concatenate((opt,X))
        elif len(opt) == 0:
            Xb = X
        elif opt == 'nodelay':
            Xb = X
        else:
            Xb = np.concatenate((opt,X))           
    elif p < 0: # underlapping buffer (skips samples), skip opt samples if provided
        if opt is None:
            Xb = X
        elif len(opt) == 0:
            Xb = X
        elif opt == 'nodelay':
            raise ValueError('"bufOpt" must not be set to no delay if p < 0')            
        else:
            Xb = X[opt:]
    else:
        raise ValueError('p cannot be greater than n!')
        
    
    N = n;
    M= np.ceil(len(X)/(n-p)).astype(int);
    
    print(N,M)
    b = np.zeros((N,M))
    print(b.shape)
    print(Xb.dtype)
    
    for i in np.arange(n,dtype=int):
        
        if i == 0:
            a = 0
            b = 6712
            b[i,:] = Xb[a:b]
        else:
            a= i*M-i*p
            b = (i+1)*M-(i+1)*p
            b[i,:] = Xb[i*M-p:(i+1)*M-p]    
    
    
    
  