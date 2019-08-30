% handles = plotF120ElectrodogramFunc(amps, par)
%
% Plots F120 electrodogram. Pulses are displayed as 0-duration delta-pulses.
% Only the positive phase of each biphasic pulse is shown. Amplitudes are
% normalized by the global current maximum.
%
% INPUT:
%   amps - (2*nChannels) x nFrames matrix of current amplitudes
%   par  - parameter object/struct
%
% OUTPUT:
%   handles - struct containing handles to various graphics objects:
%             hFig (figure), hAx (axes) , hXLabel, xYLabel (axes labels),
%             and hLines (one line per electrode)
%
% FIELDS FOR PAR:
%   parent.nChan - no. of coding strategy channels (<= 15)
%   parent.pulseWidth - pulse width [microseconds]
%   pairOffset - vector time offset per physical electrode pair;
%                (# of biphasic pulses from frame start)
%   timeUnits - units for time axis: 's', 'ms' or 'us'
%   xTickInterval - time interval between ticks (in specified units)
%   pulseColor - color used for pulses in plot (Matlab ColorSpec)
%   enable - do plotting or skip [bool]

% Change log:
% 2012, MM - created
% 16/02/2015, PH - added time scaling; plot pulses as groups of stemseries
%                  instead of line; removed non-standard formatting aids;
%                  return handles for outside access to format options
% 29/05/2015, PH - adapted to May 2015 framework: shared props removed
% 13/10/2015, PH - use plot instead of stem for compat. w. recent Matlab
% 27 Jul 2019, PH - swap input arguments for consistency, add enable property
function handles = plotF120ElectrodogramFunc(par, amps)

if ~par.enable
    handles = [];
    return
end

strat = par.parent;
nChan = strat.nChan;

% normalize amps by overall maximum stim. current
M = max(amps(:));
amps = amps/(2*M+0.01);

% adjust time units
switch lower(par.timeUnits)
    case {'s','sec'}
        timeFactor = 1e-6;
        timeLabel = 's';
    case {'ms'}
        timeFactor = 1e-3;
        timeLabel = 'ms';
    case {'us', 'mus'}
        timeFactor = 1;
        timeLabel = '{\mu}s';
    otherwise
        error('Unknown time units: ''%s'' (should be ''s'',''ms'' or ''us'')', par.timeUnits);
end

% convenience variables
strat = par.parent;

nElec = 16;
nAmpChannels = 30;
nPulseSamples = size(amps, 2);
pDur = 2*strat.pulseWidth  * timeFactor; % apply time scale correction (for units ~= microseconds)
frameDur = pDur*nChan;
stimDur = nPulseSamples*pDur*nChan;
pairOffs = par.pairOffset;


% create figure
hFig = figure;
hAx = axes;
xtick = 0:par.xTickInterval:stimDur;
set(gcf, 'Units', 'centimeter', 'Position', [10,10,20,15]);
set(gca, 'xlim', [0 (stimDur+pDur)],...
    'ylim', [0.5 (nElec + 1)],...
    'LooseInset', [0 0 0.02 0.02],...
    'box', 'on', ...
    'yTick', 1:nElec,...
    'xTick', xtick, ...
    'xTickLabel', xtick, ...
    'fontSize', 10);
hold on;

timeFrameStart = 0:frameDur:(stimDur-frameDur); % start time of each stimulation frame

% create one handle group for each electrode
hggroupEl = zeros(1,nElec);
for iElec = 1:nElec
    hggroupEl(iElec) = hggroup;
end

% "collect" pulse times/amps for each electrode 
tPulse = cell(1,nElec);
ampPulse = cell(1,nElec);
for iCh = 1:nAmpChannels
    iPair = ceil(iCh/2);
    timeOffset = pairOffs(iPair)*pDur;
    iEl = floor(iCh/2)+1;
    
    nonZeroInd = find(amps(iCh,:)); % find non-zero amps
    if isempty(nonZeroInd) nonZeroInd = 1; end

    tPulse{iEl} = [tPulse{iEl}, timeFrameStart(nonZeroInd)+timeOffset];
    ampPulse{iEl} = [ampPulse{iEl}, amps(iCh,nonZeroInd)];
end

% plot pulses, electrode after electrode
hLines = NaN(1,nElec);
for iEl = 1:nElec   
    xx = repmat(tPulse{iEl}, 3, 1);
    yy = [iEl+zeros(size(ampPulse{iEl})); iEl+ampPulse{iEl}; NaN(size(ampPulse{iEl}))];
    
    hLines(iEl) = plot( [xx(:); stimDur; 0], [yy(:); iEl; iEl], 'Color', par.pulseColor);
end

% return handles
handles.hFig = hFig;
handles.hAx = hAx;
handles.hLines = hLines;
handles.hXLabel = xlabel(sprintf('Time [%s]', timeLabel), 'fontSize', 12);
handles.yYLabel = ylabel('Electrode', 'fontSize', 12);