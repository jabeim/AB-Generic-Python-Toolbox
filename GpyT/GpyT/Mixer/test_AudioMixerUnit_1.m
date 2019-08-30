% The output of two ReadWavUnits are mixed at 65dB SPL rms / 110dB SPL peak
% with wrap-around of the shorter signal and no cross-fade at the
% repetition boundary. The mixed signal is then vocoded. The peak amplitude
% of the mixed signal should be close to -10dB FS = ~0.31.

%% Create strategy
strat = FftStrategy();

%% Create instances of ProcUnits and attach them to strategy
rw1 = ReadWavUnit(strat, 'RW1');
rw2 = ReadWavUnit(strat, 'RW2');

mix = AudioMixerUnit(strat, 'MIX', 2, [60 90], {'rms','peak'}, 120, [], [], 1, 0);

wb = WinBufUnit(strat, 'WB');
fftfb = FftFilterbankUnit(strat, 'FFT');
env = FftFilterbankEnvUnit(strat, 'ENV', []);

voc = VocoderUnit(strat,'VOC',[], 'linear', 'triang', 25, 'coherent', 'power');
synth = FftSynthesisUnit(strat,'IFFT','blackHann',[]);

try
    initGmtClassPath;
    csViewer(strat, [], 1);
catch
end


%% connect ProcUnits (auto flowChart will be added soon)
strat.connect('RW1', 'MIX', 1);
strat.connect('RW2', 'MIX', 2);
strat.connect('MIX', 'WB');
strat.connect('WB','FFT');
strat.connect('FFT', 'ENV');
strat.connect('ENV', 'VOC');
strat.connect('VOC', 'IFFT');

rw1.wavFile = 'tone_1kHz.wav';
rw2.wavFile = 'impulse.wav';

%% run strategy
strat.run();

snd = mix.getOutput(1);
snd_voc = synth.getOutput(1);

figure;
t1 = (1:length(snd))/17400;
t2 = (1:length(snd_voc))/17400;
subplot(2,1,1);
plot(t1,snd);
title('Mixed audio signal');
xlabel('time [s]');
axis tight;
subplot(2,1,2);
plot(t2,snd_voc, 'r');
title('Vocoder output');
xlabel('time [s]');
axis tight;