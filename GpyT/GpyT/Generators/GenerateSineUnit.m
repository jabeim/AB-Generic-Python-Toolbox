% Generate sine wave of given frequency, duration and peak amplitude.
% Required rampAudioFunc.
%
% GenerateSineUnit properties:
%   *freq - frequency [Hz] {1000}
%   *dur  - total duration [sec] {1}
%   *peak - peak amplitude {1}
%   *durRampOn - onset ramp duration [sec] {0}
%   *durRampOff - offset ramp duration [sec] {0}
%   *rampTypeOn  - onset ramp type: 'lin'/'cos'/'cos2' {'lin'}
%   *rampTypeOff - offset ramp type: 'lin'/'cos'/'cos2' {'lin'}   
%
% GenerateSineUnit methods:
%   GenerateSineUnit - constructor
%   run - execute processing
%
% Input Ports: none
%
% Output Ports:
%   #1 - generated waveform (1 x nSamp) 
%
% See also: rampAudioFunc

% ??, MM - created
% 08/01/2015, PH - use getInput/setOutput instead of getData/setData,
%                  remove nInput/nOutput constructor args
% 28/07/2015, PH - renamed GenerateSinusUnit -> GenerateSineUnit,
%                  added ramp duration and type,  documentation
% 17/08/2015, PH - use rampAudioFunc for ramping
% 22/Jun/2017, PH - SetObservable properties
% 13 Jul 2017, PH - added 'zero' ramp option
classdef GenerateSineUnit < ProcUnit
   properties (SetObservable)
      freq = 1000; % frequency [Hz] {1000}
      dur = 1; % total duration [sec] {1}
      peak = 1; % peak amplitude {1}
      durRampOn = 0; % onset ramp duration [sec] {0}
      durRampOff = 0; % onset ramp duration [sec] {0}
      rampTypeOn  = 'lin'; % ramp type: 'lin'/'cos'/'cos2'/'zero' {'lin'}
      rampTypeOff = 'lin'; % ramp type: 'lin'/'cos'/'cos2'/'zero' {'lin'}     
   end
   
   methods
      function obj = GenerateSineUnit(parent, ID, freq, dur, peak, durRampOn, rampTypeOn, durRampOff, rampTypeOff)
          % obj = GenerateSineUnit(parent, ID, freq, dur, peak, durRampOn, rampTypeOn, durRampOff, rampTypeOff) 
          %  Constructor. Arg #3 - #9 are optional. See class doc for details.
          obj = obj@ProcUnit(parent, ID, 0, 1);
          
          if (nargin > 2)
            obj.freq = freq;
          end
          if (nargin > 3)
            obj.dur = dur;
          end
          if (nargin > 4)
            obj.peak = peak;
          end
          if (nargin > 5)
            obj.durRampOn = durRampOn;
          end
          if (nargin > 6)
            obj.rampTypeOn = rampTypeOn;
          end
          if (nargin > 7)
            obj.durRampOff = durRampOff;
          end
          if (nargin > 8)
            obj.rampTypeOff = rampTypeOff;
          end          
      end
      
      function run(obj)
          fs = obj.parent.fs;
          t = (0:obj.dur*fs - 1)/fs;
          s = sin(2*pi*obj.freq*t)*obj.peak;
          
          s = rampAudioFunc(obj, s);        
          
          obj.setOutput(1, s);
      end
   end
end