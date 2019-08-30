% GenerateNoiseUnit < ProcUnit
%
%  GenerateNoiseUnit properties:
%   *type -  'uniform'/'gaussian'/'binary'/'impulse'  ['uniform'];
%   *dur - duration in sec [5] 
%   *peak - peak amplitude [1];
%
% Change log:
% ??, MM - created
% 08/01/2015, PH - use getInput/setOutput instead of getData/setData
%                  remove nInput/nOutput constructor args
% 22/Jun/2016, PH - SetObservable properties, some documentation
% 06/07/2018, JT - Added Impulse "noise" type


classdef GenerateNoiseUnit < ProcUnit
   properties (SetObservable)
      type = 'uniform';
      dur = 5; % 5 sec.
      peak = 1;
      delay = .1; % .1 sec.
   end
   methods
      function obj = GenerateNoiseUnit(parent, ID, type, dur, peak, delay)
          obj = obj@ProcUnit(parent, ID, 0, 1);
          
          if nargin > 2
              obj.type = type;
          end
          if nargin > 3
              obj.dur = dur;
          end
          if nargin > 4
              obj.peak = peak;
          end
          if nargin > 5
              obj.delay = delay;
          end
      end
      
      function run(obj)
          nSamples = round(obj.dur*obj.parent.fs);
          
          switch obj.type
              case {'gauss', 'gaussian'}
                  s = randn(nSamples,1);
              case {'uniform'}
                  s = rand(nSamples,1)-0.5;
              case {'binary'}
                  s = sign(rand(nSamples,1)-0.5);
              case {'impulse'}
                  s =  zeros(nSamples, 1);
                  s(obj.delay*obj.parent.fs) = 1;
              otherwise
                  error('Unknown noise type: ''%s''', obj.noiseType);
          end
          
          peakAmp = max(abs(s));
          
          s = s / peakAmp * obj.peak;
          
          obj.setOutput(1, s);
      
      end
   end
end