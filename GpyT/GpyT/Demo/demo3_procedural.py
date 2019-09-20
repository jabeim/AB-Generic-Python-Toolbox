# -*- coding: utf-8 -*-
"""
Created on Wed Sep 18 14:55:51 2019

@author: beimx004
"""
# Import necessary functions
import numpy as np
import matplotlib.pyplot as plt

from Frontend.readWavFunc import readWavFunc
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
from Plotting.plotF120ElectrodogramFunc import plotF120ElectrodogramFunc

def demo3_procedural():
    
    parStrat = {
            'fs' : 17400,
            'nFft' : 256,
            'nHop' : 20,
            'nChan' : 15,
            'startBin' : 6,
            'nBinLims' : np.array([2,2,1,2,2,2,3,4,4,5,6,7,8,10,56]),
            'window' : 0.5*(np.blackman(256)+np.hanning(256)),
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
                                            7616, 7659]),7679*np.ones((53,))))
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
            'mapIDR' : 60*np.ones(16),
            'mapGain' : 0*np.ones(16),
            'mapClip' : 2048*np.ones(16),
            'chanToElecPair' : np.arange(1,16),
            'carrierMode' : 1
            }
    
    parPlotter = {
            'parent' : parStrat,
            'pairOffset' : np.array([1,5,9,13,2,6,10,14,3,7,11,15,4,8,12])-1,
            'timeUnits' : 'ms',
            'xTickInterval' : 250,
            'pulseColor' : 'r',
            'enable' : True
            }
    # read specified wav file and scale
    sig_smp_wavIn = readWavFunc(parReadWav)
    sig_smp_wavScaled = sig_smp_wavIn/np.sqrt(np.mean(sig_smp_wavIn**2))*10**((65-111.6)/20) # set level to 65 dB SPL (assuming 111.6 dB full-scale)
    
    # apply preemphasis
    sig_smp_wavPre = tdFilterFunc(parPre,sig_smp_wavScaled) # preemphahsis
    # automatic gain control
    sig_smp_wavAgc, sig_smp_gainAgc = dualLoopTdAgcFunc(parAgc,sig_smp_wavPre)[0:2] # agc
    # window and filter into channels
    sig_frm_audBuffers = winBufFunc(parWinBuf,sig_smp_wavAgc) # buffering
#    sig_frm_fft = fftFilterbankFunc(parFft,sig_frm_audBuffers) # stft
#    sig_frm_hilbert = hilbertEnvelopeFunc(parHilbert,sig_frm_fft) # get hilbert envelopes
#    sig_frm_energy = channelEnergyFunc(parEnergy,sig_frm_fft,sig_smp_gainAgc) # estimate channel energy
#    # apply clearvoice noise reduction
#    sig_frm_gainCv = clearvoiceFunc(parClearVoice,sig_frm_energy) # estimate noise reduction
#    sig_frm_hilbertMod = sig_frm_hilbert+sig_frm_gainCv # apply noise reduction gains to envelope
#    
#    # subsample every third FFT input frame
#    sig_3frm_fft = sig_frm_fft[:,3::3]
#    sig_3frm_peakFreq, sig_3frm_peakLoc = specPeakLocatorFunc(parPeak,sig_3frm_fft)
#    #upsample back to full framerate (and add padding)
#    sig_frm_peakFreq = np.repeat(np.repeat(sig_3frm_peakFreq,1,axis=0),3,axis=1)
#    sig_frm_peakFreq = np.concatenate((np.zeros((sig_frm_peakFreq.shape[0],2)),sig_frm_peakFreq))
#    sig_frm_peakFreq = sig_frm_peakFreq[:,:sig_frm_fft.shape[1]]
#    sig_frm_peakLoc = np.repeat(np.repeat(sig_3frm_peakLoc,1,axis=0),3,axis=1)
#    sig_frm_peakLoc = np.concatenate((np.zeros((sig_frm_peakLoc.shape[0],2)),sig_frm_peakLoc))
#    sig_frm_peakLoc = sig_frm_peakLoc[:,:sig_frm_fft.shape[1]]
#
#
#
#    
#    sig_frm_steerWeights = currentSteeringWeightsFunc(parSteer,sig_frm_peakLoc) # steer current based on peak location
#    sig_ft_carrier, sig_ft_idxFtToFrm = carrierSynthesisFunc(parCarrierSynth,sig_frm_peakFreq) # carrier synthesis based on peak frequencies
#    sig_ft_ampWords = f120MappingFunc(parMapper,sig_ft_carrier,                             # combine envelopes, carrier, current steering weights and compute outputs
#                                      sig_frm_hilbertMod,sig_frm_steerWeights,sig_ft_idxFtToFrm)
#    
#    plotF120ElectrodogramFunc(parPlotter,sig_ft_ampWords)  # plot electrodogram
#    
#    # diplay CV gains
#    plt.figure()
#    G = sig_frm_gainCv*3.01
#    plt.imshow(G)
#    plt.colorbar
#    plt.title('ClearVoice Gain [dB]')
#    plt.xlabel('Frame #')
#    plt.ylabel('Channel #')
    
    return sig_smp_wavIn, sig_smp_wavScaled, sig_smp_wavPre,sig_smp_wavAgc, sig_smp_gainAgc