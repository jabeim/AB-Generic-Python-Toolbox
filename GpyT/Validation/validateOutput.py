# -*- coding: utf-8 -*-
"""
# saved = validateOutputFunc(par,electrodogram,sourceFileName)
# 
# Validates electrodogram outputs based on contest rules by ensuring that:
#  1. electrodogram sampling rate is 55556 Hz
#  2. electrodogram contains 16 rows (channels)
#  3. electrodogram length matches the resampled source audio (within a small tolerance)
#  4. electrodogram channels are charge-balanced: abs(sum(channel)) < epsilon
# 
#  Validation also attempts to load a validation file containing the
#  electrodogram of the same stimulus preprocessed by the default strategy
#  for comparison. A warning is issued if no validation file is found, and
#  the similarity comparison process is skipped.
# 
#  A simple subtractive analysis of each channel is used to estimate the
#  similarity between elecdtrode channels using cross correllation to time
#  align the data.
# 
#  INPUT:
#   electrodogram - either a 16 x n matrix, where N is audioDuration*55556
#            samples, or a path to a .mat file containing the electrodogram data
#            saved as a variable 'elData'
#   sourceFileName - the name of the acoustic source file that generated the electrodogram as a string.
# 
#  KEYS FOR PAR:
#    parent['wavFile'] - the name of the source audio file being processed, ['Sounds\example.wav']
#    lengthTolerance - the number of samples difference allowable between validation and electrodogram array lengths, [15]
#    saveIfSimilar - whether or not to save the output matrix if similarity between electrodogram and default data is high, [bool]
#    differenceThreshold - max value for sum(abs(electrodogram-validationData)) in each channel, 
#                          channels are flagged as similar if the result is less than the threshold, [int]
#    maxSimilarChannels - maximum number of channels where the similarity exceeds the difference Threshold, [8]
#    elGramFs - the sampling frequency used to generate electrodogram; also stored in the parameters for f120ElectrodogramFunc
#                MUST BE SET TO 55556 Hz
#    outFile - optional filename to save the results somewhere else ".npz" will be appended if missing when outFile is a str, '' [str or file-like]
# 
#  OUTPUT:
#     saved - boolean indicating whether or not the data in electrodogram was saved to an output file, true [bool]
# 
"""
import time
from os import path

import pathlib
import numpy as np
import h5py
import warnings
import scipy.sparse as sparse
from scipy.io.wavfile import read as wavread
# from .validationTools import xCorrSimilarity
from scipy.io import loadmat, savemat




