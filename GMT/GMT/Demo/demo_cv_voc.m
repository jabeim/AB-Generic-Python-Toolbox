initGmtClassPath;

%% Create strategy
strat = FftStrategy();

%% Add ProcUnits to strategy
rw_s = ReadWavUnit(strat, 'WAV_S', 'Sounds\AzBio_3sent.wav');
rw_n = ReadWavUnit(strat, 'WAV_N', 'Sounds\olnoise.wav');

mix = AudioMixerUnit(strat, 'MIX', 2, [65 65], 'rms', 90, [2 0], 1, 1, 0.02);
wb = WinBufUnit(strat, 'BUF');
fftfb = FftFilterbankUnit(strat, 'FFT');
engy = FftFilterbankEnvUnit(strat, 'ENGY', [15 1]);  % 15-channel FFT filterbank, F120 spacing

% ClearVoice 
cv = ClearvoiceUnit(strat, 'CV', 2); % 2 outputs: gains (unused) and modified channel energy estimates (for vocoder)
cv.maxAtt = 18; % ClearVoice, "strong" setting

voc = VocoderUnit(strat,'VOC',[],'linear','triang',40,'random','power');
voc_cv = VocoderUnit(strat,'VOC_CV',[],'linear','triang',40,'random','power');

% Resynthesis incl. ClearVoice
ifft =  FftSynthesisUnit(strat,'IFFT','blackHann',[]);
ifft_cv = FftSynthesisUnit(strat,'IFFT_CV','blackHann',[]);

%% connect ProcUnits
strat.connect(rw_s, 1, mix,1);
strat.connect(rw_n, 1, mix,2);
strat.connect(mix,wb);

strat.connect(wb,fftfb);
strat.connect(fftfb,engy);

strat.connect(engy,cv);
strat.connect(cv, 2, voc_cv);
strat.connect(voc_cv, ifft_cv);
strat.connect(engy, voc);
strat.connect(voc, ifft);

[hFig, graph] = csViewer(strat,[],1);

%% run strategy
strat.run();

wav = ifft.getOutput(1);
wav_cv = ifft_cv.getOutput(1);

figure
subplot(1,2,1)
[S,F,T] = spectrogram(wav,hamming(512),512-40,512,17400);
imagesc(T,F,db(S))
set(gca,'clim',[-40 20]);
set(gca,'ydir','normal');
xlabel('Time [s]');
ylabel('Frequency [Hz]')
title('ClearVoice Off');

subplot(1,2,2)
[S_cv,F,T] = spectrogram(wav_cv,hamming(512),512-40,512,17400);
imagesc(T,F,db(S_cv))
set(gca,'clim',[-40 20]);
set(gca,'ydir','normal');
xlabel('Time [s]');
ylabel('Frequency [Hz]')
title('ClearVoice On');
