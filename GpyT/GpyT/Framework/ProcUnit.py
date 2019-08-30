# -*- coding: utf-8 -*-
import numpy as np

class ProcUnit(object):
    def __init__(self,parent,ID,nInputs,nOutputs):
        self.parent = parent;
        self.verbose = 0;
        self.debugData = [];
        self.debugRequest = {};
        
        self.__inputCount = 0;
        self.__outputCount = 0;
        self.ID = ID;
        self.depth = 0;
        self.changeListeners
        
        