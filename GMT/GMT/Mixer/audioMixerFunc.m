% [wavOut clip] = audioMixerUnit(wav_1, ..., wav_n, par)
% Mix arbitrary number of audio inputs signals wav_i. For every signal, the
% target level as well as the target level type have to be specified 
% (abs. rms/abs. peak/rel. to input). par.sensIn defines the peak SPL 
% equivalent to 0dB FS. par.wrap controls the behaviour of input signals
% are of unequal length (warp around or zero-pad to match duration of the 
% primary signal). For par.wrap = 1, par.durFade controls the duration of 
% a cosine-shaped cross-fade between the end and beginning.
%
% INPUT:
%   wav_i - vector containing wav data for input channel i
%   par   - paramteter struct / object
%
% FIELDS FOR PAR:
%   parent.fs    - input sampling rate
%   sensIn   - input sensitivity: dB SPL corresponding to digital RMS amp. (0dB re.) 1
%                  [equivalently: dB peak corresponding to digital peak amp. 1]  
%   lvlType  - string or cell array of strings: 'rms' / 'peak' / 'rel'; 
%              if string, same type is used for all channels;
%              if cell aray, the size must match n
%   lvlDb    - scalar or n-vector of levels per channel in dB; for types 'rms'
%              and 'peak', lvlDb(i) is in dB SPL; for type 'rel', lvlDb(i) is
%              in dB relative to the input level.
%              If a scalar is provided, the gain derived for the primary 
%              input (see below) is applied to all channels equally. %   delays   - vector of onset delays for each input [s] 
%   primaryIn - which input determines the length of the mixed output
%               (1..nInputs, or []); if [], the longtest input (including 
%               delay) is chosen as primary.
%   wrap     - repeat shorter inputs to match duration of the primary
%              input? [1/0]
%   durFade  -  duration of cross-fade when wrapping signals [s]
%   channelMode - treat each channel independently, or apply gain
%                 determined for the primary input to all channels?
%                 ['independent' / 'primary']
%
% OUTPUT:
%    wavOut  - mixed signal (column vector)
%    clip    - clipping indicator [0/1]

% Change log:
% 29/08/2012, P.Hehrmann - created
% 31/08/2012, P.Hehrmann - bug fix: determine input levels before
%                          wrapping/padding
% 12/09/2012, P.Hehrmann - bug fix (unwanted error occurred in case of clipping)
% 09/12/2012, PH - added 'primaryIn' and 'delays' functionality
% 11/12/2012, PH - convenience fix: make all inputs column vectors
% 22/01/2015, RK - Adding the (delayed) input signals to be able to plot
%                 the components
% 01/06/2015, PH - adapted to May 2015 framework: removed shared props
% 27/11/2017, PH - option to compute gain for one "master channel" and 
%                  apply to all channels equally 
% 17 Apr 2018, PH - added clipValue property 
% 05/07/2018, JT - added multichannel handling
function [wavOut, wav, clip] = audioMixerFunc(varargin)

par = varargin{end};

fs = par.parent.fs;

