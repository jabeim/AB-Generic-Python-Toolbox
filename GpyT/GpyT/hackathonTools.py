# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

import numpy as np


def electrodogramLengthCalc(inputLength,inputFs):
    outputFs = 55556
       
    # Import relevant values from demo4_procedural
    strat = {
        'wavFile' : 'Sounds/AzBio_3sent.wav',
        'fs' : 17400, # this value matches implant internal audio rate. incoming wav files resampled to match
        'nFft' : 256,
        'nHop' : 20,
        'nChan' : 15, # do not change
        # 'startBin' : 6,
        # 'nBinLims' : np.array([2,2,1,2,2,2,3,4,4,5,6,7,8,10,56]),
        # 'window' : stratWindow,   
        'pulseWidth' : 18, # DO NOT CHANGE
        # 'verbose' : 0
        }
    
    agc = {
       # 'parent' : parStrat,
       # 'kneePt' : 4.476,
       # 'compRatio' : 12,
       # 'tauRelFast' : -8/(17400*np.log(.9901))*1000,
       # 'tauAttFast' : -8/(17400*np.log(.25))*1000,
       # 'tauRelSlow' : -8/(17400*np.log(.9988))*1000,
       # 'tauAttSlow' : -8/(17400*np.log(.9967))*1000,
       # 'maxHold' : 1305,
       # 'g0' : 6.908,
       # 'fastThreshRel' : 8,
       # 'cSlowInit' : 0,
       # 'cFastInit' : 0,
       # 'controlMode' : 'naida',
       # 'clipMode' : 'limit',
       'decFact' : 8,
       'envBufLen' : 32,
       'gainBufLen' : 16,
       # 'envCoefs' : envCoefs    
           }
    
    
    
    # calculate changes in stimulus length during each processing step
    wavInFuncOutputLength = np.ceil(inputLength*(strat['fs']/inputFs))
    agcFuncOutputLength = wavInFuncOutputLength-(agc['envBufLen']-(agc['gainBufLen']+1))
    winBuffFuncOutputLength = np.ceil(agcFuncOutputLength/strat['nHop'])
    
    durStimCycle = 2*strat['pulseWidth']*strat['nChan']*1e-6
    
    ampWordsOutputLength = np.ceil(strat['nHop']/strat['fs']*winBuffFuncOutputLength/durStimCycle)-1
    
    elGramLength = np.floor(2*strat['nChan']*ampWordsOutputLength*(outputFs/(1/(strat['pulseWidth']*1e-6))))
    
    return elGramLength.astype(int)