def validateOutputFunc(par,electrodogram,sourceFileName):
    
    lengthTol = par['lengthTolerance']
    # inputFileName = sourceFileName[sourceFileName.rfind('/')+1:sourceFileName.rfind('.wav')]
    inputFileName = path.splitext(path.split(sourceFileName)[1])[0]
    validationFileName = 'Validation/' + inputFileName+ '_validation.mat'
    
    
    skipMatrixSubtraction = False
    
    basepath = pathlib.Path(__file__).parent.parent.absolute()
    validationPath = (basepath / validationFileName).__str__()

    try:
        defaultData = loadmat(validationPath)
        if type(defaultData['elData']) is sparse.csc.csc_matrix:
            validationData = defaultData['elData'].A
        else:
            validationData = defaultData['elData']
            
        assert validationData.shape == electrodogram.shape,'Electrodogram shape does not match validation file. Expected: '+f"{validationData.shape}"+', found '+f'{electrodogram.shape}'
    except FileNotFoundError:
        
            validationData = electrodogram  # if data flag for skipping validation files is set load an empty matrix (useful for processing non-official/unvalidated inputs)
           
            warnings.warn('No Validation file found! Validation process will be skipped, results may not be accepted for final entry submission!!')
            [Fs,sourceData] = wavread(sourceFileName.__str__());
            validationData = np.zeros((16,np.fix(len(sourceData)/Fs*55556).astype(int)))
            skipMatrixSubtraction = True

         
    # if a string is passed, load that datafile according to extension string
    if type(electrodogram) is str:      
        # Check the filestring extension 
        if electrodogram[-3:] == '.h5':
            with h5py.File(electrodogram,'r') as f:
                if len(list(f.keys())) == 1:
                    electrodogram = np.array(f.get(list(f.keys())[0]))
                    f.close()
                else:
                    f.close()
                    raise ValueError('HDF5 File contains multiple datasets. File should contain only the electrode pulse matrix.')
        elif electrodogram[-4:] == '.mat':
            rawData = loadmat(electrodogram)
            if 'elData' in rawData.keys():                 
                electrodogram = rawData['elData']            
                if type(electrodogram) is sparse.csc.csc_matrix:
                    electrodogram = electrodogram.A
            else:
                raise KeyError('The supplied .mat file must contain data saved as "elData"')
        elif electrodogram[-4:] == '.npy':
            rawData = np.load(electrodogram);
            electrodogram = rawData            
        elif electrodogram[-4:] == '.npz':
            rawData = sparse.load_npz(electrodogram)
            electrodogram = rawData.A    
        else:
            raise ValueError('Invalid File format: Only .npy, scipy sparse .npz, .h5, or .mat files are allowed')
    elif type(electrodogram) is np.ndarray:      
        pass
    else:
        raise ValueError('Expected str or numpy ndarray inputs.')
    
    if len(electrodogram.shape) == 2:
        if 16 in electrodogram.shape:
            if electrodogram.shape[0] == 16:
                pass
            else:
                electrodogram = electrodogram.T
        else:
            raise ValueError('Electrodogram should have 16 channels (rows). Instead found: '+f'{electrodogram.shape[0]}')
    else:
        raise ValueError('Electrodogram should be a 2 dimensional array! Input shape: '+f'{electrodogram.shape}')

    
    
    # validate type, shape, and sampling rate of elgram so that comparison with standard model can take place
    if par['elGramFs']:
        assert np.round(par['elGramFs']) == 55556, 'Electrodogram must be generated with 55556 Hz rate'
        
    assert validationData.shape[1]-electrodogram.shape[1] <= lengthTol, 'Electrodogram should have approximately '+f'{validationData.shape[1]}'+' columns. (+-'+f'{lengthTol}'+') Instead contains: '+'f{electrodogram.shape[0]}'
    
    
    # validate that electrode matrix is charge balanced in each channel
    eps = np.finfo(float).eps
    chargeBalance = np.abs(np.sum(electrodogram,axis=1)) > eps
    
    if np.sum(chargeBalance) == 1:
       warnings.warn('Electrodogram is not charge-balanced! Channel output does not sum to zero for channel: '+f'{np.where(chargeBalance > 0)[0]}')
    elif np.sum(chargeBalance) > 1:
        warnings.warn('Electrodogram is not charge-balanced! Channel output does not sum to zero for channels: '+f'{np.where(chargeBalance > 0)[0]}')
        
     
    # compute cross-correlation based matrix subtraction to estimate channel similarity
    outputDifference = np.array([])
    if skipMatrixSubtraction == True:
        pass
    else:
        outputDifference = np.array([])
        if validationData.shape == electrodogram.shape:
            outputDifference = np.sum(np.abs(electrodogram-validationData),axis=1).reshape(16,1)
        else:
            pass
            # #cross-correlation based similarity comparison, doing this as in matlab is too slow!
            # for i in np.arange(validationData.shape[0]):            
            #     outputDifference[i] = xCorrSimilarity(validationData[i,:],electrodogram[i,:])

        

    
    # Unless override is enabled, if any channel is not sufficiently different from the default algorithm produce a warning, otherwise save the output
    if par['saveIfSimilar'] == True:
        if np.any(outputDifference < par['differenceThreshold']):
            channels = np.where(outputDifference < par['differenceThreshold'])[0]
            if len(channels) == 1:           
                print('Channel ' + f'{channels}' ' is very similar to the default output.') 
            else:               
                print('Channels ' + f'{channels}' ' are very similar to the default output.')
        
        # convert to csc sparse matrix for reduced file size
        data2save = sparse.csc_matrix(electrodogram,dtype=np.float)
        data2save.eliminate_zeros()

        # save in matlab compatible format for processing later
        if par['outFile'] is None:
            # use timestamp format if no filename specified
            timestr = time.strftime("%Y%m%d_%H%M%S")
            relativepath = 'Output/'+inputFileName+'_elGramOutput_'+timestr+'.npz'
            sparse.save_npz(basepath / relativepath,data2save)        
        else:
            sparse.save_npz(par['outFile'],data2save) 

               
        return True      
    elif par['saveIfSimilar'] == False:
        channels = np.where(outputDifference < par['differenceThreshold'])[0]
        if len(channels) > par['maxSimilarChannels']:
            if len(channels) == 1:           
                warnings.warn('Channel ' + f'{channels}' ' is very similar to the default output. DATA NOT SAVED!') 
            else:               
                warnings.warn('Channels ' + f'{channels}' ' are very similar to the default output. DATA NOT SAVED!')
            return False 

        else:
            # convert to csc sparse matrix for reduced file size
            data2save = sparse.csc_matrix(electrodogram,dtype=np.float)
            data2save.eliminate_zeros()
            
            # save in matlab compatible format for processing later
            if par['outFile'] is None:
                # use timestamp format if no filename specified
                timestr = time.strftime("%Y%m%d_%H%M%S") 
                relativepath = 'Output/'+inputFileName+'_elGramOutput_'+timestr+'.npz'
                sparse.save_npz(basepath / relativepath,data2save)
            else:
                sparse.save_npz(par['outFile'],data2save)
            return True
        
    
            

    
    