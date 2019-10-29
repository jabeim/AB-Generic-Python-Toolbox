# -*- coding: utf-8 -*-
"""
Created on Mon Oct 28 12:55:58 2019

@author: beimx004
"""
import numpy as np
from scipy.io import loadmat

matBuffer = loadmat('matBuffer.mat')
matBuffer = matBuffer['b']

pyBuffer = np.load('pyBuffer.npy')


bufferComp = matBuffer-pyBuffer

print(np.sum(bufferComp))


matWindow = loadmat('matWindow.mat')
matWindow = matWindow['matWindow']

pyWindow = loadmat('C:/Users/beimx004/Documents/GitHub/hackathon_simulator/GpyT/GpyT/WinBuf/windowData.mat')
pyWindow = pyWindow['winData']
#pyWindow = np.load('pyWindow.npy')


windowComp = matWindow-pyWindow

print(np.sum(windowComp))


matBufferFin = loadmat('matBufferFin.mat')
matBufferFin = matBufferFin['b']
pyBufferFin = np.load('pyBufferFin.npy')

finBufferComp = matBufferFin-pyBufferFin

print(np.sum(finBufferComp))