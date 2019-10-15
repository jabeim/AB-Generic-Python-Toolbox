# -*- coding: utf-8 -*-
"""
Created on Wed Sep 18 14:55:51 2019

@author: beimx004
"""
# Import necessary functions
import numpy as np
from scipy.io import loadmat
import matplotlib.pyplot as plt

from Frontend.readWavFunc import readWavFunc

from Frontend.readMatFunc import readMatFunc

from Frontend.tdFilterFunc import tdFilterFunc
from Agc.dualLoopTdAgcFunc import dualLoopTdAgcFunc
from WinBuf.winBufFunc import winBufFunc
from Filterbank.fftFilterbankFunc import fftFilterbankFunc
from Filterbank.hilbertEnvelopeFunc import hilbertEnvelopeFunc
from Filterbank.channelEnergyFunc import channelEnergyFunc
from Clearvoice.clearvoiceFunc import clearvoiceFunc
from PostFilterbank.specPeakLocatorFunc import specPeakLocatorFunc
from PostFilterbank.currentSteeringWeightsFunc import currentSteeringWeightsFunc
from PostFilterbank.carrierSynthesisFunc import carrierSynthesisFunc
from Mapping.f120MappingFunc import f120MappingFunc
#from Plotting.plotF120ElectrodogramFunc import plotF120ElectrodogramFunc
from Electrodogram.f120ElectrodogramFunc import f120ElectrodogramFunc



def demo3_procedural():
    
    matWindow = loadmat('C:/Users/beimx004/Documents/GitHub/hackathon_simulator/GpyT/GpyT/WinBuf/windowData.mat')
    stratWindow = matWindow['winData'].T
    
#    stratWindow = 0.5*(np.blackman(256)+np.hanning(256))
#    stratWindow = stratWindow.reshape(1,stratWindow.size)
    
    parStrat = {
            'fs' : 17400,
            'nFft' : 256,
            'nHop' : 20,
            'nChan' : 15,
            'startBin' : 6,
            'nBinLims' : np.array([2,2,1,2,2,2,3,4,4,5,6,7,8,10,56]),
            'window' : stratWindow,
            'pulseWidth' : 18,
            'verbose' : 0
            }
    
    parReadWav = {
            'parent' : parStrat,
            'wavFile' : 'C:/Users/beimx004/Documents/GitHub/hackathon_simulator/GpyT/GpyT/Sounds/AzBio_3sent.wav',
            'tStartEnd' : [],
            'iChannel' : 1,
            }
    
    parPre = {
            'parent' : parStrat,
            'coeffNum' : np.array([.7688, -1.5376, .7688]),
            'coeffDenom' : np.array([1, -1.5299, .5453]),
            }
    
    parAgc = {
            'parent' : parStrat,
            'kneePt' : 4.476,
            'compRatio' : 12,
            'tauRelFast' : -8/(17400*np.log(.9901))*1000,
            'tauAttFast' : -8/(17400*np.log(.25))*1000,
            'tauRelSlow' : -8/(17400*np.log(.9988))*1000,
            'tauAttSlow' : -8/(17400*np.log(.9967))*1000,
            'maxHold' : 1305,
            'g0' : 6.908,
            'fastThreshRel' : 8,
            'cSlowInit' : 0,
            'cFastInit' : 0,
            'controlMode' : 'naida',
            'clipMode' : 'limit',
            'decFact' : 8,
            'envBufLen' : 32,
            'gainBufLen' : 16,
            'envCoefs' : np.array([-19,55,153,277,426,596,784,983,
                                   1189,1393,1587,1763,1915,2035,2118,2160,
                                   2160,2118,2035,1959,1763,1587,1393,1189,
                                   983,784,596,426,277,153,55,-19])/2**16
    }
    
    parWinBuf = {
            'parent' : parStrat,
            'bufOpt' : []
            }
    
    parFft = {
            'parent' : parStrat,
            'combineDcNy' : False,
            'compensateFftLength' : False,
            'includeNyquistBin' : False
            }
    
    parHilbert = {
            'parent' : parStrat,
            'outputOffset' : 0,
            'outputLowerBound' : 0,
            'outputUpperBound' : np.inf
            }
    
    parEnergy = {
            'parent' : parStrat,
            'gainDomain' : 'linear'
            }
    
    parClearVoice = {
            'parent' : parStrat,
            'gainDomain' : 'log2',
            'tau_speech' : .0258,
            'tau_noise' : .219,
            'threshHold' : 3,
            'durHold' : 1.6,
            'maxAtt' : -12,
            'snrFloor' : -2,
            'snrCeil' : 45,
            'snrSlope' : 6.5,
            'slopeFact' : 0.2,
            'noiseEstDecimation': 1,
            'enableContinuous' : False,
            'initState' : [],
            }
    
    parPeak = {
            'parent' : parStrat,
            'binToLocMap' : np.concatenate((np.zeros(6,),np.array([256, 640, 896, 1280, 1664, 1920, 2176,       # 1 x nBin vector of nominal cochlear locations for the center frequencies of each STFT bin
                                            2432, 2688, 2944, 3157, 3328, 3499, 3648, 3776, 3904, 4032,         # as in firmware; values from 0 .. 15 (originally in Q9 format)
                                            4160, 4288, 4416, 4544, 4659, 4762, 4864, 4966, 5069, 5163,         # corresponding to the nominal steering location for each 
                                            5248, 5333, 5419, 5504, 5589, 5669, 5742, 5815, 5888, 5961,         # FFT bin
                                            6034, 6107, 6176, 6240, 6304, 6368, 6432, 6496, 6560, 6624, 
                                            6682, 6733, 6784, 6835, 6886, 6938, 6989, 7040, 7091, 7142, 
                                            7189, 7232, 7275, 7317, 7360, 7403, 7445, 7488, 7531, 7573, 
                                            7616, 7659]),7679*np.ones((53,))))/512
    }
    
    parSteer = {
            'parent' : parStrat,
            'nDiscreteSteps' : 9,
            'steeringRange' : 1.0
            }
    
    parCarrierSynth = {
            'parent' : parStrat,
            'fModOn' : .5,
            'fModOff': 1.0,
            'maxModDepth' : 1.0,
            'deltaPhaseMax' : 1.0
            }
    
    parMapper = {
            'parent' : parStrat,
            'mapM' : 500*np.ones(16),
            'mapT' : 100*np.ones(16),
            'mapIdr' : 60*np.ones(16),
            'mapGain' : 0*np.ones(16),
            'mapClip' : 2048*np.ones(16),
            'chanToElecPair' : np.arange(16),   
            'carrierMode' : 1
            }
    
