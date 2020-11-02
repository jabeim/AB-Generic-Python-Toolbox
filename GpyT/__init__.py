# -*- coding: utf-8 -*-
"""
Created on Fri Oct 30 11:34:22 2020

@author: Jbeim
"""

# Import multifunction modules
from . import Filterbank
from . import Frontend
from . import PostFilterbank


# Import single function modules
from .Agc.dualLoopTdAgc import dualLoopTdAgcFunc
# from .Demo.proceduralDemo import demo4_procedural
from .Electrodogram.f120Electrodogram import f120ElectrodogramFunc
from .Mapping.f120Mapping import f120MappingFunc
from .NoiseReduction.noiseReduction import noiseReductionFunc
from .Plotting.plotF120Electrodogram import plotF120ElectrodogramFunc
from .Validation.validateOutput import validateOutputFunc
from .Vocoder.vocoder import vocoderFunc
from .WinBuf.winBuf import winBufFunc

