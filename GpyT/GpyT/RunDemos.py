# -*- coding: utf-8 -*-

import matplotlib.pyplot as plt

from Demo.demo3_procedural import demo3_procedural

sigIn,sigScaled,sigPre,sigWavAgc,sigGainAgc,sigFrm_AudBuffer,sigFrm_fft,sigFrm_hilbert,sigFrm_engy,sigFrm_gainCv,sig3F_fft,sig_3f_peakF,sig_3f_peakLoc,sig_frm_peakFreq,sig_frm_peakLoc = demo3_procedural()


#plt.plot(sigWavAgc)