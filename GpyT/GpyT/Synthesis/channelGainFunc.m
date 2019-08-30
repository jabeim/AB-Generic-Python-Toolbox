% function Y_out = channelGainFunc(G, Y, par)
%  
% Apply gains G (defined per strategy channels) to STFT coefficients Y
%
% FIELDS FOR PAR:
%   [parent.startBin - index of 1st FFT bin in the lowest filterbank channel; needed if anaMixingWeights = [] 
%   [parent.nBinLims - 1 x nChan vector, nr of FFT bins per channel; needed if anaMixingWeights = []
%    gainDomain  - 'linear' / 'dB' / 'log2Pow'
%    anaMixingWeights - EITHER: nCh x nFFT analysis mixing matrix, 
%                       OR: 2-el vector (nCh, extended low?)
%                       OR: scalar, specifying the number of ch. for a F120
%                           filterbank without extended low channel
%                       OR: [] to use the filterbank specified by the 
%                           parent strategy's startBin nBinLims properties
%    maintainUnassigned - maintain input FFT coefficients for frequency bins
%                         not mapped to a channel? [boolean]
% Change log:
% 16/08/2012, P.Hehrmann - created  
% 24/09/2012, PH - allow anaMixingWeights to be a scalar (specifying
%                          #chan. for a default F120 filterbank w/o exteded low)
% 02/12/2014, PH - removed 'scale' input (#3)
% 11 Jul 2017, PH - updated documentation
function Y_out = channelGainFunc(G, Y, par)
    
    strat = par.parent;

    if isempty(G)
        switch lower(par.gainDomain)
            case 'linear'
                G = ones(strat.nChan, size(Y,2));
            case {'db', 'log2', 'log2pow'}
                G = zeros(strat.nChan, size(Y,2));
        end
    end

    nCh = size(G,1);
    nFrames = size(G,2);
    
    if isempty(par.anaMixingWeights)
        anaMap = binLimsToMixingWeights(strat.startBin, strat.nBinLims, size(Y,1));
    elseif isscalar(par.anaMixingWeights)
        anaMap = computeF120FilterbankWeights(par.anaMixingWeights, 0);        
    elseif isvector(par.anaMixingWeights)
        anaMap = computeF120FilterbankWeights(par.anaMixingWeights(1), par.anaMixingWeights(2));
    else
        anaMap = par.anaMixingWeights;
    end
    
    nFreq = size(anaMap,2);

    assert(size(G,1) == size(anaMap,1), 'Mismatched dimensions: size(env,1) != size(map,2)');
    
    % convert gains to linear
    switch lower(par.gainDomain)
        case 'linear'
            % do nothing
        case 'db'
            G = 10.^(G ./ 20);
        case 'log2pow'
            G = 2.^(0.5*G);
    end
    
    mapCh2Fft = anaMap';
    iNotMapped = false(1,nFreq);
     for iFreq = 1:size(mapCh2Fft,1)
         sumWeights = sum(mapCh2Fft(iFreq,:));
         if (sumWeights > 0);
             mapCh2Fft(iFreq,:) = mapCh2Fft(iFreq,:) ./ sumWeights; % normalise weights across channels to 1
         else
             iNotMapped(iFreq) = true;
         end
     end
    
    Y_out = Y(1:nFreq,:) .* (mapCh2Fft * G);
    
    if par.maintainUnassigned 
        Y_out(iNotMapped,:) = Y(iNotMapped,:);
    end
end

