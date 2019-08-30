% CurrentSteeringWeightsUnit < ProcUnit
% Compute current steering weights from nominal cochlear location of the 
% estimated spectral peak frequency per channel. Assumes that locations 
% for channel i lie within [i-1, i]. Steering weights can be distretized 
% and/or limited to a channel-specific sub-range. For each channel, the 
% resulting pairs of steering weights sum to 1 always. 
%
% CurrentSteeringWeightsUnit properties:
%   nDiscreteSteps - number of discretization steps [int >= 0] [9]; 0 -> no discretization
%   steeringRange  - range of steering between electodes [0..1] [1.0]
%                         - scalar range around 0.5 for all channels (within [0,1])
%                         - 1 x nChan vector of ranges (0-1) around 0.5 per channel
%                         - 2 x nChan matrix with (absolute) lower and upper steering 
%                           limits (0-1) per channel
%
% CurrentSteeringWeightsUnit methods:
%   CurrentSteeringWeightsUnit(parent, ID) - constructor
%   run() - execute processing
% 
% Input ports:
%   #1 - nChan x nFrames matrix of cochlear location, each row i limited to
%        values in [i-1, 1]
%
% Output ports:
%   #1 - (2*nChan) x nFrames matrix of current steering weights; weights 
%        for the lower and higher electrode of channel i are contained in
%        rows i and (i+nChan), resp.

% Change log:
% 2012, MM - created
% 09/01/2015, PH - use getInput /setOutput instead getData/setData,
%                  removed nInput/nOutput constuctor args
% 29/05/2015, PH - adapted to May 2015 framework: shared props removed
% 10/19/2015, PH - added: flexible discretization and steering ranges
% 26 Jun 2017, PH - SetObservable properties
% 25 Jul 2019, PH - changed default nDiscreteSteps to 9 (matching product FW)                   
% 14 Aug 2019, PH - swapped currentSteeringWeightsFunc arguments
classdef CurrentSteeringWeightsUnit < ProcUnit
    properties (SetObservable)
        nDiscreteSteps = 9;   % nr. of discretization steps  [int >= 0] [9]; 0 -> no discretization
        steeringRange = 1.0;  % steering range between electrodes [0..1] [1.0]
    end
    
    methods
        function obj = CurrentSteeringWeightsUnit(parent, ID)
            obj = obj@ProcUnit(parent, ID, 1, 1);
        end
        
        function run(obj)
            loc = obj.getInput(1);
            weights = currentSteeringWeightsFunc(obj, loc);
            obj.setOutput(1, weights);            
        end
    end
end