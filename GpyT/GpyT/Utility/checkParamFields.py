# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 10:20:48 2019

@author: beimx004
"""

def checkParamFields(par,requiredFields):
    if isinstance(par,dict):
        for field in requiredFields:
            if not field in par.keys():
                raise ValueError('Wrong parameter names or parameter missing.')
    elif isinstance(par,object):
        for field in requiredFields:
            foo = par.field;
    else:
        raise TypeError('Input Argument ''par'' needs to be a dict or an object.')
        
            