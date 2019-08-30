function [wavOut GExpand State C CSlow CFast Hold Env G EnvFast] = dualLoopTdAgcFunc(par, wavIn, ctrl)
% [wavOut GExpand State C CSlow CFast Hold Env G EnvFast] = dualLoopTdAgcFunc(par, wavIn, [ctrl])
%
% Apply the (single-channel) Harmony time-domain dual-loop AGC to input. 
% Implementation based on Teak model (agc17.c and agca.c) 
%
% INPUT:
%    wavIn - input waveform (max. range [-1,1])
%    ctrl  - (optional) additional "control" signal that is used to determine
%            the gain to be applied to wavIn; wavIn itself is used as control
%            is no other is explcitly provided          
%
% FIELDS FROM PAR: sampling frequency
%   parent.fs - audio sample rate
%   kneePt - compression threshold (in log2 power)
%   compRatio -  compression ratio above kneepoint (in log-log space)
%   tauRelFast - fast release [ms]
%   tauAttFast - fast attack [ms]
%   tauRelSlow - slow release [ms]
%   tauAttSlow - slow attack [ms]
%   maxHold - max. hold counter value
%   g0 - gain for levels < kneepoint  (log2)
%   fastThreshRel - relative threshold for fast loop [dB]
%   clipMode   - output clipping behavior: 'none' / 'limit' / 'overflow'
%   decFact    - decimation factor
%   envBufLen  - buffer length for envelope computation
%   gainBufLen - buffer length for gain smoothing
%   cSlowInit - initial value for slow averager, 0..1, [] for auto-scale to avg signal amp.
%   cFastInit - initial value for fast averager, 0..1, [] for auto-scale 
%   envCoefs - data window for envelope computation
%   controlMode - how to use control signal, if provided on port #2? [string]; 
%                   'naida'  - actual control signal is 0.75*max(abs(control, audio))
%                   'direct' - control signal is used verbatim without further processing
%
% OUTPUT:
%   wavOut - output waveform
%   G - gain vector (linear, sample-by-sample)
%   State - state vector (0: release, 1: hold,  2:slow attack, fast release,3:slow attack, fast attack)
%   C - vector of effective "input levels" 
%   CSlow - vector of slow averager values
%   CFast - vector of fast averager values
%   Hold - hold counter vector
%
% See also: DualLoopTdAgcUnit

% Change log:
% 27/11/2012, P.Hehrmann - created
% 14/01/2012, P.Hehrmann - renamed; 
%                          fixed: temporal alignment wavIn <-> gains (consistent with fixed-point GMT implementation / C model)
% 01/06/2015, PH - adapted to May 2015 framework: removed shared props
% 28/09/2015, PH - added 'auto' option for initial conditions
% 01/Dec/2017, PH - add "controlMode" property
% 14 Aug 2019, PH - swapped function arguments

% check input dimensions
assert(isvector(wavIn), 'wavIn must be a vector');

if (nargin < 3)
    ctrl = [];
end

if isempty(ctrl) % no explicit control signal provided => control = audio 
    wavIn = wavIn(:)';
    ctrl = wavIn;
else % explicit control signal provided => apply controlMode option 
    assert(isvector(ctrl), 'ctrl must be a vector');
    nSamp = min(length(wavIn), length(ctrl));
    wavIn = wavIn(1:nSamp); % make wavIn a row vector
    wavIn = wavIn(:)';
    switch lower(par.controlMode)
        case 'naida' 
            ctrl = ctrl(1:nSamp)'; 
            ctrl = 0.75*max(abs(wavIn), abs(ctrl));
        case 'direct'
            ctrl = ctrl(1:nSamp)';
        otherwise
            error('Unknown controlMode setting: %s', par.controlMode);
    end
end

% general algo parameters
fs = par.parent.fs;
decFact = par.decFact;
envBufLen = par.envBufLen;
gainBufLen = par.gainBufLen;
maxHold = par.maxHold; % max hold count
c0_log2 = par.kneePt - 15; % compression threshold (log2)
c0 = 2^c0_log2;  % compression threshold (linear)
g0 = par.g0; % AGC base gain, for level < kneepoint (log2) 
gainSlope = (1/par.compRatio - 1); % gain slope above compression threshold (log-log axes)
fastHdrm = 10^(-par.fastThreshRel/20); % fast headroom (linear factor)
envCoefs = par.envCoefs;

% averager weights (derived from time constants in par)
bAttSlow = exp(-decFact / fs * 1000 / par.tauAttSlow); 
bRelSlow = exp(-decFact / fs * 1000 / par.tauRelSlow);
bAttFast = exp(-decFact / fs * 1000 / par.tauAttFast);
bRelFast = exp(-decFact / fs * 1000 / par.tauRelFast);

nSamp = length(ctrl);
nFrame = ceil(nSamp / decFact);

