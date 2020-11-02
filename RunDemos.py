# -*- coding: utf-8 -*-
import numpy as np
import pyaudio as pa
from scipy.signal import resample
from scipy.io.wavfile import read as wavread

# load the toolbox package
from GpyT.Demo.proceduralDemo import demo4_procedural

playAudio = True

results  = demo4_procedural()

if playAudio:
    wavIn = wavread(results['sourceName'])
    wavData = wavIn[1]/(2**15-1)
    wavFs = wavIn[0]

    wavResampled = resample(wavData,((results['audioFs']/wavFs)*wavData.shape[0]).astype(int))
    input1 = np.float32(np.concatenate((wavResampled,np.zeros(results['audioFs']))))
    
    output1 = np.float32(np.concatenate((np.zeros(results['audioFs']),results['audioOut'])))
    p = pa.PyAudio()
    devInfo = p.get_default_output_device_info()
    devIndex = devInfo['index']
    nChan = 1
    
    stream = p.open(format=pa.paFloat32,
    channels=nChan,
    rate=results['audioFs'],
    output=True,
    output_device_index = devIndex
    )
    
    inData = input1.astype(np.float32).tobytes()
    outData1 = output1.astype(np.float32).tobytes()
    

    stream.write(outData1)

    
    stream.write(inData)
    stream.close()
    
    
    