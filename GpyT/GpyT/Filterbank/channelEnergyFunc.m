% engyEnv = channelEnergyFunc(par, X)
% Compute the energy envelope for each channel of a FFT-based filterbank.
%
% INPUT:
%   X - FFT coefficients, size nFFT x nFrames
%   gAgc - AGC gain, 1 x nFrames or 1 x nSamples (where nFrames ~~ nSamples/strat.nHop)
%   par - parameter struct or object
%
% FIELDS FOR PAR:
%   gainDomain - domain of gain input (if applicable) ['linear','db','log2']
%   parent.startBin - index of 1st FFT bin in the lowest filterbank channel [one-based]
%   parent.nBinLims - 1 x nChan vector, nr of FFT bins per channel [int > 0]
%
% OUTPUT:
%   engy - Filterbank envelopes, size nCh x nFrames

% Change log:
% 22/10/2015, PH - created
% 04 Jul 2017, PH - output X squared for further processing, remove 
%                   optional computation of spectral maxima per channel 
function [engy] = channelEnergyFunc(par, X, gAgc)
    
    strat = par.parent;
    startBin = strat.startBin;  % first bin of lowest channel
    nBinLims = strat.nBinLims;  % # bins per channel
    nHop = strat.nHop;          % FFT hop size
    
    nFrames = size(X,2);
    nChan = length(nBinLims);

    assert(isempty(gAgc) || isvector(gAgc), 'gAgc, if supplied, has to be a vector');   
    
    % determine if AGC is sample-based, and decimate to frame rate if necessary
    lenAgcIn = length(gAgc);
    if lenAgcIn > nFrames
        gAgc = gAgc(nHop:nHop:end);
        assert(abs(length(gAgc)-nFrames) <= 2, ... % allow some slack around expected size of decimated AGC signal
               'Length of sample-based gAgc input incompatible with nr. frames in STFT matrix: length/nHop must equal nFrames approx.');
        gAgc(end+1:nFrames) = gAgc(end);  % pad / crop decimated gain to nFrames
        gAgc = gAgc(1:nFrames);        
    elseif (lenAgcIn > 0) && (lenAgcIn < nFrames)
        error('Length of gAgc input incompatible with number of frames in STFT matrix: length must be >= nr. frames.');
    end
    
    % compute root-sum-squared FFT magnitudes per channel
    engy = zeros(nChan, nFrames);
    bin = startBin;
    for iChan = 1:nChan
        currBinIdx = bin : bin + nBinLims(iChan) - 1;
        engy(iChan,:) = sum(abs(X(currBinIdx,:)).^2, 1);
        bin = bin + nBinLims(iChan);
    end
    engy = sqrt(engy);
            
    % compensate AGC gain, if applicable
    if lenAgcIn > 0
        switch lower(par.gainDomain)
            case {'linear','lin'}
                % do nothing
            case {'log','log2'}
                gAgc = 2.^(gAgc/2);  % /2 
            case 'db'
                gAgc = 10.^(gAgc/20);
            otherwise
                error('Illegal value for parameter gainDomain');
        end
        gAgc = max(gAgc, eps); % avoid devide-by-zero
        engy = bsxfun(@rdivide, engy, gAgc); % divide each row (channel) of engy by AGC gain vector
    end
end