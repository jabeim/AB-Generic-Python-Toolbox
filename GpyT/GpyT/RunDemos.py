# -*- coding: utf-8 -*-
import numpy as np
import pyaudio as pa
from scipy.signal import resample
from scipy.io import savemat
from scipy.io.wavfile import read as wavread
from Demo.demo3_procedural import demo3_procedural

playAudio = True
results  = demo3_procedural()

#elGram = results['elGram']
#np.save('elGram.npy',elGram)

if playAudio:
    wavIn = wavread('Sounds/AzBio_3sent.wav')
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
    
    inData = input1.astype(np.float32).tostring()
    outData1 = output1.astype(np.float32).tostring()
#    outData2 = output2.astype(np.float32).tostring()
    
#    stream.write(inData)
    stream.write(outData1)
#    stream.write(outData2)
    
    stream.write(inData)
    stream.close()
#savemat('GpyTdataPYTHON_GIT.mat',results)
            
        
