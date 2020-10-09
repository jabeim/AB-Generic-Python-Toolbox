# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 10:19:09 2019

@author: beimx004
"""

#[G_out, A_out, Vn, Vs, Hold] = noiseReductionFunc(par, A)
#
#Compute channel-by-channel noise reduction gains.
#
#INPUT:
#  par - parameter object / struct
#  A - nCh x nFrames matrix of channel amplitudes (sqrt(power), linearly scaled)
#
#OUTPUT:
#  G_out - nCh x nFrames matrix of noise reduction gains (domain determined by par.gainDomain)
#  A_out - nCh x nFrames matrix of channel amplitudes (sqrt(power), linearly scaled)
#  Vn   - nCh x nFrames matrix of noise estimates
#  Vs   - nCh x nFrames matrix of speech estimates
#  Hold - nCh x nFrames matrix of hold states
#
#FIELDS FOR PAR:
#  parent.fs   - audio sample rate [int > 0]
#  parent.nHop - FFT hop size [int > 0]
#  gainDomain - domain of gain output ['linear','db','log2'] ['linear']
#  tau_speech - time constant of speech estimator [s]
#  tau_noise - time constant of noise estimator [s]
#  threshHold - hold threshold (onset detection criterion) [dB, > 0]
#  durHold - hold duration (following onset) [s]
#  maxAtt - maximum attenuation (applied for SNRs <= snrFloor) [dB]
#  snrFloor - SNR below which the attenuation is clipped [dB]
#  snrCeil  - SNR above which the gain is clipped  [dB]
#  snrSlope - SNR at which gain curve is steepest  [dB]
#  slopeFact  - factor determining the steepness of the gain curve [> 0]
#  noiseEstDecimation - down-sampling factor (re. frame rate) for noise estimate [int > 0]
#  enableContinuous - save final state for next execution? [boolean]

import numpy as np


def nrGainFunc(par,gMin,SNR):
    SNR = np.minimum(np.maximum(SNR,par['snrFloor']),par['snrCeil'])
    g__ = gMin+np.divide((1-gMin),1+np.exp(-par['slopeFact']*(SNR-par['snrSlope'])));
    return g__


def noiseReductionFunc(par,A):
    from Utility.checkParamFields import checkParamFields
    # check input
    checkParamFields(par,['tau_speech','tau_noise','durHold','threshHold',
                          'maxAtt','snrFloor','snrCeil','snrSlope','slopeFact',
                          'noiseEstDecimation','enableContinuous','gainDomain'])
    
    strat = par['parent']
    initState = par['initState']
    noiseDS = par['noiseEstDecimation']
    dtFrame = strat['nHop']/strat['fs']
    
    nCh,nFrame = A.shape
    
    alpha_s = np.exp(-dtFrame/par['tau_speech'])
    alpha_n = np.exp(-dtFrame/par['tau_noise'])
    
    threshHold = par['threshHold']
    maxHold = par['durHold']/(dtFrame*noiseDS)
    maxAttLin = 10**(-np.abs(par['maxAtt'])/20)
    
    gMin = 1+(maxAttLin-1) /(1-1/(1+np.exp(-par['slopeFact']*(par['snrFloor']-par['snrSlope']))))
    
    G = np.empty((nCh,nFrame))
    Vs_out = np.empty((nCh,nFrame))
    Vn_out = np.empty((nCh,nFrame))
    Hold_out = np.empty((nCh,nFrame))
    
    logA = np.maximum(-100,20*np.log10(A))
    
    V_s = np.zeros(nCh)
    V_n = np.zeros(nCh)
    Hold = np.zeros(nCh,dtype=bool)
    HoldReady = np.ones(nCh,dtype=bool)
    HoldCount = np.zeros(nCh)+maxHold
    
    if len(par['initState']) > 0:
        if 'V_s' in par:
            V_s = par['initState']['V_s']
        if 'V_n' in par:
            V_n = par['initState']['V_n']
        if 'Hold' in par:
            Hold = par['initState']['Hold']
        if 'HoldReady' in par:
            HoldReady = par['initState']['HoldReady']
        if 'HoldCount' in par:
            HoldCount = par['initState']['HoldCount']

        
    for iFrame in np.arange(nFrame):
        V_s = alpha_s*V_s+(1-alpha_s)*logA[:,iFrame]
        if np.mod(iFrame-1,noiseDS) == noiseDS-1:
            maskSteady = (V_s-V_n) < threshHold;
            maskOnset = ~maskSteady & HoldReady;
            maskHold = ~maskSteady & ~HoldReady & Hold
            
            maskUpdateNoise = maskSteady | (~maskSteady & ~HoldReady & ~Hold)
            
            V_n[maskUpdateNoise] = alpha_n*V_n[maskUpdateNoise]+(1-alpha_n)*V_s[maskUpdateNoise]
            
            Hold[maskOnset] = True
            HoldReady[maskOnset] = False
            HoldCount[maskOnset] = maxHold
            
            
            
            HoldCount[maskHold] -= 1
            Hold[np.squeeze(maskHold & [HoldCount <= 0])] = False
            Hold[maskSteady] = False
            HoldReady[maskSteady] = True
            
        # compute gains
        SNR = V_s-V_n
        

        
        G[:,iFrame] = nrGainFunc(par,gMin,SNR)            
        Vn_out[:,iFrame] = V_n;
        Vs_out[:,iFrame] = V_s
        Hold_out[:,iFrame] = Hold

    # Apply Gains
    A_out = np.multiply(A,G);

    if par['gainDomain'].lower() == 'linear' or par['gainDomain'].lower() == 'lin':
        G_out = G
    elif par['gainDomain'].lower() == 'log' or par['gainDomain'].lower() == 'log2':
        G_out = 2*np.log2(G);
    elif par['gainDomain'].lower() == 'db':
        G_out = 20*np.log10(G);
    else:
        raise ValueError('Illegal value for parameter ''gainDomain''')
            
    if par['enableContinuous']:
        par['initState'] = {'V_s' : V_s,'V_n' : V_n,'Hold' : Hold,'HoldReady' : HoldReady,'HoldCount':HoldCount}

    return G_out,A_out,Vn_out,Vs_out,Hold_out
            
            
            
            
            
            
            
            
    
    
    

    