% pre-allocate variables (output time series)
Env = NaN(1, nFrame);
CSlow = NaN(1,nFrame);
CFast = NaN(1,nFrame);
C = NaN(1,nFrame);
G = NaN(1,nFrame);
Hold = NaN(1,nFrame);
State = NaN(1,nFrame);
EnvFast = NaN(1,nFrame);

% Initial conditions
cSlow_i = par.cSlowInit; % slow envelope
if isempty(cSlow_i)  
    cSlow_i = min(1, mean(abs(ctrl)) .* sum(envCoefs));
end
cFast_i = par.cFastInit; % fast envelope
if isempty(cFast_i)
    cFast_i = min(1, mean(abs(ctrl)) .* sum(envCoefs) * fastHdrm);
end
cFastLowLimit_i = cFast_i;
hold_i = 0; % hold counter

% loop over blocks
for iFrame = 1:nFrame    
    
    idxWav = (iFrame)*decFact + (-(envBufLen-1):0) - 1; % -1 gives match apparent match with c-model...
    idxWav = idxWav(( idxWav > 0) & (idxWav <= nSamp) );

    % compute envelope
    env_i = sum( abs(ctrl(idxWav)) .* envCoefs((end-length(idxWav)+1):end) );
    envFast_i = clip1( env_i * fastHdrm );
    
    % update slow and fast averager states
    if (env_i > cSlow_i)  % slow attack
        fastThr_i =  clip1( cSlow_i * 10^(8/20) );
        if (env_i > fastThr_i)  % fast threshold crossed
            deltaHold = 0;
            cFast_i = track(cFast_i, envFast_i, bAttFast); % update fast avg.: attack
            state_i = 3;
        else % fast threshold not crossed
            deltaHold = 2;
            cFastLowLimit_i = cSlow_i * 10^(-10/20) ;    
            cFast_i = track(cFast_i, envFast_i, bRelFast); % update fast avg.: release
            state_i = 2;
        end
        cSlow_i = track(cSlow_i, min(env_i, fastThr_i), bAttSlow); % update slow avg., env limited by fast threshold
    elseif (hold_i == 0) % release, hold is empty
        deltaHold = 0;
        cFastLowLimit_i = cSlow_i * 10^(-10/20) ;
        cFast_i = track(cFast_i, envFast_i, bRelFast); % update fast avg.: release
        cSlow_i = track(cSlow_i, env_i, bRelSlow); % update slow avg.: release
        state_i = 0;
    else % hold state
        deltaHold = -1;
        cFastLowLimit_i = cSlow_i * 10^(-10/20);
        cFast_i = track(cFast_i, envFast_i, bRelFast); % update fast avg.: release
        state_i = 1;
    end
    
    hold_i = min(hold_i + deltaHold, maxHold); % update hold counter
    
    % clip values
    cSlow_i = max(cSlow_i, c0); 
    cFast_i = max(cFast_i, cFastLowLimit_i);
    
    % zelect fast/slow averager for gain computation
    c_i = max(cFast_i, cSlow_i);
    
    % compute gain
    c_i_log2 = log2( max(c_i, 10^(-16)) );
    g_i = 2^(g0  +  gainSlope * max((c_i_log2 - c0_log2), 0));
    
    % store variables
    G(iFrame) = g_i;
    Env(iFrame) = env_i;
    C(iFrame) = c_i;
    CSlow(iFrame) = cSlow_i;
    CFast(iFrame) = cFast_i;
    Hold(iFrame) = hold_i;
    State(iFrame) = state_i;
    EnvFast(iFrame) = envFast_i;
end

% apply gain:
idxExpand = [ ceil( (1/decFact) : (1/decFact) : nFrame) nFrame];
GExpand = G(idxExpand); % expand decimated gain vector
GExpand = filter(ones(1,gainBufLen)/gainBufLen, 1, GExpand); % average over gain window
GExpand = GExpand(2:nSamp+2-gainBufLen);
wavOut = [zeros(1, envBufLen), wavIn(gainBufLen+1:nSamp-envBufLen+1)] .* GExpand; % apply gain

switch lower(par.clipMode)
    case 'none'
        % do nothing, i.e. allow values outside [-1, +1]
    case 'limit'
        % limit to [-1, +1]
        wavOut = max(-1, min(1, wavOut));
    case 'overflow'
        % overflow within the ring [-1, +1]
        wavOut = mod( 1 + wavOut, 2) - 1;
    otherwise
        warning('Unknown clipping mode ''%s''. Using ''none'' instead.', par.clipMode);
end

end

% C_out = track(C_prev, In, weightPrev)
% Update averager
function C_out = track(C_prev, In, weightPrev)
    weightIn = 1 - weightPrev;
    C_out = In * weightIn  +  C_prev * weightPrev;
end

% out = clip1(in)
% clip values to [-1, +1]
function out = clip1(in)
    out = max(-1, min(1, in));
end