% function mapCh2Fft = inverseFilterbankWeights(mapFft2Ch)
% 
% Compute matrix that maps channels to FFT bins for a given mapping from
% FFT bins to channels:  invert matrix and normalise rows.
%
% P.Hehrmann, Jul 2012
function mapCh2Fft = inverseFilterbankWeights(mapFft2Ch)
    mapCh2Fft = mapFft2Ch'; % transpose
    
    channelSum = sum(mapCh2Fft,2);
    normMask = (channelSum > 0);
    
    mapCh2Fft(normMask,:) = mapCh2Fft(normMask,:) ./ repmat( channelSum(normMask), 1, size(mapCh2Fft,2) ); % normalise rows
end