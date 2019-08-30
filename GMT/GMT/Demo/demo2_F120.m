% This demo implements HiRes F120 (without Clearvoice) and computes the 
% electrode output for 1000 Hz tone. 
initGmtClassPath;

%% Create strategy
strat = FftStrategy();
strat.verbose = 0; % no console output from strategy

%% Create instances of ProcUnits and add them to strategy
gs = GenerateSineUnit(strat, 'GS', ...              % generate tone with 1000Hz, 0.2s duration, peak amp. 0.01, 50 ms cos^2 onset ramp
        1000, 0.2, 0.01, 0.05, 'cos2'); 
    
pre = HarmonyPreemphasisUnit(strat, 'PRE');         % pre-emphasis filter    
agc = DualLoopTdAgcUnit(strat, 'AGC');              % automatic gain control 
wb = WinBufUnit(strat, 'WB');                       % buffering and windowing  
fftfb = FftFilterbankUnit(strat, 'FFT');            % FFT

env = HilbertEnvelopeUnit(strat, 'ENV');            % Hilbert envelopes
spl = SpecPeakLocatorUnit(strat, 'SPL');            % channel peak frequency and target location estimation
csw = CurrentSteeringWeightsUnit(strat, 'CSW');     % current steering weights based on target location
csynth = CarrierSynthesisUnit(strat, 'CSYNTH');     % synthesize electrode carrier signal at FT rate (temporal fine structure)

map = F120MappingUnit(strat, 'MAP');                % combine envelopes and carriers, and map to stimulation current amplitude

plotter = PlotF120ElectrodogramUnit(strat, 'PLT');  % plot mapper output as electrodogram

%% set (non-default) block parameters
agc.cFastInit = 0; agc.cSlowInit = 0;   % start AGC in fully "relaxed" state
map.mapM = 500 * ones(1,16);            % M = 500 uA
map.mapT = 120 * ones(1,16);            % T = 120 uA
plotter.xTickInterval = 10;             % 10 ms steps 
plotter.pulseColor = [0.7 0.2 0.85];    % an electrodogram in mauve

%% connect ProcUnits (using block labels)
strat.connect('GS',  'PRE');
strat.connect('PRE', 'AGC');
strat.connect('AGC', 'WB');
strat.connect('WB', 'FFT');

strat.connect('FFT', 'ENV');
strat.connect('FFT', 'SPL');
strat.connect('SPL', 'CSYNTH');
strat.connect('SPL', 2, 'CSW');

strat.connect('ENV', 'MAP');
strat.connect('CSW', 'MAP', 2);
strat.connect('CSYNTH', 'MAP', 3);
strat.connect('CSYNTH', 2, 'MAP', 4);

strat.connect('MAP','PLT');

% create "offline" viewer (display strategy as is, no dynamic updating)
hFig = csViewer(strat, [], 0); 

%% run strategy
strat.run();