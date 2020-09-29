# -*- coding: utf-8 -*-
"""
Created on Fri Sep 25 17:27:08 2020

@author: Jbeim
"""


def testfunc(a,b):

    try:
        assert a+b <2, 'result is too large'
    except Exception as e:      
        return e

a = 3
b = 2

c = testfunc(a,b)


print(c)