#    parPlotter = {
#            'parent' : parStrat,
#            'pairOffset' : np.array([1,5,9,13,2,6,10,14,3,7,11,15,4,8,12])-1,
#            'timeUnits' : 'ms',
#            'xTickInterval' : 250,
#            'pulseColor' : 'r',
#            'enable' : True
#            }
    
    parElectrodogram = {
            'parent' : parStrat,
            'cathodicFirst' : True,
            'channelOrder' : np.array([1,5,9,13,2,6,10,14,3,7,11,15,4,8,12]),
            'colorScheme' : 4,
            'enablePlot' : True,
            'outputFs' : 200e3,
            'resistance' : 10e3
            }
    
    gmtData = loadmat('C:/Users/beimx004/Documents/GitHub/hackathon_simulator/GpyT/GpyT/GMTresults.mat')
    
    results = {}
    
    comparison = {}
    # read specified wav file and scale
#    results['sig_smp_wavIn'] = readWavFunc(parReadWav)
    results['sig_smp_wavIn'] = readMatFunc(parReadWav)     # read the resampled data from matlab script to ensure equivalence for debugging  
    
    comparison['sig_smp_wavIn'] = results['sig_smp_wavIn']-gmtData['sig_smp_wavIn'].T
    
    
    results['sig_smp_wavScaled'] = results['sig_smp_wavIn']/np.sqrt(np.mean(results['sig_smp_wavIn']**2))*10**((65-111.6)/20) # set level to 65 dB SPL (assuming 111.6 dB full-scale)
    comparison['sig_smp_wavScaled'] = results['sig_smp_wavScaled']-gmtData['sig_smp_wavScaled'].T
    
    # apply preemphasis
    results['sig_smp_wavPre'] = tdFilterFunc(parPre,results['sig_smp_wavScaled']) # preemphahsis
    comparison['sig_smp_wavPre'] = results['sig_smp_wavPre']-gmtData['sig_smp_wavPre']
   
    
    
    # automatic gain control
    results['agc'] = dualLoopTdAgcFunc(parAgc,results['sig_smp_wavPre']) # agc
    
#    comparison['sig_smp_wavAgc'] = results['agc']['wavOut']-gmtData['agc']['wavOut']
#    comparison['sig_smp_gainAgc'] = results['agc']['smpGain']-gmtData['agc']['smpGain']
    
    
    # window and filter into channels
    results['sig_frm_audBuffers'] = winBufFunc(parWinBuf,results['agc']['wavOut']) # buffering
    comparison['sig_frm_audBuffers'] = results['sig_frm_audBuffers']-gmtData['sig_frm_audBuffers']
    
    results['sig_frm_fft'] = fftFilterbankFunc(parFft,results['sig_frm_audBuffers']) # stft
    comparison['sig_frm_fft'] = results['sig_frm_fft']-gmtData['sig_frm_fft']
    
    
    results['sig_frm_hilbert'] = hilbertEnvelopeFunc(parHilbert,results['sig_frm_fft']) # get hilbert envelopes
    comparison['sig_frm_hilbert'] = results['sig_frm_hilbert']-gmtData['sig_frm_hilbert']
    
    results['sig_frm_energy'] = channelEnergyFunc(parEnergy,results['sig_frm_fft'],results['agc']['smpGain']) # estimate channel energy
    comparison['sig_frm_energy'] = results['sig_frm_energy']-gmtData['sig_frm_energy']
