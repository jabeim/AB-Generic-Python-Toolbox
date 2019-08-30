% weights = currentSteeringWeightsFunc(par, loc)
% Calculate pairs of current steering weights per channel given estimated 
% cochlear location of the spectral peak frequency per channel.
%
% INPUT:
%   par - parameter object/struct
%   loc - estimated peak locations per channel in "electrode locations", 
%         i.e. ranging from 0 (most apical el.) to 15 (most basal el.) and
%         confined to range [i-1, i] for each channel i
%
% FIELDS FOR PAR:
%   parent.nChan - number of filterbank channels
%   nDiscreteSteps - number of discretization steps
%                    integer >= 0; 0 -> no discretization
%   steeringRange - range of steering between electodes; either
%                      - scalar range (in [0,1]) around 0.5 for all channels
%                      - 1 x nChan vector with range (in [0,1] around 0.5 per channel
%                      - 2 x nChan matrix with (absolute) lower and upper steering 
%                           limits (within [0,1]) per channel
% 
% OUTPUT:
%   weights - (2*nChan) x nFrames matrix of current steering weights; 
%      weights for the lower and higher electrode of channel i are 
%      contained in rows i and (i+nChan), resp.

% Change log:
% 2012, MM - created
% 29/05/2015, PH - adapted to May 2015 framework: shared props removed
% 19/10/2015, PH - added: flexible discritization and steering ranges;
%                  added documentation
% 29/07/2019, PH - fixed bug (weight discretization), added doc
% 14 Aug 2019, PH - swapped arguments
function weights = currentSteeringWeightsFunc(par, loc)

nChan = par.parent.nChan;

nSteps = par.nDiscreteSteps;
assert(isscalar(nSteps) && mod(nSteps,1) == 0, 'nSteps must be an integer scalar.')

range = par.steeringRange;
% 
if isscalar(range)  % convenience: scalar range (around 0.5) for all channels
   range = 0.5 + 0.5*range*[ -ones(1,nChan); ones(1,nChan)];
elseif isvector(range) % convenience: scalar range (around 0.5) per channel  
   assert(length(range) == nChan, 'Length of vector ''range'' must equal nr. of channels.');
   range = 0.5 + 0.5*[-range(:)'; range(:)'];
end
assert((size(range,2) == nChan) && (size(range,1) == 2),...
        'Matrix ''range'' must have dimensions 2 x nChannels.');
assert(all(range(:) >= 0) && all(range(:) <= 1), 'Entries of ''range'' need to lie in [0,1].');
assert(all(diff(range,1) >= 0), 'range(i,2) must be >= range(i,1) for all channels.');


[~, nFrames] = size(loc);
weights = zeros(nChan*2, nFrames);

for iCh = 1:nChan
    % weights for high electrode 
    weightHiRaw = loc(iCh,:) - iCh + 1;  

    % limit high weight to [0, 1]
    weightHiRaw = max(min(weightHiRaw, 1), 0);
    
    % quantize weights (if applicable)
    if nSteps == 1 
        weightHiRaw = 0.5; % steer towards middle of desired range 
    elseif nSteps > 1
        weightHiRaw = round(weightHiRaw * (nSteps-1)) / (nSteps-1); % quantize into nStep steps (including edges 0/1)
    end
    
    % map [0,1] to actual specified steering range (contained in [0,1])
    weightHi = range(1, iCh) + weightHiRaw*diff(range(:, iCh));
    
    weights(iCh, :) = 1 - weightHi; 
    weights(iCh + nChan, :) = weightHi;
end