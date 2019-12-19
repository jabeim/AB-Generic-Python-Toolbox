# -*- coding: utf-8 -*-

import numpy as np
from scipy.io import loadmat, savemat
from scipy.sparse import csc_matrix as sparse


def validateOutputFunc(par,electrodogram):
    assert isinstance(electrodogram,np.ndarray), 'Electrodogram must be a numpy array'
    assert len(electrodogram.shape)==2, 'Electrodogram must be a 2 dimensional array'
    assert par['elGramRate'] == 200e3, 'Electrodogram must be generated with 200 kHz rate'
    
    
    if electrodogram.shape[0] != 16:
        assert electrodogram.shape[1] == 16, 'Electrodogram dimensions should be: 16 x numSamples, currently: '+f'{electrodogram.shape}'
        electrodogram = electrodogram.T
    
    
    # load validation data for comparison
    
    
#    defaultData = loadmat('')
#    outputDifference = np.sum(electrodogram-defaultData['elgram'],axis=1)
    
    outputDifference = np.ones((16,1))*1000
    
#    outputDifference[4,:] = 0;
    
    
    # If any channel is not sufficiently different from the default algorithm produce a warning, otherwise save the output
    if np.any(outputDifference < par['differenceThreshold']):
        channels = np.where(outputDifference < par['differenceThreshold'])[0]
        if len(channels) > 1:           
            print('Channel ' + f'{channels}' ' is too similar to the default output. DATA NOT SAVED!') 
        else:               
            print('Channels ' + f'{channels}' ' are too similar to the default output. DATA NOT SAVED!')
        return False 
    else:
        # convert to csr sparse matrix
        data2save = sparse(electrodogram)
        
        # save in matlab compatible format for processing later
        savemat('tempPy',{'elData' : data2save})
        return True
        
    
            
        
        
    
    