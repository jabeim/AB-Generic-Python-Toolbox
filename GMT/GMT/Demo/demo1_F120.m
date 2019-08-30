% This demo implements HiRes F120 (without Clearvoice) and computes the 
% electrode output for some speech tokens.

initGmtClassPath;
   
%% Create strategy
strat = FftStrategy();

%% Create instances of ProcUnits and add them to strategy
src = ReadWavUnit(strat, 'SRC', 'Sounds\AzBio_3sent.wav');  % use wav file as input
mix = AudioMixerUnit(strat, 'MIX', 1, 65, 'rms', 111.6);    % 1 input, 65dB SPL RMS assuming full-scale level 111.6 dB SPL

pre = HarmonyPreemphasisUnit(strat, 'PRE');                 % pre-emphasis filter
agc = DualLoopTdAgcUnit(strat, 'AGC');                      % automatic gain control 
wb = WinBufUnit(strat, 'WB');                               % buffering and windowing    
fftfb = FftFilterbankUnit(strat, 'FFT');                    % FFT
    
env = HilbertEnvelopeUnit(strat, 'ENV');                    % Hilbert envelopes 
spl = SpecPeakLocatorUnit(strat, 'SPL');                    % channel peak frequency and target location estimation
csw = CurrentSteeringWeightsUnit(strat, 'CSW');             % current steering weights based on target location
csynth = CarrierSynthesisUnit(strat, 'CSYNTH');             % synthesize electrode carrier signal at FT rate (temporal fine structure)

map = F120MappingUnit(strat, 'MAP');                        % combine envelopes and carriers, and map to stimulation current amplitude

plotter = PlotF120ElectrodogramUnit(strat, 'PLT');          % plot mapper output as electrodogram

%% connect ProcUnits (using object handles)
strat.connect(src, mix);
strat.connect(mix, pre);

strat.connect(pre, agc);
strat.connect(agc, wb);
strat.connect(wb, fftfb);

strat.connect(fftfb, env);
strat.connect(fftfb, spl);
strat.connect(spl, csynth);
strat.connect(spl, 2, csw);

strat.connect(env, map);
strat.connect(csw, map, 2);
strat.connect(csynth, map, 3);
strat.connect(csynth, 2, map, 4);

strat.connect(map, plotter);

% create "online" viewer (updates view dynamically, slows down strategy execution)
hFig = csViewer(strat, [], 1); 

%% run strategy
strat.run();