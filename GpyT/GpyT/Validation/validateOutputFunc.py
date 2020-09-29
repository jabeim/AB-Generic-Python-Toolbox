# -*- coding: utf-8 -*-

import time
import numpy as np
import h5py
import warnings
import scipy.sparse as sparse
from scipy.io import loadmat



def validateOutputFunc(par,electrodogram,sourceFileName):
    # if a string is passed, load that datafile according to extension string
    if type(electrodogram) is str:
        # First load the validation file if it exists
        validationFileName = electrodogram[:electrodogram.rfind('_elGramOutput')]+'.mat' # grab validation file name based on beginning of input file name        
        try:
            defaultData = loadmat('Validation/'+validationFileName)
            assert defaultData['elData'].shape == electrodogram.shape,'Electrodogram shape does not match validation file. Expected: '+f"{defaultData['elData'].shape}"+', found '+f'{electrodogram.shape}'
        except FileNotFoundError:
            if par['skipValidation']:
                defaultData['elData'] = electrodogram  # if data flag for skipping validation files is set load an empty matrix (useful for processing non-official/unvalidated inputs)
                warnings.warn('No Validation file found! Validation process will be skipped, results may not be accepted for final entry submission!!')
            else:
                raise FileNotFoundError('Could not find validation file for '+sourceFileName[sourceFileName.rfind('/')+1:]+'. Expected to find '+'Validation/'+validationFileName)
        
        # Next check the filestring extension 
        if electrodogram[-3:] == '.h5':
            with h5py.File(electrodogram,'r') as f:
                if len(list(f.keys())) == 1:
                    electrodogram = np.array(f.get(list(f.keys())[0]))
                    if 16 in electrodogram.shape and len(electrodogram.shape) == 2:
                        if electrodogram.shape[0] == 16:
                            pass
                        else:
                            electrodogram = electrodogram.T
                    else:
                        #TODO can refine error message to specify exact sample number by comparing to loaded validation matrix size
                        raise ValueError('Electrodogram must be shape 16 x n, (16 electrodes x n total samples)') 
                else:
                    raise ValueError('HDF5 File contains multiple datasets. File should contain only the electrode pulse matrix.')
                f.close()
        elif electrodogram[-4:] == '.mat':
            rawData = loadmat(electrodogram)
            if 'elData' in rawData.keys():                 
                electrodogram = rawData['elData']            
                if type(electrodogram) is sparse.csc.csc_matrix:
                    electrodogram = electrodogram.A
                    if 16 in electrodogram.shape and len(electrodogram.shape) == 2:
                            if electrodogram.shape[0] == 16:
                                pass
                            else:
                                electrodogram = electrodogram.T
                    else:
                        #TODO can refine error message to specify exact sample number by comparing to loaded validation matrix size
                        raise ValueError('Electrodogram must be shape 16xn, (16 electrodes x n total samples)')
            else:
                raise KeyError('The supplied .mat file must contain data saved as "elData"')
        elif electrodogram[-4:] == '.npy':
            rawData = np.load(electrodogram);
            electrodogram = rawData
            if 16 in electrodogram.shape and len(electrodogram.shape) == 2:
                if electrodogram.shape[0] == 16:
                    pass
                else:
                    electrodogram = electrodogram.T
            else:
                #TODO can refine error message to specify exact sample number by comparing to loaded validation matrix size
                raise ValueError('Electrodogram must be shape 16xn, (16 electrodes x n total samples)')
            
        elif electrodogram[-4:] == '.npz':
            rawData = sparse.load_npz(electrodogram)
            electrodogram = rawData.A  
            if 16 in electrodogram.shape and len(electrodogram.shape) == 2:
                if electrodogram.shape[0] == 16:
                    pass
                else:
                    electrodogram = electrodogram.T
            else:
                #TODO can refine error message to specify exact sample number by comparing to loaded validation matrix size
                raise ValueError('Electrodogram must be shape 16xn, (16 electrodes x n total samples)')
            
            
        else:
            raise ValueError('Invalid File format: Only .npy, scipy sparse .npz, .h5, or .mat files are allowed')
    elif type(electrodogram) is np.ndarray:
        inputFileName = sourceFileName[sourceFileName.rfind('/')+1:sourceFileName.rfind('.wav')]
        validationFileName = inputFileName+'_validation.mat'
        try:
            defaultData = loadmat('Validation/'+validationFileName)
            assert defaultData['elData'].shape == electrodogram.shape,'Electrodogram shape does not match validation file. Expected: '+f"{defaultData['elData'].shape}"+', found '+f'{electrodogram.shape}'
        except FileNotFoundError:
            if par['skipValidation']:
                defaultData['elData'] = electrodogram  # if data flag for skipping validation files is set load an empty matrix (useful for processing non-official/unvalidated inputs)
                warnings.warn('No Validation file found! Validation process will be skipped, results may not be accepted for final entry submission!!')
            else:
                raise FileNotFoundError('Could not find validation file for '+sourceFileName[sourceFileName.rfind('/')+1:]+'. Expected to find '+'Validation/'+validationFileName)
        
        if 16 in electrodogram.shape:
            if electrodogram.shape[0] == 16:
                pass
            else:
                electrodogram = electrodogram.T
        else:
            #TODO can refine error message to specify exact sample number by comparing to loaded validation matrix size
            raise ValueError('Electrodogram must be shape 16xn, (16 electrodes x n total samples)')
    else:
        raise ValueError('Expected str or numpy ndarray inputs.')
    
    # validate type, shape, and sampling rate of elgram so that comparison with standard model can take place
    assert isinstance(electrodogram,np.ndarray), 'Electrodogram must be a numpy array'  # deprecate this
    assert len(electrodogram.shape)==2, 'Electrodogram must be a 2 dimensional array'   # deprecate this
    assert par['elGramRate'] == 55556, 'Electrodogram must be generated with 55556 Hz rate'
    
    # flip matrix so that rows = 16 if necessary
    if electrodogram.shape[0] != 16:  # this is redundant
        assert electrodogram.shape[1] == 16, 'Electrodogram dimensions should be: 16 x numSamples, currently: '+f'{electrodogram.shape}'
        electrodogram = electrodogram.T
       
    # load validation data for comparison
    # inputFileName = par['parent']['wavFile']
    inputFileName = sourceFileName[sourceFileName.rfind('/')+1:sourceFileName.rfind('.wav')]
    validationFileName = inputFileName+'_validation.mat'
    


        
    # calculate absolute differences between standard and test algorithm outputs
    outputDifference = np.sum(electrodogram-defaultData['elData'],axis=1).reshape(16,1)
    
    # Unless override is enabled, if any channel is not sufficiently different from the default algorithm produce a warning, otherwise save the output
    if par['saveWithoutValidation'] == True:
        if np.any(outputDifference < par['differenceThreshold']):
            channels = np.where(outputDifference < par['differenceThreshold'])[0]
            if len(channels) == 1:           
                warnings.warn('Channel ' + f'{channels}' ' is too similar to the default output.') 
            else:               
                warnings.warn('Channels ' + f'{channels}' ' are too similar to the default output.')
        
        # convert to csc sparse matrix for reduced file size
        data2save = sparse.csc_matrix(electrodogram,dtype=np.float)
        data2save.eliminate_zeros()
        
        # save in matlab compatible format for processing later
        if len(par['outFile']) == 0:
            # use timestamp format if no filename specified
            timestr = time.strftime("%Y%m%d_%H%M%S")
            sparse.save_npz('Output/'+inputFileName+'_elGramOutput_'+timestr,data2save)            
        else:
            sparse.save_npz('Output/'+inputFileName+'_elGramOutput_'+par['outFile'],data2save) 

               
        return False,True      
    elif par['saveWithoutValidation'] == False:
        channels = np.where(outputDifference < par['differenceThreshold'])[0]
        if len(channels) > par['maxSimilarChannels']:
            if len(channels) == 1:           
                warnings.warn('Channel ' + f'{channels}' ' is too similar to the default output. DATA NOT SAVED!') 
            else:               
                warnings.warn('Channels ' + f'{channels}' ' are too similar to the default output. DATA NOT SAVED!')
            return False,False 

        else:
            # convert to csc sparse matrix for reduced file size
            data2save = sparse.csc_matrix(electrodogram,dtype=np.float)
            data2save.eliminate_zeros()
            
            # save in matlab compatible format for processing later
            if len(par['outFile']) == 0:
                # use timestamp format if no filename specified
                timestr = time.strftime("%Y%m%d_%H%M%S") 
                sparse.save_npz('Output/'+inputFileName+'_elGramOutput_'+timestr,data2save)      
            else:
                sparse.save_npz('Output/'+inputFileName+'_elGramOutput_'+par['outFile'],data2save)
            return True,True
        
    
            

    
    