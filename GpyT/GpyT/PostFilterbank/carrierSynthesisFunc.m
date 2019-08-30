% [carrier, tFtFrame] = carrierSynthesisFunc(par, fPeak)
%
% INPUT:
%   par - parameter object/struct
%   fPeak - nChan x nFrames matrix of estimated peak frequencies per channel
%
% FIELDS FOR par:
%   parent.nChan - number of analysis channels
%   parent.fs - sample rate of signalIn [Hz]
%   stimRate - channel stimulation rate in pps or Hz
%
% OUTPUT:
%   carrier  - nChan x nFrameFt square-wave carrier signals
%   tFtFrame - start time of each FT frame, starting with 0 [s]

% Change log:
% 2012, MM - created
% 29 May 2015, PH - adapted to May 2015 framework: shared props removed
% 18 Jul 2019, PH - re-wrote CS code for improved readability ans speed, 
%                   added parameters maxModDepth, fModOn, fModOff   
%                   changed function interface (swap input order)
% 26 Jul 2019, PH - added parameter deltaPhaseMax 
function [carrier, tFtFrame] = carrierSynthesisFunc(par, fPeak)

strat = par.parent;
nChan = strat.nChan;
nFrame = size(fPeak,2); 
fs = strat.fs;   % audio sampling rate [Hz]
pw = strat.pulseWidth; % pulse width (per phase) [us]

durFrame = strat.nHop / fs; % audio frame duration [s]
durStimCycle = 2 * pw * nChan * 1e-6;  % duration of a full stimulation cycle [s] 
rateFt = round(1/durStimCycle); % stim cyc per sec = forward telemetry rate  [Hz]

nFtFrame = ceil(durFrame * nFrame / durStimCycle) - 1; % number of output forward-telemetry frames
tFtFrame = (0 : nFtFrame-1) * durStimCycle; % "start time" of each FT frame

idxAudFrame = floor(tFtFrame / durFrame) + 1; % index of latest audio frame available for each FT frame;
fPeakPerFtFrame = fPeak(:,idxAudFrame);  % latest peak freq. estimate for each channel and FT frame 

% compute phase accumulation (per channel and frame)
deltaPhiNorm = min(fPeakPerFtFrame/rateFt, 0.5*2);   % phase deltas [in turns, i.e. rad/(2*Pi)]
phiNorm = mod(cumsum(deltaPhiNorm, 2), 1);   % accumulated phase, modulo 1 [turns]

% compute modulation depth  (per channel and frame)
maxMod = par.maxModDepth;        % max. modulation depth
fModOn = rateFt * par.fModOn;    % peak freq. up to which max. modulation depth is applied
fModOff = rateFt * par.fModOff;  % peak freq. beyond which modulation depth is 0
modDepth = maxMod * (fModOff - min(max(fPeakPerFtFrame, fModOn),fModOff)) / (fModOff - fModOn); % drop depth from 100% to 0% between fModOn and fModOff

% synthesize carrier: phase-dependent alternation x modulation depth  
carrier = 1 - (modDepth .* (phiNorm < 0.5));

% DEBUGGING only: output audio sample index instead of FT times
tFtFrame = idxAudFrame;