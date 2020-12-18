# -*- coding: utf-8 -*-
"""
Created on Wed Sep 18 14:55:51 2019

@author: beimx004
"""
# Import necessary functions
import numpy as np
from pathlib import Path


# Import the rest of the GpyT subpackage functions for the demo here
from ..Frontend.readWav import readWavFunc
from ..Frontend.tdFilter import tdFilterFunc
from ..Agc.dualLoopTdAgc import dualLoopTdAgcFunc
from ..WinBuf.winBuf import winBufFunc
from ..Filterbank.fftFilterbank import fftFilterbankFunc
from ..Filterbank.hilbertEnvelope import hilbertEnvelopeFunc
from ..Filterbank.channelEnergy import channelEnergyFunc
from ..NoiseReduction.noiseReduction import noiseReductionFunc
from ..PostFilterbank.specPeakLocator import specPeakLocatorFunc
from ..PostFilterbank.currentSteeringWeights import currentSteeringWeightsFunc
from ..PostFilterbank.carrierSynthesis import carrierSynthesisFunc
from ..Mapping.f120Mapping import f120MappingFunc
from ..Electrodogram.f120Electrodogram import f120ElectrodogramFunc
from ..Validation.validateOutput import validateOutputFunc
from ..Vocoder.vocoder import vocoderFunc



