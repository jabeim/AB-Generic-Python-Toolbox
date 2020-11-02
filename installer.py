# -*- coding: utf-8 -*-
"""
Created on Mon Nov  2 14:59:01 2020

@author: Jbeim
"""

import subprocess
import sys



def install(package):
    subprocess.check_call([sys.executable,"-m","pip","install","-e",package])
                           
# Run installation script   
install('.')

