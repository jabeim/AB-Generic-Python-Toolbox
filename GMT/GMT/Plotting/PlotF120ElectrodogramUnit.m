% PlotF120ElectrodogramUnit < ProcUnit
% 
% Plot F120 electrodogram. 
%
% PlotF120ElectrodogramUnit properties:
%   *pairOffset - pairOffset - vector time offset per physical el.pair; 
%                # of biphasic pulses from frame start; 
%   *timeUnits - units on time axis ('s', 'ms' or 'us')
%   *xTickInterval - time interval between ticks (in timeUnits)
%   *pulseColor - color used for pulses in plot (Matlab ColorSpec)
%   enable - do plotting or skip [bool] [true]
%   hGraph - struct containing handles to various graphics objects created 
%            during the most recent call of run():
%            hFig (figure), hAx (axes) , hXLabel, xYLabel (axes labels),
%            hLines (one line obj. per electrode)
%
% Input ports:
%   #1 - (2*nChannels) x nFrames matrix of current amplitudes  
%
% Output ports: none
% 
% See also: plotF120ElectrodogramFunc

% Change log:
% 2012, MM - created
% 09/01/2015, PH - use getInput /setOutput instead getData/setData,
%                  removed nInput/nOutput constuctor args
% 29/05/2015, PH - adapted to May 2015 framework: shared props removed
% 26 Jun 2017, PH - SetObservable properties
% 26 Jul 2019, PH - added enable property, update func call in run (swapped arguments)
classdef PlotF120ElectrodogramUnit < ProcUnit
    properties (SetObservable)
        pairOffset = [1 5 9 13 2 6 10 14 3 7 11 15 4 8 12]-1;  % default F120 staggering order       
        timeUnits = 'ms';  % units on time axis ('s', 'ms' or 'us')
        xTickInterval = 500; % time interval between ticks (in timeUnits)
        pulseColor = 'k'; % color used for pulses in plot (Matlab ColorSpec)
    end
    
    properties
        enable = true; % do plotting or skip [bool] [true]
    end
    
    properties(SetAccess=private)
        hGraph; % struct containing handles to various graphics objects:
        % hFig (figure), hAx (axes) , hXLabel, xYLabel (axes labels),
        % hStem (all stemseries) and hggroupEl (one hggroup per el.)
    end
    methods
        function obj = PlotF120ElectrodogramUnit(parent, ID, timeUnits, xTickInt, col)
            % obj = PlotF120ElectrodogramUnit(parent, ID, timeUnits, xTickInt, col)
            obj = obj@ProcUnit(parent, ID, 1, 0);
            
            if nargin > 2
                obj.timeUnits = timeUnits;
            end
            if nargin > 3
                obj.xTickInterval = xTickInt;
            end
            if nargin > 4
                obj.pulseColor = col;
            end
        end
        
        function run(obj)
            ampWords = obj.getInput(1);
            obj.hGraph = plotF120ElectrodogramFunc(obj, ampWords);
        end
    end
end