% DiscritizeAudioUnitUnit < ProcUnit
% Discretize audio signal to desired fixed-point precision
%
% DiscritizeAudioUnitUnit properties:
% *q - number of bits excluding sign; set <= 0 for no discretization
% 
% DiscritizeAudioUnitUnit methods:
% DiscritizeAudioUnitUnit(parent, ID, q) - constructor
%
% Input ports:
%   #1 - audio input vector
%
% Output ports:
%   #1 - discretized audio vector (same length as input)
%

% Change log:
% 17/08/2015, PH - created
% 26 Jun 2017, PH - SetObservable properties
classdef DiscretizeAudioUnitUnit < ProcUnit
    properties (SetObservable)
        q = 15;  % description of property1
    end
    
    methods
        function obj = DiscretizeAudioUnitUnit(parent, ID, q)
            % obj = DiscritizeAudioUnitUnit(parent, ID, q)
            obj = obj@ProcUnit(parent, ID, 1, 1); % change no. of ports as needed
            obj.q = q;
        end
        
        function run(obj)
            % adjust as necessary...
            x = obj.getInput(1);
            
            if (obj.q > 0)
                x = round(x * 2^obj.q) / 2^obj.q;
            end
            
            obj.setOutput(1, x);
        end
    end
end
