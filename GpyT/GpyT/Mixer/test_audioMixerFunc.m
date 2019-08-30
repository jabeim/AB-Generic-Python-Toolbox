clear par;

fs = 17400;
dt = 1/fs;

t1 = (0:dt:2-dt);
t2 = (0:dt:0.5-dt);

wavTone = cos(2*pi*t1*200)';
wavImp = (2*([1 rand(1,length(t2)-1)]-0.5) .* exp(-t2/0.05))';

par.parent.fs = 17400;
par.sensIn = 120;
par.lvlDb = [77 100];
par.lvlType = {'rms','peak'};
par.wrap = 1;
par.durFade = 0;
par.primaryIn = [];
par.delays = [];
par.clipValue = 1;

wavMix = audioMixerFunc(wavTone, wavImp, par);
figure
plot(t1, wavMix);
% expected max. amplitude = 0.11:
%   tone: 77dB RMS = 80 dB peak = -40dB FS = 0.01;
%   impulse:        100 dB peak = -20dB FS = 0.1;
% tone starts in cos-phase, first impulse amp. is +1 => max amps. add
disp(max(abs(wavMix)));


t3 = (0:dt:1-dt);
wavChirp = chirp(t3, 300, 1, 1200, 'log')';
par2.parent.fs = 17400;
par2.sensIn = 120;
par2.lvlDb = [-12 -12];
par2.lvlType = 'rel';
par2.wrap = 1;
par2.durFade = 0.4;
par2.primaryIn = [];
par2.delays = [0 0.5];
par2.clipValue = 1;
wavMix2 = audioMixerFunc(wavTone, wavChirp, par2);
figure;
spectrogram(wavMix2, hamming(512), 512*3/4, 512, 17400 )
set(gca,'xlim',[0 1500]);
view(90, 270)
colorbar