nWav = nargin-1;
wav = varargin(1:nWav);
nChannels = zeros(nWav, 1);
% make all wavs column vectors and determine number of channels
for iWav = 1:nWav
    [M, N] = size(wav{iWav});
    if M>N
        nChannels(iWav) = N;
        wav{iWav} = reshape(wav{iWav}', M*N, 1);
    else
        nChannels(iWav) = M;
        wav{iWav} = reshape(wav{iWav}, M*N, 1);
    end
end
% ensure all inputs have the same number of channels
assert(all(nChannels==nChannels(1)), 'All inputs need to have the same number of channels.');
nChannels = nChannels(1);

primaryIn = par.primaryIn;

assert(all(cellfun(@(X__) isnumeric(X__) & isvector(X__), wav(1:nWav))), 'wav_1..wav_n must be numerical vectors');
assert(length(par.lvlDb) == nWav || isscalar(par.lvlDb), 'Length of par.lvlDb must equal the number of audio inputs.');
assert(isempty(par.delays) || (length(par.delays) == nWav), 'Length of par.delays must 0 or equal the the number of audio inputs. ' )
assert(ischar(par.lvlType) || iscellstr(par.lvlType), 'par.lvlType must be a string of cell array of strings.')
assert(isempty(primaryIn) || (~mod(primaryIn,1) && (primaryIn <= nWav) && primaryIn > 0),...
       'primaryIn must be empty or an integer less or equal to the number of audio inputs.');

% compute onset delay for each audio input
if isempty(par.delays)
    delays = zeros(1,nWav);
else
    assert(all(par.delays >= 0), 'Elements of par.delays must be non-negative.');
    delays = nChannels*round(par.delays * fs);
end

% get level type for each input
if ischar(par.lvlType)
    lvlType = repmat({par.lvlType},1,nWav);
else
    lvlType = par.lvlType;
end

% determine input signal lengths
lenWavIn = cellfun(@length, wav(1:nWav));
lenWavDelayed = lenWavIn + delays; % input length including delays

% determine output length
if isempty(primaryIn)
    lenOut = max(lenWavDelayed);
else
    lenOut = lenWavDelayed(primaryIn);
end

% length of cross-fade in samples, and fade-in/out envelopes
lenFade = ceil(par.durFade * fs);
envFadeOut = 0.5*cos(linspace(0,pi,lenFade))' + 0.5;
% Adjust fade to account for number of channels and their arrangement in
% the colum vector
envFadeOut = reshape(repmat(envFadeOut,1,nChannels)',1,lenFade*nChannels)';
lenFade = lenFade*nChannels;
envFadeIn = 1-envFadeOut;

% determine input levels (prior to padding/wrapping)
lvlWav = NaN(1,nWav);
for iWav = 1:nWav
    switch lower(lvlType{iWav})
        case 'rms'
            lvlWav(iWav) = 10*log10(mean(wav{iWav}.^2)) + par.sensIn;
        case 'peak'
            lvlWav(iWav) = 20*log10(max(abs(wav{iWav})))  + par.sensIn;
        case 'rel'
            lvlWav(iWav) = 0;
        otherwise 
            error('Unknown level scaling type ''%s'' at index %d', lvlType{iWav}, iWav);
    end
end

% find wavs that need to be wrapped / padded
needsLengthening = (lenWavDelayed < lenOut);

for iWav = 1:nWav
    % RETHINK nRep with delays!
    if needsLengthening(iWav)
        if par.wrap % wrap signal
            nRep = ceil( (lenOut-delays(iWav))/(lenWavIn(iWav)-lenFade) - 1 );
            wavCross = envFadeOut .* wav{iWav}(end-lenFade+1:end) + envFadeIn .* wav{iWav}(1:lenFade);
            wav{iWav} = [zeros(delays(iWav),1); wav{iWav}(1:end-lenFade); ...
                repmat([wavCross; wav{iWav}(lenFade+1:end-lenFade)], nRep, 1 )];
            wav{iWav}(lenOut+1:end) = [];
        else % zero-pad signal
            wav{iWav} = [zeros(delays(iWav),1); wav{iWav}; zeros(lenOut-lenWavDelayed(iWav),1)];
        end
    else % truncate signal
        wav{iWav} = [zeros(delays(iWav),1); wav{iWav}(1:lenOut-delays(iWav))];
        wav{iWav}(end+1:lenOut) = [];
    end
    
end

% keyboard
assert(all(cellfun(@(W__) length(W__) == lenOut, wav)), 'All wavs must have length lenMax by now.')

% compute gain in dB for each input
if isscalar(par.lvlDb) && isempty(primaryIn) % master gain applied to all inputs, but not primary input specified 
    gains = (par.lvlDb(1)-lvlWav(1)) * ones(1,nWav);
elseif isscalar(par.lvlDb) && isscalar(primaryIn) % master gain applied to all inputs, derived from primary input 
    gains = (par.lvlDb(primaryIn)-lvlWav(primaryIn)) * ones(1,nWav);
else % gain computed independently for each channel
    gains = zeros(1,nWav);
    for iWav = 1:nWav
        gains(iWav) = (par.lvlDb(iWav)-lvlWav(iWav));
    end
end


% add scaled inputs
wavOut = zeros(lenOut, 1);
for iWav = 1:nWav
    wavOut = wavOut + wav{iWav} * 10^(gains(iWav) / 20);
    wav{iWav} = wav{iWav} * 10^(gains(iWav) / 20);
end

% check clipping
maxAbsOut = max(abs(wavOut));
clip = (maxAbsOut > par.clipValue);
if clip
    warning('Clipping occured. Maximum output amplitude %.2f (%.2fdB FS, equiv. %.2fdB SPL)', maxAbsOut, 20*log10(maxAbsOut), 20*log10(maxAbsOut)+par.sensIn);
end

% undo flattening
wavOut = reshape(wavOut, nChannels, lenOut/nChannels).';
% same on all input signals
for iWav = 1:nWav
    wav{iWav} = reshape(wav{iWav}, nChannels, lenOut/nChannels).';
end

end