# -*- coding: utf-8 -*-

import matplotlib.pyplot as plt

from Demo.demo3_procedural import demo3_procedural

sigIn,sigScaled,sigPre,sigWavAgc,sigGainAgc,sigFrm_AudBuffer,sigFrm_fft,sigFrm_hilbert,sigFrm_engy,sigFrm_gainCv,sig3F_fft = demo3_procedural()


#plt.plot(sigWavAgc)