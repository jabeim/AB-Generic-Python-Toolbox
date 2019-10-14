% F120ElectrodogramUnit < ProcUnit
% Generate scope-like electrodogram from F120 amplitude frames. Amplitude 
% frames are expected to represent the amplitude( pair)s for each channel 
% by a pair of consecutive rows each (as provided e.g. by F120MappingUnit)
%
% F120ElectrodogramUnit properties:
%   channelOrder - 1 x nChan vector defining the firing order among channels  
%                  [1..nChan, unique] [[1 5 9 13 2 6 10 14 3 7 11 15 4 8 12]]
%   outputFs - output sampling frequency; [] for native FT rate  [Hz] [[]]
%              (resampling is done using zero-order hold method)
%   cathodicFirst - start biphasic pulse with cathodic phase [boolean] [true]
%   resistance - load-board resistance; [] (or 1) to return values in uA  [Ohm] [[]]
%   enablePlot - generate electrodogram plot? [bool] [true] 
%   colorScheme - color scheme for plot; [1..4] [1] 1/2 more subdued, 3/4 more strident colors; odd/even affects color order
% 
% F120ElectrodogramUnit methods:
%   F120ElectrodogramUnit(parent, id, outputFs, cathodicFirst, channelOrder) - constructor 
%   run() - execute processing
%
% Input ports:
%   #1 - 2*nChan x nFtFrames matrix of stimulation amplitudes [uA]
%
% Output ports:
%   #1 - 16 x nScopeFrame matrix of electrode current flow; [uA]/[V] depending on resistance
%        (nFtFrames == nScopeFrames if outputFs = [])
%
% See also: f120ElectrodogramFunc, F120MappingUnit

% Change log:
% 16 Aug 2019, PH - created
% 08 Oct 2019, PH - added color scheme option
classdef F120ElectrodogramUnit < ProcUnit
    properties(SetObservable)
        outputFs = []; % output sampling frequency; [] for native FT rate  [Hz] [[]]
        cathodicFirst = true; % start biphasic pulse with cathodic phase [bool] [true]
        resistance = []; % load-board resistance; [] to return current in uA  [Ohm] [[]]
        enablePlot = true; % generate electrodogram plot? [bool] [true] 
        colorScheme = 1;  % color scheme for plot; [1..4] [1] 1/2 more subdued, 3/4 more strident colors; odd/even affects color order
    end
    
    properties(SetAccess=private) % can't be changed or monitored for change
        channelOrder = [1 5 9 13 2 6 10 14 3 7 11 15 4 8 12]; %  1 x nChan vector defining the firing order among channels [1..nChan, unique]
    end
    
    methods
        function obj = F120ElectrodogramUnit(parent, id, enablePlot, outputFs, resistance, cathodicFirst, channelOrder) 
            % obj = F120ElectrodogramUnit(parent, id [, enablePlot [, outputFs [, resistance [, cathodicFirst [, channelOrder]]]]])
            % Class constructor.
            % Input:
            %   parent - containing Strategy object
            %   id - string identifier
            %   enablePlot - generate electrodogram plot? [bool]
            %   outputFs - output sampling frequency; [] for native FT rate  [Hz]
            %   resistance - load-board resistance; [] to return current in uA  [Ohm]
            %   cathodicFirst - start biphasic pulse with cathodic phase? [bool]
            %   channelOrder - 1 x nChan vector defining the firing order among channels [1..nChan, unique]
            % Output:
            %   obj - new instance of class F120ElectrodogramUnit
            obj = obj@ProcUnit(parent, id, 1, 1);

            if nargin > 2
                obj.enablePlot = enablePlot;
            end
             
            if nargin > 3
                obj.outputFs = outputFs;
            end
            
            if nargin > 4
                obj.resistance = resistance;
            end            
            
            if nargin > 5 && ~isempty(cathodicFirst)
                obj.cathodicFirst = cathodicFirst;
            end
            
            if nargin > 6              
                obj.channelOrder = channelOrder;
            end
            assert( isequal(sort(obj.channelOrder), 1:parent.nChan) , ...
                    'channelOrder (%s) must be a permutation of [1 .. parent.nChan]', mat2str(obj.channelOrder) ); 
        end
        
        function run(obj)
            x = obj.getInput(1);
            y = f120ElectrodogramFunc(obj, x);
            obj.setOutput(1, y);
        end
    end
end
