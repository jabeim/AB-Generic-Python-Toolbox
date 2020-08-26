# -*- coding: utf-8 -*-

import time
import numpy as np
import scipy.sparse as sparse
from scipy.io import loadmat



def validateOutputFunc(par,electrodogram):
    # if a string is passed, load that matfile, assuming data is already saved in sparse format with the appropriate structure
    if electrodogram is str:
        loaded = loadmat(electrodogram)
        electrodogram = loaded['elData'].A
    
    # validate type, shape, and sampling rate of elgram so that comparison with standard model can take place
    assert isinstance(electrodogram,np.ndarray), 'Electrodogram must be a numpy array'
    assert len(electrodogram.shape)==2, 'Electrodogram must be a 2 dimensional array'
    assert par['elGramRate'] == 55556, 'Electrodogram must be generated with 55556 Hz rate'
    
    # flip matrix so that rows = 16 if necessary
    if electrodogram.shape[0] != 16:
        assert electrodogram.shape[1] == 16, 'Electrodogram dimensions should be: 16 x numSamples, currently: '+f'{electrodogram.shape}'
        electrodogram = electrodogram.T
       
    # load validation data for comparison
    inputFileName = par['parent']['wavFile']
    validationFileName = inputFileName[inputFileName.rfind('/')+1:inputFileName.rfind('.wav')]+'_validation.mat'
    
    defaultData = loadmat('Validation/'+validationFileName)
    # calculate absolute differences between standard and test algorithm outputs
#    outputDifference = np.sum(np.abs(electrodogram-defaultData['elData'].A),axis=1)
    outputDifference = np.sum(electrodogram-defaultData['elData'],axis=1).reshape(16,1)
    
    # Unless override is enabled, if any channel is not sufficiently different from the default algorithm produce a warning, otherwise save the output
    if par['saveWithoutValidation'] == True:
        if np.any(outputDifference < par['differenceThreshold']):
            channels = np.where(outputDifference < par['differenceThreshold'])[0]
            if len(channels) == 1:           
                print('Channel ' + f'{channels}' ' is too similar to the default output.') 
            else:               
                print('Channels ' + f'{channels}' ' are too similar to the default output.')
        
        # convert to csc sparse matrix for reduced file size
        data2save = sparse.csc_matrix(electrodogram,dtype=np.float)
        data2save.eliminate_zeros()
        
        # save in matlab compatible format for processing later
        if len(par['outFile']) == 0:
            # use timestamp format if no filename specified
            timestr = time.strftime("%Y%m%d_%H%M%S")
            sparse.save_npz('Output/elGramOutput_'+timestr,data2save)            
        else:
            sparse.save_npz('Output/'+par['outFile'],data2save) 

               
        return True      
    elif par['saveWithoutValidation'] == False:
        channels = np.where(outputDifference < par['differenceThreshold'])[0]
        if len(channels) > par['maxSimilarChannels']:
            if len(channels) == 1:           
                print('Channel ' + f'{channels}' ' is too similar to the default output. DATA NOT SAVED!') 
            else:               
                print('Channels ' + f'{channels}' ' are too similar to the default output. DATA NOT SAVED!')
            return False 

        else:
            # convert to csc sparse matrix for reduced file size
            data2save = sparse.csc_matrix(electrodogram,dtype=np.float)
            data2save.eliminate_zeros()
            
            # save in matlab compatible format for processing later
            if len(par['outFile']) == 0:
                # use timestamp format if no filename specified
                timestr = time.strftime("%Y%m%d_%H%M%S") 
                sparse.save_npz('Output/elGramOutput_'+timestr,data2save)     
            else:
                sparse.save_npz('Output/'+par['outFile'],data2save) 
            return True
        
    
            

    
    