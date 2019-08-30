% map = binLimsToMixingWeights(startBin, nBins)
% Compute mixing matrix for starting bin and vector containing 
% number of FFT bins per channel
%
% INPUT:
%    startBin - index of first FFT bin belonging to the lowest channel
%    nBins - vector (length nCh) containing number of FFT bins per channel
%    nFreq - nFFT/2, if not set, then nFFT = 256 assumed
%
% OUTPUT:
%    map  - nCh x nFreq mixing matrix (1 or 0 each)
%
% Change log:
% 25/07/2012, P.Hehrmann - created
% 16/01/2018, SD         - added optional argument "nFreq"

function map = binLimsToMixingWeights(startBin, nBins, nFreq)

nCh = length(nBins);
if nargin <3
    nFreq = 128;
end

map = zeros(nCh, nFreq);

for iCh = 1:nCh
    map(iCh, startBin + sum([nBins(1:iCh-1)]) : startBin + sum(nBins(1:iCh))-1) = 1;
end

%fprintf('Number of bins per channel:');
%fprintf('%3d',sum(map,2)); fprintf('\n')

end

