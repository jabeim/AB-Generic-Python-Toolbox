initGmtClassPath;

%% Create strategy
strategy = CodingStrategy();

%% Create instances of ProcUnits and attach them to strategy
rw = ReadWavUnit(strategy, 'RW_1', 1, 1);
wb = WinBufUnit(strategy, 'WB_1',1, 2);
fftfb = FFTFilterBankUnit(strategy, 'FFT_1', 1, 1);
extenv = ExtractEnvelopeUnit(strategy, 'ENV_1', 2, 1);
sml = SpecMaxLocatorUnit(strategy, 'SML_1', 1, 3);
spl = SpecPeakLocatorUnit(strategy, 'SPL_1', 2, 2);
csw = CurrentSteeringWeightsUnit(strategy, 'CSW_1', 1, 1);

% Upsampling ratio for estimated frequencies and weights
resRatioSlow = strategy.sp_hopSize*strategy.sp_dsFactor;
% Upsampling ratio for fast envelope
resRatioFast = strategy.sp_hopSize;

resWeights = ResampleUnit(strategy, 'RES_WEIGHTS', 1, 1, resRatioSlow);
resFreq = ResampleUnit(strategy, 'RES_FREQ', 1, 1, resRatioSlow);
resFast = ResampleUnit(strategy, 'RES_FAST', 1, 1, resRatioFast);
csynth = CarrierSynthesisUnit(strategy, 'CSYNTH_1', 2, 2);
map = MappingUnit(strategy, 'MAP_1', 4, 1);
plotter = PlotF120ElectrodogramUnit(strategy, 'PLT_1', 1, 0);

%% post-assign parameters through strategy
strategy.sp_nBinLims = [2, 2, 1, 2, 2, 2, 3, 4, 4, 5, 6, 7, 8, 10, 56];
% strategy.sp_nBinLims = generateBinLimsF120;

strategy.sp_mapRecords = [1 5 9 13 2 6 10 14 3 7 11 15 4 8 12];
% strategy.sp_mapRecords = 1:15;

%% connect ProcUnits (weird order to test csViewer)
strategy.connectProcUnits('RES_FAST', 'OUTPUT_1', 'MAP_1', 'INPUT_1');
strategy.connectProcUnits('RES_WEIGHTS', 'OUTPUT_1', 'MAP_1', 'INPUT_2');
strategy.connectProcUnits('CSYNTH_1', 'OUTPUT_1', 'MAP_1', 'INPUT_3');
strategy.connectProcUnits('CSYNTH_1', 'OUTPUT_2', 'MAP_1', 'INPUT_4');
strategy.connectProcUnits('MAP_1', 'OUTPUT_1', 'PLT_1', 'INPUT_1');

strategy.connectProcUnits('WB_1', 'OUTPUT_1', 'FFT_1', 'INPUT_1');
strategy.connectProcUnits('WB_1', 'OUTPUT_2', 'ENV_1', 'INPUT_2');
%strategy.connectProcUnits('ENV_1', 'OUTPUT_1', 'ENV_1', 'INPUT_2'); % creates a loop 
strategy.connectProcUnits('FFT_1', 'OUTPUT_1', 'ENV_1', 'INPUT_1');
strategy.connectProcUnits('FFT_1', 'OUTPUT_1', 'SML_1', 'INPUT_1');
strategy.connectProcUnits('SML_1', 'OUTPUT_1', 'SPL_1', 'INPUT_1');
strategy.connectProcUnits('SML_1', 'OUTPUT_2', 'SPL_1', 'INPUT_2');
strategy.connectProcUnits('SPL_1', 'OUTPUT_2', 'CSW_1', 'INPUT_1');
strategy.connectProcUnits('CSW_1', 'OUTPUT_1', 'RES_WEIGHTS', 'INPUT_1');
strategy.connectProcUnits('SPL_1', 'OUTPUT_1', 'RES_FREQ', 'INPUT_1');
strategy.connectProcUnits('ENV_1', 'OUTPUT_1', 'RES_FAST', 'INPUT_1');
strategy.connectProcUnits('RES_FREQ', 'OUTPUT_1', 'CSYNTH_1', 'INPUT_1');
strategy.connectProcUnits('RW_1', 'OUTPUT_1', 'CSYNTH_1', 'INPUT_2');

strategy.connectProcUnits('RW_1', 'OUTPUT_1', 'WB_1', 'INPUT_1');

rw.setData('INPUT_1', 'beispielSatz_kurz.wav');

[hFig graph] = csViewer(strategy);
