# -*- coding: utf-8 -*-
"""
Created on Thu May  9 14:32:18 2019

@author: Jbeim
"""

import numpy as np
import scipy as sp
from numba import jit
from pathlib import Path


#@jit('float64[:,:](float64[:,:],float64[:,:],float64[:,:],float64[:,:],float64[:,:],float64,float64,int32,int32,int32,int32)',nopython=True)
#def NeurToAudio(elData,normRamp,normOffset,mNeurToBin,audioPwr,alpha,mAvg,nAvg,playOverAvgRatio,blkSize,nFFT):
##    audioPwr = np.zeros((nNeuralLocs,blkSize+1))
#    
#    shLen = nFFT+(playOverAvgRatio-1)*nAvg
#    stateHolder = np.zeros(shLen)
#    shli = np.int(0)
#    sH2 = np.zeros(shLen)
#    nl = 5
#    phs = 2*np.pi*np.random.rand(np.floor(nFFT/2).astype(int32))
#    dphi = 2*np.pi*np.arange(1,np.floor(nFFT/2)+1)*nAvg/nFFT
#    audioOut = np.array([])
#    
#    for blkNumber in range(1,np.floor(elData.shape[1]/blkSize.astype(int))+1):
#        timeIdx = np.arange((blkNumber-1)*blkSize+1,blkNumber*blkSize+1,dtype=int)-1
#        efData = np.dot(normRamp,elData[:,timeIdx])        
#        efData = (efData.T-normOffset).T
#        electricField = np.maximum(0,efData)
#        activity = np.maximum(0,np.minimum(np.exp(-nl+nl*electricField),1)-np.exp(-nl))/(1-np.exp(-nl))
#        audioPwr = ActivityToPower(alpha,activity,audioPwr,blkSize)
#        energy = np.sum(audioPwr,axis = 1)/mAvg        
#        spect = np.multiply(np.dot(mNeurToBin,energy),np.exp(1j*phs))
#        
#        scl = 1
#        if np.mod(nFFT,2) == 1:
#            sgn = np.multiply(scl*(nFFT/2)*win,np.real(np.fft.ifft(np.concatenate((np.array([0]),spect,np.conj(spect[::-1]))))))
#        else:
#            sgn = np.multiply(scl*(nFFT/2)*win,np.real(np.fft.ifft(np.concatenate((np.array([0]),spect,np.conj(spect[spect.size-2::-1]))))))
#        
#        shWin = np.arange(shli,shli+nFFT)
#        stateHolder[shWin] = stateHolder[shWin]+sgn 
#        shli = shli+nAvg
#        phs = np.mod(phs+dphi,2*np.pi)
#        shWin2 = np.arange(0,playOverAvgRatio*nAvg)
#        if not(np.mod(blkNumber,playOverAvgRatio)):          
#            audioOut = np.append(audioOut,1*stateHolder[shWin2])       
#            stateHolder = np.concatenate((stateHolder[playOverAvgRatio*nAvg:None],np.zeros(playOverAvgRatio*nAvg)))
#            sH2 = np.concatenate((sH2[playOverAvgRatio*nAvg:None],np.zeros(playOverAvgRatio*nAvg)))
#            shli = np.int(0)
#        
#        
#        
#    
#    return audioOut
    
@jit('float64[:,:](float64,float64[:,:],float64[:,:],int32)',nopython = True)
def ActivityToPower(alpha,activity,audioPwr,blkSize):

    for k in np.arange(blkSize):
        audioPwr[:,k+1] = np.maximum(audioPwr[:,k]*alpha+activity[:,k]*(1-alpha),activity[:,k])            
    audioPwr[:,0] = audioPwr[:,blkSize]
    
    return audioPwr

@jit('float64[:,:](float64[:,:],float64[:,:],int64,float64)',nopython = True)
def ElFieldToActivity(efData,normOffset,nl,nlExp):
               
    efData = (efData-normOffset)
    electricField = np.maximum(0,efData)
    electricField = electricField / 0.4 * 0.5
#    activity = np.maximum(0,np.minimum(np.exp(-nl+nl*electricField),1)-nlExp)/(1-nlExp)  
    activity = np.maximum(0,np.minimum(np.exp(nl*electricField),nlExp)-1)/(nlExp-1)
    return activity
        
def NeurToBinMatrix(neuralLocsOct,nFFT,Fs):
     
    fGrid = np.arange(0,np.floor(nFFT/2)+1)*(Fs/nFFT)
    fBinsOct = np.log2(fGrid[1:])
    
    binCountPerOct = np.divide(1,np.diff(fBinsOct))
    x = np.ones((2,np.floor(nFFT/2).astype(int)-1))
    x[1,:] = np.arange(1,np.floor(nFFT/2),1)
##    x = np.append(a1,a2,axis=1)
#    coef = np.linalg.solve(x,binCountPerOct)
#    scl = coef[0]+coef[1]*10**(neuralLocsOct/20)
    
    nNeuralLocs = len(neuralLocsOct)
    mNeurToBin = np.zeros((np.floor(nFFT/2).astype(int),nNeuralLocs))
    
    I = np.zeros(nNeuralLocs)
    for k in np.arange(len(neuralLocsOct)):
        tmp = np.abs(fBinsOct-neuralLocsOct[k])
        I[k] = np.argmin(tmp)
        mNeurToBin[I[k].astype(int),k] = 1
    
    basepath = Path(__file__).parent.parent.absolute()    
    pFN = basepath / 'MatlabSupportFiles/preemph.mat'
    emph = sp.io.loadmat(pFN)
    
    I = np.argmax(emph['emphDb'])
    emph['emphDb'][I+1:] = emph['emphDb'][I]
    emphDb = -emph['emphDb']
    emphDb= emphDb-emphDb[0]
    
    scl = np.interp(
            np.arange(1,np.floor(nFFT/2)+1)*Fs/nFFT,
            np.append(0,emph['emphF']),
            np.append(0,emphDb)
            )
    
    mNeurToBin = np.multiply(mNeurToBin.T,10**(scl/20))
    mNeurToBin = np.nan_to_num(mNeurToBin).T
    
    return mNeurToBin

def generate_cfs(lo, hi, n_bands):
    """
    Generates a series of 'bands' frequencies in Hz, linearely distributed
    on an ERB scale between the frequencies 'lo' and 'hi' (in Hz).
    These would are the centre frequencies (on an ERB scale) of the bands
    specifications made by 'generate_bands' with the same arguments
    """  
    
    density = n_bands / (hz2erb(hi) - hz2erb(lo))
    bands = []
    for i in np.arange(1, n_bands + 1):
        bands.append(erb2hz(hz2erb(lo) + (i - 0.5) / density))
    return bands


def erb2hz(erb):
    """
    Convert equivalent rectangular bandwidth (ERB) to Hertz.
    """
    tmp = np.exp((erb - 43.) / 11.17)
    return (0.312 - 14.675 * tmp) / (tmp - 1.0) * 1000.

def hz2erb(hz):
    """
    Convert Hertz to equivalent rectangular bandwidth (ERB).
    """
    return 11.17 * np.log((hz + 312.) / (hz + 14675.)) + 43.