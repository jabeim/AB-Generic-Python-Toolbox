% VocoderDiscCompUnit < VocoderUnit
% FFT-based vocoder, extends the more basic VocoderUnit in several aspects. 
%
% Envelope values exceeding the specified IDR (incl. headroom at the top 
% end) can optionally be bounded to the available IDR, or (at the lower
% end) set to 0. VocoderDiscCompUnit allows for additional discretization
% and instantaneous log. compression of the channel envelopes, intended to
% mimic perceptual level discrimination deficits typically found in 
% electric hearing (monaural level JNDs and ILD JNDs). Instantaneous
% envelope compression is always applied AFTER discritization and bounding.
%
% Random number generation: 
%   - If enableContinuous == false, the random generator will be initialized
%     with the specified seed value (randSeed) during every call of run();
%     Set randSeed = 'shuffle' to get a different random sequence every time;
%   - If enableContinuous == true, the random generator will only be 
%     initialized in the run() method if randGen is empty; run() will set 
%     the randGen property to a non-empty value in that case;  
%
% CircBufUnit will always have its "modified" status flag set to true, i.e. 
% it will recompute its output always, even if inputs haven't changed
% 
% Parameters determining discretisation/compression have to be set 
% after an instance of VocoderDiscCompUnit has been created.
%
% VocoderDiscComp properties:
%  *compressionRatio - instantaneous envelope compression ratio [db/db] {1}
%  *idrTopLvl - nominal top of IDR, excl. "head-room" [db FS] {-12}
%  *idrWidth - width of the IDR [dB] {60}
%  *idrHeadroom - head-room above IDR top [dB] {12}
%  *stepSize - discretisation step size, 0 = off [dB] {0} 
%  *aboveIdrMode - how to handle values above IDR+HR ['nop'/'bound'] {'nop'} 
%  *belowIdrMode - how to handle values below IDR ['nop'/'bound'/'zero'] {'nop'} 
%  *randSeed - random seed for phase generation [int or 'shuffle']
%  *alpha - wighting factor for phase noise, only for phaseType = 'alpha' [0..1] [1]
%   enableContinuous - save/restore states across repeated calls of run [boolean] [false]
%   randGen {protected} - RandStream object used as random generator
%
% VocoderDiscComp methods:
%   VocoderDiscComp - constructor
%   run - execute processing
%
% See also: vocoderDiscCompFunc.m, VocoderUnit, RandStream

% Change log:
% 14/10/2013 - feature: envelope discretization (equidistant steps in log-domain)
% 02/12/2014, PH - removed optional 'scale' input (#2)
% 09/01/2015, PH - use getInput /setOutput instead getData/setData
% 10/05/2015, PH - adapted to May 2015 framework: removed shared props
% 27 Jun 2017, PH - SetObservable properties
% 01 Mar 2018, PH - add enableContinuous  
% 09 Mar 2018, PH - new phase mode 'alpha'
classdef VocoderDiscCompUnit < VocoderUnit
    
    properties (SetObservable)
        compressionRatio = 1; % instantaneous envelope compression ratio [db/db] {1}
        idrTopLvl = -12; % nominal top of IDR, excl. "head-room" [db FS] {-12}
        idrWidth = 60; % width of the IDR [dB] {60}
        idrHeadroom = 12; % head-room above IDR top [dB] {12}
        stepSize = 0; % discretisation step size, 0 = off [dB] {0} 
        aboveIdrMode = 'nop'; % how to handle values above IDR+HR ['nop'/'bound'] {'nop'} 
        belowIdrMode = 'nop'; % how to handle values below IDR ['nop'/'bound'/'zero'] {'nop'} 
        randSeed = 0;  % random seed for phase generation [int or 'shuffle']
        alpha = 1; % wighting factor for phase noise, only for phaseType = 'alpha' [0..1]
    end
    
    properties
        enableContinuous = false; % enable storing of DSA and ZASTA state for continuous repeated processing
    end
    
    properties(SetAccess=protected)
        randGen;
    end
    
    methods
        function obj = VocoderDiscCompUnit(parent, ID, anaMixingWeights, envDomain, synthType, synthSlope, phaseType, normalization)
        % Syntax:
        % obj = VocoderDiscCompUnit(parent, ID, anaMixingWeights, envDomain, synthType, synthSlope, phaseType, normalization)   
            obj = obj@VocoderUnit(parent, ID, anaMixingWeights, envDomain, synthType, synthSlope, phaseType, normalization);
            obj.MODIFIED_RESETVAL = true;
        end
        
        function run(obj)
            X = obj.getInput(1);
            
            if ~obj.enableContinuous || isempty(obj.randGen)
                obj.randGen = RandStream('dsfmt19937', 'Seed', obj.randSeed); % fast double-precision Mersenne twister
            end
            
            Y = vocoderDiscCompFunc(X, obj);
            obj.updateModified(true);
            
            obj.setOutput(1,Y);
        end
    end
end