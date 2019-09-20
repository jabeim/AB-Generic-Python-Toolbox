# -*- coding: utf-8 -*-
"""
Created on Wed Sep  4 12:17:40 2019

@author: beimx004
"""
import numpy as np
from scipy import signal
from warnings import warn

def dualLoopTdAgcFunc(par,wavIn,*args):
#[wavOut GExpand State C CSlow CFast Hold Env G EnvFast] = dualLoopTdAgcFunc(par, wavIn, [ctrl])
#
#Apply the (single-channel) Harmony time-domain dual-loop AGC to input. 
#Implementation based on Teak model (agc17.c and agca.c) 
#
#INPUT:
#   wavIn - input waveform (max. range [-1,1])
#   ctrl  - (optional) additional "control" signal that is used to determine
#           the gain to be applied to wavIn; wavIn itself is used as control
#           is no other is explcitly provided          
#
#FIELDS FROM PAR: sampling frequency
#  parent.fs - audio sample rate
#  kneePt - compression threshold (in log2 power)
#  compRatio -  compression ratio above kneepoint (in log-log space)
#  tauRelFast - fast release [ms]
#  tauAttFast - fast attack [ms]
#  tauRelSlow - slow release [ms]
#  tauAttSlow - slow attack [ms]
#  maxHold - max. hold counter value
#  g0 - gain for levels < kneepoint  (log2)
#  fastThreshRel - relative threshold for fast loop [dB]
#  clipMode   - output clipping behavior: 'none' / 'limit' / 'overflow'
#  decFact    - decimation factor
#  envBufLen  - buffer length for envelope computation
#  gainBufLen - buffer length for gain smoothing
#  cSlowInit - initial value for slow averager, 0..1, [] for auto-scale to avg signal amp.
#  cFastInit - initial value for fast averager, 0..1, [] for auto-scale 
#  envCoefs - data window for envelope computation
#  controlMode - how to use control signal, if provided on port #2? [string]; 
#                  'naida'  - actual control signal is 0.75*max(abs(control, audio))
#                  'direct' - control signal is used verbatim without further processing
#
#OUTPUT:
#  wavOut - output waveform
#  G - gain vector (linear, sample-by-sample)
#  State - state vector (0: release, 1: hold,  2:slow attack, fast release,3:slow attack, fast attack)
#  C - vector of effective "input levels" 
#  CSlow - vector of slow averager values
#  CFast - vector of fast averager values
#  Hold - hold counter vector
#
#See also: DualLoopTdAgcUnit
#
#Change log:
#27/11/2012, P.Hehrmann - created
#14/01/2012, P.Hehrmann - renamed; 
#                         fixed: temporal alignment wavIn <-> gains (consistent with fixed-point GMT implementation / C model)
#01/06/2015, PH - adapted to May 2015 framework: removed shared props
#28/09/2015, PH - added 'auto' option for initial conditions
#01/Dec/2017, PH - add "controlMode" property
#14 Aug 2019, PH - swapped function arguments

    
    #check input dimensions
    assert isinstance(wavIn,np.ndarray),'wavIn must be a numpy array!'
    
    if len(args) == 0: # no explicit control provided, use audio
        ctrl = wavIn;
    else: # control signal is provided, use the specified control mode option
        assert isinstance(args[0],np.ndarray),'ctrl must be a numpy array!'
        ctrl = args[0];
        nSamp = np.min([wavIn.size, ctrl.size]);
        wavIn = wavIn[0:nSamp-1]
        if par['controlMode'].lower()  == 'naida':
            ctrl = ctrl[0:nSamp-1];
            ctrl = 0.75*np.maximum(np.abs(wavIn),np.abs(ctrl))
        elif par['controlMode'].lower() == 'direct':
            ctrl = ctrl[0:nSamp-1]
        else: 
            raise ValueError('Unknown control mode setting: ',par['controlMode'])
            
    # general parameters
    fs = par['parent']['fs'];
    decFact = par['decFact'];
    envBufLen = par['envBufLen'];
    gainBufLen = par['gainBufLen'];
    maxHold = par['maxHold'];
    c0_log2 = par['kneePt']-15;
    c0 = 2**c0_log2;
    g0 = par['g0']
    gainSlope = 1/par['compRatio']-1
    fastHdrm = 10**(-par['fastThreshRel']/20)
    envCoefs = par['envCoefs']
    
    
        
    # averaging weights
    bAttSlow = np.exp(-decFact/fs*1000/par['tauAttSlow'])
    bRelSlow = np.exp(-decFact/fs*1000/par['tauRelSlow'])
    bAttFast = np.exp(-decFact/fs*1000/par['tauAttFast'])
    bRelFast = np.exp(-decFact/fs*1000/par['tauRelFast'])
    
    nSamp = ctrl.size
   
    nFrame = np.ceil(nSamp/decFact).astype(int);
    
    # preallocation 
    Env = np.empty(nFrame);
    CSlow = np.empty(nFrame);
    CFast = np.empty(nFrame);
    C = np.empty(nFrame);
    G = np.empty(nFrame);
    Hold = np.empty(nFrame);
    State = np.empty(nFrame);
    EnvFast = np.empty(nFrame);
    # inital conditions
    cSlow_i = par['cSlowInit']
    if not cSlow_i:
        cSlow_i = np.min((1,np.mean(np.abs(ctrl))*np.sum(envCoefs)))
    cFast_i = par['cFastInit']
    if not cFast_i:
        cFast_i = np.min([1,np.mean(np.abs(ctrl))*np.sum(envCoefs)*fastHdrm])
    cFastLowLimit_i = cFast_i;
    hold_i = 0;
    
    # loop over blocks
    for iFrame in np.arange(nFrame):
        idxWav = iFrame+1*decFact+np.arange(-(envBufLen-1),0)-1;
        idxWav = idxWav[idxWav>=0];
        idxWav = idxWav[idxWav <=nSamp];
        
        # compute envelope
        env_i = np.sum(np.abs(ctrl[idxWav])*envCoefs[-idxWav.size:]);
        envFast_i = clip1(env_i*fastHdrm);
        # update envelope averagers
        if env_i > cSlow_i:
            fastThr_i = clip1(cSlow_i*10**(8/20));
            if env_i > fastThr_i:
                deltaHold = 0
                cFast_i = track(cFast_i,envFast_i,bAttFast);
                state_i = 3
            else:
                deltaHold = 2;
                cFastLowLimit_i = cSlow_i*10**(-10/20);
                cFast_i = track(cFast_i,envFast_i,bRelFast);
                state_i = 2;
            cSlow_i = track(cSlow_i,min((env_i,fastThr_i)),bAttSlow)
        elif hold_i == 0:
            deltaHold = 0;
            cFastLowLimit_i = cSlow_i*10**(-10/20)
            cFast_i = track(cFast_i,envFast_i,bRelFast);
            cSlow_i = track(cSlow_i,env_i,bRelSlow);
            state_i = 0;
        else:
            deltaHold = -1;
            cFastLowLimit_i = cSlow_i*10**(-10/20);
            cFast_i = track(cFast_i,envFast_i,bRelFast);
            state_i = 1;
            
        hold_i = min((hold_i+deltaHold,maxHold))
        
        cSlow_i = max((cSlow_i,c0));
        cFast_i = max((cFast_i,cFastLowLimit_i))
        
        c_i = max((cFast_i,cSlow_i));
        
        c_i_log2 = np.log2(max((c_i,10**-16)));
        g_i = 2**(g0+gainSlope*max((c_i_log2-c0_log2,0)));

        G[iFrame] = g_i;
        
        Env[iFrame] = env_i;
        C[iFrame] = c_i;
        CSlow[iFrame] = cSlow_i;
        CFast[iFrame] = cFast_i;
        Hold[iFrame] = hold_i;
        State[iFrame] = state_i;
        EnvFast[iFrame] = envFast_i;
    
    # apply gain
    
    
    idxExpand = np.concatenate((np.ceil(np.arange(1/decFact,nFrame+1/decFact,1/decFact)),np.array([nFrame]))).astype(int)
    GExpand = G[idxExpand-1];
    GExpand = signal.lfilter(np.ones(gainBufLen)/gainBufLen,1,GExpand)
    
    GExpand = GExpand[1:nSamp+2-gainBufLen];
    
    wavOut = np.concatenate((np.zeros(envBufLen),wavIn[gainBufLen:nSamp-envBufLen+1]))*GExpand
    
    if par['clipMode'].lower() == 'none':
        pass
    elif par['clipMode'].lower() == 'limit':
        wavOut = np.maximum(-1,np.minimum(1,wavOut));
    elif par['clipMode'].lower() == 'overflow':
        wavOut = np.mod(1+wavOut,2)-1
    else:
        warn('Unknown clipping mode: '+par['clipMode']+' . Using ''none'' instead.')
        
    return wavOut,GExpand,State,C,CSlow,CFast,Hold,Env,G,EnvFast
#        return wavOut,GExpand
    
    
def track(C_prev,In,weightPrev):
    weightIn = 1-weightPrev
    C_out = In*weightIn+C_prev*weightPrev;
    return C_out
    
def clip1(In):
    out = np.max([-1,np.min([1,In])])
    return out