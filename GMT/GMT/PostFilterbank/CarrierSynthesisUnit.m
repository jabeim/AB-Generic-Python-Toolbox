% CarrierSynthesisUnit < ProcUnit
% Compute square-wave stimulation carrier signals at forward-telemetry (FT) 
% rate given spectral peak frequency estimates for each channel
%
% Input Ports:
%   1 - nChan x nFrames matrix of peak frequency estimates
%
% Output Ports:
%   1 - nChan x nFtFrame matrix of stimulation carriers
%   2 - 1 x nFtFrame array of times corresponding to the FT frames [s]

% Change log:
% 2012, MM - created
% 09/01/2015, PH - use getInput /setOutput instead getData/setData,
%                  removed nInput/nOutput constuctor args
% 29/05/2015, PH - adapted to May 2015 framework: shared props removed
% 18 Jul 2019, PH - added parameters maxModDepth, fModOn, fModOff,
%                   changed function interface (swap input order);
%                   removed dependent property stimRate
%                   added comments
% 26 Jul 2019, PH - added parameter deltaPhaseMax 
classdef CarrierSynthesisUnit < ProcUnit
    
    properties(SetAccess=private)
        fModOn;   % peak frequency up to which max. modulation depth is applied [fraction of FT rate] [0.5]
        fModOff;  % peak frequency beyond which no modulation is applied  [fraction of FT rate] [1.0]
        maxModDepth; % maximum modulation depth [0.0 .. 1.0] [1.0]
        deltaPhaseMax; % maximum phase rotation per FT frame [turns] [1.0] (Harmony: 1.0, Coguaro: 0.5)
                       % Set to (<)= 0.5 to avoid aliasing for fPeak > FT_rate/2
    end
    
    methods
        function obj = CarrierSynthesisUnit(parent, ID, maxModDepth, fModOn, fModOff, deltaPhaseMax)
        % obj = CarrierSynthesisUnit(parent, ID [, maxModDepth [, fModOn [, fModOff]]])
            obj = obj@ProcUnit(parent, ID, 1, 2);
            
            % check inputs
            if nargin < 3
                maxModDepth = 1.0;
            end
            if nargin < 4
                fModOn = 0.5;
            end
            if nargin < 5
                fModOff = 1.0;
            end
            assert(maxModDepth >= 0 && maxModDepth <= 1, 'maxModDepth must be within [0,1]');
            assert(fModOn >= 0 && fModOn < 1, 'fModOn must be within [0,1)');
            assert(fModOff > 0 && fModOff <= 1, 'fModOff must be within (0,1]');
            assert(fModOff > fModOn, 'fModOff must be > fModOn');
            
            % assign parameters
            obj.maxModDepth = maxModDepth;
            obj.fModOn = fModOn;
            obj.fModOff = fModOff;            
            if nargin > 5
                obj.deltaPhaseMax = deltaPhaseMax;
            end

        end
        
        function run(obj)
            fPeak = obj.getInput(1);
            [carrier, tFtFrame] = carrierSynthesisFunc(obj, fPeak);
            obj.setOutput(1, carrier);
            obj.setOutput(2, tFtFrame);
        end
        
    end
end












