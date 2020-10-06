# -*- coding: utf-8 -*-
"""
Created on Fri Oct  2 15:10:09 2020

@author: Jbeim
"""
import numpy as np
def xCorrSimilarity(x,y):

    
    if len(y) == len(x):
        print('length is the same')
    elif abs(len(y)-len(x)) > 0.01*max([len(x),len(y)]):
        ValueError('Array size difference exceeds tolerance! Make sure X and Y are the same length')
    elif len(y) > len(x):
        x = np.hstack((x,np.zeros((1,len(y)-len(x)))))
    else:
        y = np.hstack((y,np.zeros((1,len(x)-len(y)))))
        
    lags = np.arange(-(len(x)-1),len(x))
    r  = np.correlate(y,x,mode='full')
    
    peakInd = lags[np.argmax(np.abs(r))].astype(int)
    print(peakInd)
        
    if peakInd == 0:
        pass
    elif peakInd > 0:
        y = np.hstack((y[peakInd:],np.zeros((len(x)-len(y[peakInd:])))))
    else:
        x = np.hstack((x[np.abs(peakInd):],np.zeros(len(y)-len(x[np.abs(peakInd):]))))

          
    return np.sum(np.abs(x-y))
            