def demo4_procedural():
        
    stratWindow = 0.5*(np.blackman(256)+np.hanning(256))
    stratWindow = stratWindow.reshape(1,stratWindow.size)  
    basepath = Path(__file__).parent.parent.absolute()
    
    parStrat = {
            'wavFile' : basepath / 'Sounds/AzBio_3sent_65dBSPL.wav',  # this should be a complete absolute path to your sound file of choice
            'fs' : 17400, # this value matches implant internal audio rate. incoming wav files resampled to match
            'nFft' : 256,
            'nHop' : 20,
            'nChan' : 15, # do not change
            'startBin' : 6,
            'nBinLims' : np.array([2,2,1,2,2,2,3,4,4,5,6,7,8,10,56]),
            'window' : stratWindow,
            'pulseWidth' : 18, # DO NOT CHANGE
            'verbose' : 0
            }
    
    parReadWav = {
            'parent' : parStrat,
            'tStartEnd' : [],
            'iChannel' : 1,
            }
    
    parPre = {
            'parent' : parStrat,
            'coeffNum' : np.array([.7688, -1.5376, .7688]),
            'coeffDenom' : np.array([1, -1.5299, .5453]),
            }
    
    envCoefs = np.array([-19,55,153,277,426,596,784,983,
                                   1189,1393,1587,1763,1915,2035,2118,2160,
                                   2160,2118,2035,1915,1763,1587,1393,1189,
                                   983,784,596,426,277,153,55,-19])/(2**16) 
    
    
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
            'cSlowInit' : 0.5e-3,
            'cFastInit' : 0.5e-3,
            'controlMode' : 'naida',
            'clipMode' : 'limit',
            'decFact' : 8,
            'envBufLen' : 32,
            'gainBufLen' : 16,
            'envCoefs' : envCoefs
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
    
    parNoiseReduction = {
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
            'initState' : {'V_s' : -30*np.ones((15,1)),'V_n' : -30*np.ones((15,1))},
            }
    
    parPeak = {
            'parent' : parStrat,
            'binToLocMap' : np.concatenate((np.zeros(6,),np.array([256, 640, 896, 1280, 1664, 1920, 2176,       # 1 x nBin vector of nominal cochlear locations for the center frequencies of each STFT bin
                                            2432, 2688, 2944, 3157, 3328, 3499, 3648, 3776, 3904, 4032,         # values from 0 .. 15 in Q9 format
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
            'deltaPhaseMax' : 0.5
            }
    
    parMapper = {
            'parent' : parStrat,
            'mapM' : 500*np.ones(16),
            'mapT' : 50*np.ones(16),
            'mapIdr' : 60*np.ones(16),
            'mapGain' : 0*np.ones(16),
            'mapClip' : 2048*np.ones(16),
            'chanToElecPair' : np.arange(16),   
            'carrierMode' : 1
            }
    
    parElectrodogram = {
            'parent' : parStrat,
            'cathodicFirst' : True,
            'channelOrder' : np.array([1,5,9,13,2,6,10,14,3,7,11,15,4,8,12]), # DO NOT CHANGE (different order of pulses will have no effect in vocoder output)
            'enablePlot' : True,
            'outputFs' : [], # DO NOT CHANGE (validation depends on matched output rate, vocoder would not produce different results at higher or lower Fs when parameters match accordingly) [default: [],(uses pulse width ~ 55555.55)]
            }
    
    parValidate = {
            'parent' : parStrat,
            'lengthTolerance' : 50, 
            'saveIfSimilar' : True,  # save even if the are too similar to default strategy
            'differenceThreshold' : 1,
            'maxSimilarChannels' : 8,
            'elGramFs' : parElectrodogram['outputFs'],  # this is linked to the previous electrodogram generation step, it should always match [55556 Hz]
            'outFile' : None           # This should be the full path including filename to a location where electrode matrix output will be saved after validation
            }

    results = {} #initialize demo results structure
    

    # read specified wav file and scale
    results['sig_smp_wavIn'],results['sourceName'] = readWavFunc(parReadWav)     # load the file specified in parReadWav; assume correct scaling in wav file (111.6 dB SPL peak full-scale)    
    
    # apply preemphasis
    results['sig_smp_wavPre'] = tdFilterFunc(parPre,results['sig_smp_wavIn']) # preemphahsis
  
    # automatic gain control    
    results['agc'] = dualLoopTdAgcFunc(parAgc,results['sig_smp_wavPre']) # agc
    
    # window and filter into channels
    results['sig_frm_audBuffers'] = winBufFunc(parWinBuf,results['agc']['wavOut']) # buffering
    results['sig_frm_fft'] = fftFilterbankFunc(parFft,results['sig_frm_audBuffers']) # stft
    results['sig_frm_hilbert'] = hilbertEnvelopeFunc(parHilbert,results['sig_frm_fft']) # get hilbert envelopes   
    results['sig_frm_energy'] = channelEnergyFunc(parEnergy,results['sig_frm_fft'],results['agc']['smpGain']) # estimate channel energy

    # apply noise reduction
    results['sig_frm_gainNr'] = noiseReductionFunc(parNoiseReduction,results['sig_frm_energy'])[0] # estimate noise reduction
    results['sig_frm_hilbertMod'] = results['sig_frm_hilbert']+results['sig_frm_gainNr'] # apply noise reduction gains to envelope
    
    # subsample every third FFT input frame
    results['sig_3frm_fft'] = results['sig_frm_fft'][:,2::3]
    
    # find spectral peaks
    results['sig_3frm_peakFreq'], results['sig_3frm_peakLoc'] = specPeakLocatorFunc(parPeak,results['sig_3frm_fft'])

    # upsample back to full framerate (and add padding)
    results['sig_frm_peakFreq'] = np.repeat(np.repeat(results['sig_3frm_peakFreq'],1,axis=0),3,axis=1)
    results['sig_frm_peakFreq'] = np.concatenate((np.zeros((results['sig_frm_peakFreq'].shape[0],2)),results['sig_frm_peakFreq']),axis=1)
    results['sig_frm_peakFreq'] = results['sig_frm_peakFreq'][:,:results['sig_frm_fft'].shape[1]]
    results['sig_frm_peakLoc'] = np.repeat(np.repeat(results['sig_3frm_peakLoc'],1,axis=0),3,axis=1)
    results['sig_frm_peakLoc'] = np.concatenate((np.zeros((results['sig_frm_peakLoc'].shape[0],2)),results['sig_frm_peakLoc']),axis=1)
    results['sig_frm_peakLoc'] = results['sig_frm_peakLoc'][:,:results['sig_frm_fft'].shape[1]]


    # Calculate current steering weights and synthesize the carrier signals
    results['sig_frm_steerWeights'] = currentSteeringWeightsFunc(parSteer,results['sig_frm_peakLoc']) # steer current based on peak location 
    results['sig_ft_carrier'], results['sig_ft_idxFtToFrm'] = carrierSynthesisFunc(parCarrierSynth,results['sig_frm_peakFreq']) # carrier synthesis based on peak frequencies

    # map to f120 stimulation strategy
    results['sig_ft_ampWords'] = f120MappingFunc(parMapper,results['sig_ft_carrier'],                             # combine envelopes, carrier, current steering weights and compute outputs
                                      results['sig_frm_hilbertMod'],results['sig_frm_steerWeights'],results['sig_ft_idxFtToFrm'] )

    # convert amplitude words to simulated electrodogram for vocoder imput
    results['elGram'] = f120ElectrodogramFunc(parElectrodogram,results['sig_ft_ampWords'])    
   
    # # load output of default processing strategy to compare with  results['elGram'], return errors if data matrix is an invalid shape/unacceptable to the vocoder,save results['elGram'] to a file
    results['outputSaved'] = validateOutputFunc(parValidate,results['elGram'],results['sourceName']); 
    
    # process electrodogram potentially saving as a file (change to saveOutput=True)
    results['audioOut'],results['audioFs'] = vocoderFunc(results['elGram'],saveOutput=False)
    

    
    return results
