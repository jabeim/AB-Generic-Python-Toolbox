# -*- coding: utf-8 -*-
import numpy as np
import matplotlib.pyplot as plt
from scipy.io import savemat
from Demo.demo3_procedural import demo3_procedural

results, gmtData,comparison = demo3_procedural()


savemat('GpyTdata.mat',results)
            
        

    
    