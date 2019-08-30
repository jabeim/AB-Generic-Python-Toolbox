%  M = computeAnalysisFilters(FS, NFFT, fLow, fHigh)
%
%  Compute an nFftBin x nCh analysis filterbank matrix with the passband
%  for each channel i defined be frequencies fLow(i) and fHigh(i). 
%  Specifically, fLow and fHigh specify the frequencies of the nearest FFT
%  bin frequency still included in the corresponding pass band. The
%  frequency resolution of this rounding is df = FS/NFFT. The passband 
%  magnitude is 1, the stopband amplitude is 0.
%
% Change log:
% 12/12/12, P.Hehrmann - created
function M = computeAnalysisFilters(FS, NFFT, fLow, fHigh)

    if nargin < 4
        fHigh = fLow; 
    end

    assert(isvector(fLow) && isvector(fHigh) && length(fLow)==length(fHigh),...
        'fLow and fHigh must be vectors of equal length.');
    assert(all(fLow >= 0) && (all(fHigh >= 0)), 'Frequencies fLow and fHigh must be non-negative.');
    
    nCh = length(fHigh);
    nBin = NFFT/2;
    
    df = FS/NFFT;
    
    M = zeros(nBin, nCh);
    for iCh = 1:nCh
        idxPass = (round(fLow(iCh)/df):round(fHigh(iCh)/df)) + 1;
        M(idxPass, iCh) = 1;
        if isempty(idxPass)
            warning('Channel %d has no pass-band.', iCh);
        end
    end  

end