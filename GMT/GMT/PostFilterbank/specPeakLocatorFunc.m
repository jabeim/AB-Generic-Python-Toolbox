% [freq, loc] = specPeakLocatorFunc(par, stftIn)
% Estimate dominant (peak) frequency and corresponding cochlear location for
% each channel of the coding strategy. Peak frequency estimates are
% obtained by quadratic interpolation of the frequency spectrum around the
% highest-energy FFT bin per channel. Target locations are computed from
% the peak frequencies by piece-wise linear interpolation, with nodes 
% defined for the center frequencies of each STFT bin.
% 
% INPUT
%   par - parameter object / struct   
%   stft - nBins x nFrames matrix of STFT coefficients
%
% FIELDS FOR PAR:
%   parent.nFft - FFT length [int > 0]
%   parent.fs   - audio sampling rate [Hz]
%   parent.nChan - number of analysis channels [int > 0]
%   parent.startBin - index of 1st FFT bin in the lowest filterbank channel [one-based]
%   parent.nBinLims - 1 x nChan vector, nr of FFT bins per channel [int > 0]
%   binToLocMap - 1 x nBin vector of nominal cochlear locations for the center frequencies of each STFT bin
%
% OUTPUT:
%   freq : nChan x nFrames matrix of estimated peak frequencies [Hz]
%   loc : nChan x nFrames matrix of corresponding cochlear locations [within [0,15]]

% Change log:
% 2012, MM - created
% 29/05/2015, PH - adapted to May 2015 framework: shared props removed
% 30/07/2019, PH - bug fix: fit parabola to log (not linear) spectral magnitudes
%                - integrated functionality of specMaxLocator (obsoleting specMaxLocator)
%                - add binToLocMap as configurable parameter
%                - replaced 3 calls of fastIndexAlloc with 1 call of sub2ind (150x faster)
function [freqInterp, loc] = specPeakLocatorFunc(par, stftIn)

strat = par.parent;
nFft = strat.nFft;
fs = strat.fs;
nChan = strat.nChan;
nBinLims = strat.nBinLims;
binToLoc = par.binToLocMap;
startBin = strat.startBin;

fftBinWidth = (fs/nFft);
           
[nBins, nFrames] = size(stftIn);

maxBin = zeros(nChan, nFrames);      % index of highest-energy STFT bin per channel and frame 
freqInterp = zeros(nChan, nFrames);  % peak frequency estimate per channel and frame
loc = zeros(nChan, nFrames);         % cochlear location corresponding to peak freqs (in # of electrodes)
binCorrection = zeros(1, nFrames);   % fractional bin correction around the argmax of the raw STFT magnitudes, [-0.5..+0.5]

PSD = real(stftIn .* conj(stftIn))/2;
PSD = max(PSD, 10^(-120/20));

% 1st step: determine maximum-energy bin within each channel
bin = startBin;
for i = 1:nChan
    currBinIdx = bin : bin + nBinLims(i) - 1;
    % calculate local maximum within channel bins
    [~, argMaxPsd] = max(PSD(currBinIdx,:), [], 1); 
    % relocate maximum according to matlab indexing
    maxBin(i, :) = bin + argMaxPsd - 1; 
    bin = bin + nBinLims(i);
end

% 2nd step: refine peak estimation by parabolic interpolation around maxima
for i = 1:nChan
        
    ind_m = sub2ind(size(PSD), maxBin(i,:), 1:nFrames)';
    midVal = log2(PSD(ind_m));
           
    leftVal = log2(PSD(ind_m - 1));  % -1 requires par.startBin > 2 (careful with super-low phantom)
    rightVal = log2(PSD(ind_m + 1)); % +1 requires that highest bin is not maximum 
    maxLeftRight = max(leftVal,rightVal);
    
    midIsMax = (midVal > maxLeftRight);
    
    % parabolic fit if and only if middle value is unique local maximum  
    binCorrection(midIsMax) = 0.5 * (rightVal(midIsMax) - leftVal(midIsMax)) ...
                                 ./ (2 * midVal(midIsMax) - leftVal(midIsMax) - rightVal(midIsMax));  % denominator != 0 guaranteed per max condition
                              
    % set to right (+0.5) or left (-0.5) bin boundary, or middle (+0.5 - 0.5 = 0) if all are equal 
    binCorrection(~midIsMax) =   0.5 * (rightVal(~midIsMax) == maxLeftRight(~midIsMax)) ...
                               - 0.5 * (leftVal(~midIsMax) == maxLeftRight(~midIsMax));
    
    % final peak frequency estimate
    freqInterp(i,:) = fftBinWidth * (maxBin(i,:) + binCorrection - 1); 
    
    deltaLocIdx = maxBin(i,:) + sign(binCorrection); % index of the location index to steer towards (maxLoc +- 1)
    loc(i,:) = binToLoc(maxBin(i,:)) + binCorrection .* abs(binToLoc(maxBin(i,:)) - binToLoc(deltaLocIdx));
end