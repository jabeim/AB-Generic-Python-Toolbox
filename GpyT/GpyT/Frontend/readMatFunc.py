# -*- coding: utf-8 -*-

from scipy.io import loadmat

def readMatFunc(par):
    
    name = 'C:/Users/beimx004/Documents/GitHub/hackathon_simulator/GpyT/GpyT/Frontend/sig_smp_wavIn.mat'
    
    matData = loadmat(name)
    
    signalIn = matData['sig_smp_wavIn'].T




    return signalIn