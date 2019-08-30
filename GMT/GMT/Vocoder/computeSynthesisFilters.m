% function g = computeSynthesisFilters(synthType,slope,nFFT,FS,anaFilters, normalization)
% Compute a nFFT x nCh synthesis mixing matrix, based on a given analysis
% mixing matrix.
function g = computeSynthesisFilters(synthType,slope,nFFT,FS,anaFilters, normalization)
%
% INPUT
%   synthType - 'triang'/'triangLinCf': log-triangular filters around log- or linear CF
%               'trapez': trapezoidal filters, plateau = 6dB-bandwidth
%               'inverse': transpose anaFilters
%               'cf' / 'linCf': single frequency at log- or linear CF
%   slope - slope (dB/octave); only relevant for triangular/trapezoidal filters
%   nFFT - FFT length
%   FS - input sampling rate
%   anaFilters  - nCh x nFft mixing matrix defining the analysis filters
%   normalization -  normalize the mixing weights for each channel? 
%                    'none' (max. gain = 1) / 'power' (squared gains sum to one)
%
% OUTPUT
%   synFilters - nFFT x nCh mixing matrix;
%
% Change log:
%    25/07/2012, P. Hehrmann - created (based on Leo's createReconFilters.m)
%    28/08/2012, P. Hehrmann - changed type name: 'cfLin' -> 'linCf' 
plot = 0;

assert(all(anaFilters(:) >= 0), 'Elements of anaFilters must not be negative.');

nChans = size(anaFilters,1);
nFreq = size(anaFilters,2);

fBinsLin = FS/nFFT * (0:nFreq-1);
fBinsLog2 = log(max(fBinsLin, 1e-20))/log(2);  % oct re. 1 Hz

g = -Inf*ones(nFreq,nChans);

for iChan = 1:nChans
    iLowest = 2;  
    iHighest = size(g,1)-1;

    % for trapezoidal shape: width of plateau = 6dB-bandwidth (assuming contiguous filters)   
    iStart = find(anaFilters(iChan,:) >= 0.5, 1, 'first');
    iEnd = find(anaFilters(iChan,:) >= 0.5, 1, 'last');
    
    % closest index to linear center frequency for each channel
    iMidLin = floor(sum(anaFilters(iChan,:).*(1:nFreq)) / sum(anaFilters(iChan,:)));    
    
    % logarithmic center frequencies and closest index
    log_fc =  sum( anaFilters(iChan,:).*fBinsLog2) / sum(anaFilters(iChan,:));
    
    [~, iMidLog] = min( abs(fBinsLog2 - log_fc));
    
    
    switch(lower(synthType))
       case {'triang','trianglogcf'}  % Triangular on log scale
            g(iMidLog,iChan) = 0;
            g(iLowest:iMidLog-1,iChan) = -slope * (fBinsLog2(iMidLog) - fBinsLog2(iLowest:iMidLog-1));
            g(iMidLog+1:iHighest,iChan) = slope * (fBinsLog2(iMidLog) - fBinsLog2(iMidLog+1:iHighest));
            g(:,iChan) = 10.^(g(:,iChan)/20);
       case {'trianglincf'}  % log-triangular around linear CF
            g(iMidLin,iChan) = 0;
            g(iLowest:iMidLin-1,iChan) = -slope * (fBinsLog2(iMidLin) - fBinsLog2(iLowest:iMidLin-1));
            g(iMidLin+1:iHighest,iChan) = slope * (fBinsLog2(iMidLin) - fBinsLog2(iMidLin+1:iHighest));
            g(:,iChan) = 10.^(g(:,iChan)/20);
        case {'trapez'}  % Trapezoidal on log scale
            g(iStart:iEnd,iChan) = 0;
            g(iLowest:iStart-1,iChan) = -slope * (fBinsLog2(iStart) - fBinsLog2(iLowest:iStart-1));
            g(iEnd+1:iHighest,iChan) = slope * (fBinsLog2(iEnd) - fBinsLog2(iEnd+1:iHighest));
            g(:,iChan) = 10.^(g(:,iChan)/20);
        case {'inverse'}
             g(:,iChan) = anaFilters(iChan,:)'; % transpose
        case {'cf','logcf'}
            g(:,iChan) = 0;
            g(iMidLog,iChan) = 1;
        case {'lincf'}
            g(:,iChan) = 0;
            g(iMidLin,iChan) = 1;
        otherwise
            error('reconStyle = %s not supported.',  synthType);
    end
    g(1:iLowest-1,iChan) = 0;
    g(iHighest+1:end, iChan) = 0;
    
    assert(all(isfinite(g(:,iChan))), 'All elements of g(:,%d) must be finite.', iChan);  % check if all elements of g have been set
    
    switch lower(normalization)
        case {'none','unscaled'}
            % do nothing
        case {'equalpower','power'}
            g(:,iChan) = g(:,iChan) / sqrt(sum(g(:,iChan).^2));
        otherwise
            error('Illegal argument: scaling == ''%s''',normalization);
    end
    
end

if plot
    if isempty(get(0,'Children'))
        hprev = figure;
    else
        hprev = gcf;
        figure;
    end
    subplot(1,2,1);
    imagesc(g);
    colorbar;
    title('linear gains');
    
    subplot(1,2,2);
    imagesc( max(20*log10(g), -50));
    colorbar;
    title('log gains [dB]');
    
    figure(hprev);
end