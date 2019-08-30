% F120MappingUnit < ProcUnit 
% Perform mapping of log2 channel envelopes to electric stimulation current
% amplitudes with F120 current steering and fine-structure carrier.
% 
% F120MappingUnit properties:
%  *mapM - M levels; [uA] [1000]
%  *mapT - T levels; [uA] [100]
%  *mapIdr - IDRs; dB [60]
%  *mapGain - channel gains; dB [0]
%  *mapClip - clipping level; muAmp [2048]
%  *chanToElecPair - 1 x nChan vector defining mapping of logical channels
%                    to electrode pairs (1 = E1/E2, ...) [1:nChan]
%  *carrierMode - how to apply carrier [{0,1,2}] [1]
%                   0 - don't apply carrier (i.e. set carrier == 1)
%                   1 - apply to envelopes (mapper input)  [default]
%                   2 - apply to mapped stimulation amplitudes (mapper output)
%
% F120MappingUnit methods:
%   F120MappingUnit(parent, ID [, chan2el]) - constructor
%
% Input Ports:
%   1 - nCh x nAudFrame matrix of envelopes in log2 power units at audio frame rate
%   2 - 2*nCh x nAudFrame matrix of current steering weights (in [0,1]) at audio frame rate
%   3 - nCh * nFtFrame matrix of carrier signals at FT rate
%   4 - 1 x nFtFrame vector of audio frame indices corresponding to each FT frame index
%
% Output Ports:
%   1 - 30 x nFrames vector of current amplitudes with 2 successive rows
%       for each of the 15 physical electrode pairs; muAmp

% Change log:
% 04/05/2015, PH - created
% 23/06/2017, PH - SetObservable properties
% 22/07/2019, PH - add carrierMode property,
%                  minor refactoring, added comments 
classdef F120MappingUnit < ProcUnit 
   
    properties (SetObservable)
        mapM;  % M levels [uAmp] [1000]
        mapT;  % T levels [uAmp] [100]
        mapIdr; % IDRs  [dB] [60]
        mapGain; % channel gains [dB] [0]
        mapClip; % clipping level [uAmp] [2048]
        chanToElecPair; % 1 x nChan vector defining mapping of logical channels to electrode pairs (1 = E1/E2, ...) [] [1:nChan]
        carrierMode = 1; % carrierMode - how to apply carrier [0 - no carrier, 1 - to input, 2 - to output] [1]
    end
    
    methods 
       function obj = F120MappingUnit(parent, ID, chan2el)
           obj = obj@ProcUnit(parent, ID, 4, 1);
           
           nEl = 16;
           obj.mapM = 1000*ones(1, nEl);
           obj.mapT = 100*ones(1, nEl);
           obj.mapIdr = 60*ones(1, nEl);
           obj.mapGain = 0*ones(1, nEl);
           obj.mapClip = 2048*ones(1, nEl);
           
           nChan = parent.nChan;
           if nargin < 3
               chan2el = 1:obj.parent.nChan;
           end
           % check validity of chan2el
           assert(all(~mod(chan2el, 1)), 'chan2el must contain integers values');
           assert(all(chan2el >= 1) && all(chan2el <= 15), 'chan2el must contain value between 1 and 15');
           assert(length(chan2el) == nChan, 'Length of chan2el must match number of strategy channels.');
           assert(length(chan2el) == length(unique(chan2el)), 'Assignment of channels to electode pairs must be unique.');
 
           obj.chanToElecPair = chan2el;
       end
       
       function run(obj)
           env = obj.getInput(1);
           weights = obj.getInput(2);
           carrier = obj.getInput(3);
           idxAudFrame = obj.getInput(4);
           
           ampWords = f120MappingFunc(obj, carrier, env, weights, idxAudFrame);
            
           obj.setOutput(1, ampWords);
       end
   end
   
end