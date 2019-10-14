% This demo implements HiRes F120 with Clearvoice and computes the electrode
% output for some speech tokens, as measured using a load-board and scope
initGmtClassPath;

%% Create strategy
strat = FftStrategy();

%% Create instances of ProcUnits and add them to strategy
src = ReadWavUnit(strat, 'SRC', 'Sounds\AzBio_3sent.wav');  % use wav file as input
mix = AudioMixerUnit(strat, 'MIX', 1, 65, 'rms', 111.6);   % 1 inputs, 65dB dB SPL RMS, assuming full-scale level 111.6 dB SPL

pre = HarmonyPreemphasisUnit(strat, 'PRE');             % pre-emphasis filter
agc = DualLoopTdAgcUnit(strat, 'AGC');                  % AGC 
wb = WinBufUnit(strat, 'WB');                           % buffering and windowing
fftfb = FftFilterbankUnit(strat, 'FFT');                % FFT 

env = HilbertEnvelopeUnit(strat, 'HILB');               % Hilbert envelopes 
engy = ChannelEnergyUnit(strat, 'ENGY', 2);             % channel energies (for ClearVoice SNR estimation); 2 inputs (to account for AGC gain)
cv = ClearvoiceUnit(strat, 'CV', 1, 'log2', false);     % ClearVoice noise reduction; 'log2' makes gain output commesurable with Hilbert envelopes
gapp = ElementwiseUnit(strat, 'GAPP', 2, @plus, true);  % CV gain application: element-by-element sum of 2 input;
                                                        % ('true' indicates that @add supports matrix inputs natively)
                                                        
spl = SpecPeakLocatorUnit(strat, 'SPL');                % channel peak frequency and target location estimation
csw = CurrentSteeringWeightsUnit(strat, 'CSW');         % current steering weights based on target location
csynth = CarrierSynthesisUnit(strat, 'CSYNTH');         % synthesize electrode carrier signal at FT rate (temporal fine structure)

map = F120MappingUnit(strat, 'MAP');                    % combine envelopes and carriers, and map to stimulation current amplitude 

egram = F120ElectrodogramUnit(strat, 'EGRAM', true);    % generate electrodogram from mapper output, plotting enabled

%% set (non-default) block parameters
agc.cFastInit = 0; 
agc.cSlowInit = 0; % start AGC in fully "relaxed" state
agc.clipMode = 'limit';

map.mapM = 500 * ones(1,16); % M = 500 uA
map.mapT = 100 * ones(1,16); % T = 100 uA

plotter.xTickInterval = 250; % 250 ms steps 

%% connect ProcUnits (using block labels)
strat.connect(src, mix);
strat.connect(mix, pre);

strat.connect(pre, agc);
strat.connect(agc, wb);
strat.connect(wb, fftfb);  

strat.connect(fftfb, env);
strat.connect(fftfb, engy);
strat.connect(agc, 2, engy, 2);
strat.connect(engy, cv);
strat.connect(env, gapp);
strat.connect(cv, gapp, 2);

strat.connect(fftfb, spl);
strat.connect(spl, csynth);
strat.connect(spl, 2, csw);

strat.connect(gapp, map); 
strat.connect(csw, map, 2);
strat.connect(csynth, map, 3);
strat.connect(csynth, 2, map, 4);

strat.connect(map, egram);

egram.outputFs = 200000;   % 200 kHz scope sampling rate 
egram.resistance = 10000;  % 10 kOhm load-board resistors
egram.colorScheme = 4;

% create "offline" viewer (display strategy as is, no dynamic updating)
hFig = csViewer(strat, [], 0); 

%% run strategy
strat.run();

% Display CV gains
figure;
G = cv.getOutput(1) * 3.01;  % * 3.01 converts log2 power to dB
imagesc(G);
colorbar;
title('ClearVoice Gain [dB]');
xlabel('Frame #');
ylabel('Channel #');
