initGmtClassPath;

%% Create strategy
strat = FftStrategy();

%% Create instances of ProcUnits and attach them to strategy
rw_s = ReadWavUnit(strat, 'WAV_S', 'Sounds\AzBio_3sent.wav');
rw_n = ReadWavUnit(strat, 'WAV_N', 'Sounds\vacuum_cleaner.wav');

% NOP-strategy
mix = AudioMixerUnit(strat, 'MIX', 2, [65 60], 'rms', 90, [2 0], 1, 1, 0.02);
wb = WinBufUnit(strat, 'WB');
fftfb = FftFilterbankUnit(strat, 'FFT');

fbMatrix = computeF120FilterbankWeights(15);
fbMatrix(1,2:6) = 1;
env = FftFilterbankEnvUnit(strat, 'ENV', fbMatrix);  % 15-channel FFT filterbank, F120 spacing

% ClearVoice 
cv = ClearvoiceUnit(strat,'CV');
cv.maxAtt = 12; % "medium" setting

% Gain application to STFT
anaFilt = fbMatrix;
gains = ChannelGainUnit(strat, 'G', anaFilt, 2, true); 

% Resynthesis incl. ClearVoice
ifft = FftSynthesisUnit(strat,'IFFT','blackHann',[]);
ifft_cv = FftSynthesisUnit(strat,'IFFT_CV','blackHann',[]);

%% connect ProcUnits
strat.connect(rw_s, mix,1);
strat.connect(rw_n, mix,2);
strat.connect(mix, wb);

strat.connect(wb, fftfb);
strat.connect(fftfb, env);
strat.connect(fftfb, ifft);

strat.connect(env, cv);
strat.connect(fftfb, gains,2);
strat.connect(cv, 1, gains,1);
strat.connect(gains, ifft_cv);

[hFig, graph] = csViewer(strat,[],1);

%% run strategy
strat.run();

wav = ifft.getOutput(1);
wav_cv = ifft_cv.getOutput(1);

figure

subplot(1,3,1);
[S,F,T] = spectrogram(wav,hamming(512),512-40,512,17400);
imagesc(T,F,db(S))
set(gca,'clim',[-40 20]);
set(gca,'ydir','normal');
xlabel('Time [s]');
ylabel('Frequency [Hz]')
title('Without ClearVoice');
 
subplot(1,3,2);
[S_cv,F,T] = spectrogram(wav_cv,hamming(512),512-40,512,17400);
imagesc(T,F,db(S_cv))
set(gca,'clim',[-40 20]);
set(gca,'ydir','normal');
xlabel('Time [s]');
ylabel('Frequency [Hz]')
title('With ClearVoice');

subplot(1,3,3);
imagesc(T,F,db(S_cv ./ S));
set(gca,'clim',[-abs(cv.maxAtt)-3, 3]);
set(gca,'ydir','normal');
xlabel('Time [s]');
ylabel('Frequency [Hz]')
title('CV - no CV');
colorbar;