#   apply clearvoice noise reduction
    results['sig_frm_gainCv'] = clearvoiceFunc(parClearVoice,results['sig_frm_energy'])[0] # estimate noise reduction
    comparison['sig_frm_gainCv'] = results['sig_frm_gainCv']-gmtData['sig_frm_gainCv']
    
    results['sig_frm_hilbertMod'] = results['sig_frm_hilbert']+results['sig_frm_gainCv'] # apply noise reduction gains to envelope
    comparison['sig_frm_hilbertMod'] = results['sig_frm_hilbertMod']-gmtData['sig_frm_hilbertMod']
#    # subsample every third FFT input frame
    results['sig_3frm_fft'] = results['sig_frm_fft'][:,2::3]
    
    results['sig_3frm_peakFreq'], results['sig_3frm_peakLoc'] = specPeakLocatorFunc(parPeak,results['sig_3frm_fft'])
    comparison['sig_3frm_peakFreq'] = results['sig_3frm_peakFreq']-gmtData['sig_3frm_peakFreq']
    comparison['sig_3frm_peakLoc'] = results['sig_3frm_peakLoc']-gmtData['sig_3frm_peakLoc']
 #upsample back to full framerate (and add padding)
    results['sig_frm_peakFreq'] = np.repeat(np.repeat(results['sig_3frm_peakFreq'],1,axis=0),3,axis=1)
    results['sig_frm_peakFreq'] = np.concatenate((np.zeros((results['sig_frm_peakFreq'].shape[0],2)),results['sig_frm_peakFreq']),axis=1)
    results['sig_frm_peakFreq'] = results['sig_frm_peakFreq'][:,:results['sig_frm_fft'].shape[1]]
    results['sig_frm_peakLoc'] = np.repeat(np.repeat(results['sig_3frm_peakLoc'],1,axis=0),3,axis=1)
    results['sig_frm_peakLoc'] = np.concatenate((np.zeros((results['sig_frm_peakLoc'].shape[0],2)),results['sig_frm_peakLoc']),axis=1)
    results['sig_frm_peakLoc'] = results['sig_frm_peakLoc'][:,:results['sig_frm_fft'].shape[1]]

    results['sig_frm_steerWeights'] = currentSteeringWeightsFunc(parSteer,results['sig_frm_peakLoc']) # steer current based on peak location
    comparison['sig_frm_steerWeights'] = results['sig_frm_steerWeights']-gmtData['sig_frm_steerWeights']
    
    
    results['sig_ft_carrier'], results['sig_ft_idxFtToFrm'] = carrierSynthesisFunc(parCarrierSynth,results['sig_frm_peakFreq']) # carrier synthesis based on peak frequencies
    comparison['sig_ft_carrier'] = results['sig_ft_carrier']-gmtData['sig_ft_carrier']
    comparison['sig_ft_idxFtToFrm'] = results['sig_ft_idxFtToFrm']-gmtData['sig_ft_idxFtToFrm']
    
    results['sig_ft_ampWords'] = f120MappingFunc(parMapper,results['sig_ft_carrier'],                             # combine envelopes, carrier, current steering weights and compute outputs
                                      results['sig_frm_hilbertMod'],results['sig_frm_steerWeights'],results['sig_ft_idxFtToFrm'] )
    comparison['sig_ft_ampWords'] = results['sig_ft_ampWords']-gmtData['sig_ft_ampWords']
    
    results['elGram'] = f120ElectrodogramFunc(parElectrodogram,results['sig_ft_ampWords'])
    
    matElGramData = loadmat('C:/Users/beimx004/Documents/GitHub/hackathon_simulator/GpyT/GpyT/elGram.mat')
    elGramGMT = matElGramData['elGram']
    
    comparison['elGram'] = results['elGram']-elGramGMT
    
    

#    
    
    
    
    results['finalDeviation'] = results['elGram']-elGramGMT
    
#    # diplay CV gains
#    plt.figure()
#    G = sig_frm_gainCv*3.01
#    plt.imshow(G)
#    plt.colorbar
#    plt.title('ClearVoice Gain [dB]')
#    plt.xlabel('Frame #')
#    plt.ylabel('Channel #')
    
    return results, gmtData,comparison
