% Apply onset and/or offset ramp to input audio data
%
% RampAudioUnit properties:
%   *durRampOn  - onset ramp duration (included in total) [sec] {0}
%   *durRampOff - offset ramp duration (included in total) [sec] {0}
%   *rampTypeOn  - onset ramp shape: 'lin'/'cos'/'cos2' {'lin'}
%   *rampTypeOff - offset ramp shape: 'lin'/'cos'/'cos2' {'lin'}
%
%  Input Ports: 
%    #1 - input audio vector  
%  Output Ports:
%    #1 - ramped audio vector  
%
% See also: rampAudioFunc

% Change log:
% 17/08/2015, PH - created
% 22/Jun/2017, PH - SetObservable properties
% 13 Jul 2017, PH - added 'zero' ramp option
classdef RampAudioUnit < ProcUnit
   properties (SetObservable)
      durRampOn = 0; % onset ramp duration [sec] {0}
      durRampOff = 0; % onset ramp duration [sec] {0}
      rampTypeOn  = 'lin'; % ramp type: 'lin'/'cos'/'cos2'/'zero' {'lin'}
      rampTypeOff = 'lin'; % ramp type: 'lin'/'cos'/'cos2'/'zero' {'lin'}     
   end
   
   methods
      function obj = RampAudioUnit(parent, ID, durRampOn, rampTypeOn, durRampOff, rampTypeOff)
          % obj = GenerateSineUnit(parent, ID, durRampOn, rampTypeOn, durRampOff, rampTypeOff) 
          % All constructor arguments are optional. See class doc for details.
          obj = obj@ProcUnit(parent, ID, 1, 1);
          
          if (nargin > 2)
            obj.durRampOn = durRampOn;
          end
          if (nargin > 3)
            obj.rampTypeOn = rampTypeOn;
          end   
          if (nargin > 4)
            obj.durRampOff = durRampOff;
          end
          if (nargin > 5)
            obj.rampTypeOff = rampTypeOff;
          end          
      end
      
      function run(obj)
          s = obj.getInput(1);
          s = rampAudioFunc(obj, s);  
          obj.setOutput(1, s);
      end
   end
end