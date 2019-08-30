% AudioMixerUnit < ProcUnit
% Mixes any number of input audio signals into a single output signal. For
% every signal, the target level as well as the target level type have to
% be specified (abs. rms/abs. peak/rel. to input). sensIn defines the peak
% SPL equivalent to 0dB FS. wrap controls the behaviour of input signals
% are of unequal length (warp-around or zero-pad to match duration of the
% primary signal). For wrap = 1, durFade controls the duration of
% a cosine-shaped cross-fade between the end and beginning.
% 
% Input Ports: variable
%   
% Output Ports:
%   #1  - column vector contained wav data
% 
% AudioMixerUnit Properties:
%  *sensIn   - input sensitivity: peak amplitude in dB SPL corresponding to 
%              digital full scale (default is 111.6dB SPL peak for Harmony,
%              equivalent to 108.59dB SPL RMS for sine input)
%  *lvlType  - string or cell array of strings: 'rms' / 'peak' / 'rel';
%              if string, same type is used for all channels;
%              if cell aray, the size must match n
%  *lvlDb    - scalar or n-vector of levels per channel in dB; for types 'rms'
%              and 'peak', lvlDb(i) is in dB SPL; for type 'rel', lvlDb(i) is
%              in dB relative to the input level.
%              If a scalar is provided, a "master gain" is derived for the 
%              primary input (see below) applied to all channels equally.
%              If no primary input is specified ([]), input 1 is used to
%              determine the master gain.
%  *delays   - vector of onset delays for each input [s]
%  *primaryIn - which input determines the length of the mixed output
%               (1..nInputs, or []); if [], the longtest input (including
%               delay) is chosen as primary.
%  *wrap     - repeat shorter inputs to match duration of the longest
%              input? [1/0]
%  *durFade  -  duration of cross-fade when wrapping signals [s]
%  *clip     - read-only indicator: did clipping occur during the most recent
%              call of run()? [0/1]
%  clipValue - output amplitude at which signal is considered to clip [>0]; default: 1   
%
% AudioMixerUnit Methods:
%    AudioMixerUnit - constructor
%
% See also: audioMixerFunc

% Change log:
% 29/08/2012, P.Hehrmann - created
% 09/12/2012, PH - added 'delays' and 'primaryIn' and 'clip'; cf. audioMixerFunc.m
% 08/01/2015, PH - use getInput/setOutput instead of getData/setData
% 22/01/2015, RK - Scaled input components as output for visualization
% 16/02/2015, PH - set sensIn default to 111.6dB SPL peak according to 
%                  Harmony signal path spec (signal before pre-emphasis
%                  is at digital FS for sine input of 108.59dB SPL RMS) 
% 01/06/2015, PH - adapted to May 2015 framework: removed shared props
% 23/Jun/2017, PH - SetObservable properties
% 27/11/2017, PH - option to compute gain for one "master channel" and 
%                  apply to all channels equally 
% 17 Apr 2018, PH - added clipValue property 
classdef AudioMixerUnit < ProcUnit
    
    properties (SetObservable)
        lvlDb; % n-vector of levels per channel in dB
        lvlType = 'rms'; % string or cell array of strings: 'rms' / 'peak' / 'rel';
        sensIn = 111.6;  % input sensitivity: peak dB SPL equivalent to digital FS (default: 111.6 dB)
        wrap = 0; % repeat shorter inputs to match duration of the longest? (default: 0)
        durFade = 0; % duration of cross-fade when wrapping signals [s] (default: 0 s)
        delays = []; % vector of onset delays for each input [s] (default: none)
        primaryIn = []; % index of primary input which determines overall length ([] = longest) (default: []) 
        clipValue = 1; % output amplitude at which signal is considered to clip [>0]; default: 1 
    end
    
    properties(SetAccess=private)
        clip = 0; % flag: did clipping occur during the most recent call of run() ? [0/1]
    end
    
    methods
        function obj = AudioMixerUnit(parent, ID, nInputs, lvlDb, lvlType, sensIn, delays, primaryIn, wrap, durFade)
            %  obj = AudioMixerUnit(parent, ID, nInputs, lvlDb, lvlType, sensIn, delays, primaryIn, wrap, durFade)
            
            % declare required shared props
            obj = obj@ProcUnit(parent, ID, nInputs, nInputs+1);
            
            % set class properties
            assert(length(lvlDb) == nInputs || isscalar(lvlDb), 'length(lvlDb) must be 1 or match nInputs.');
            obj.lvlDb = lvlDb;
            
            if nargin > 4
                assert(ischar(lvlType) || ...
                    (iscell(lvlType) && length(lvlType) == nInputs) && all(cellfun(@ischar,lvlType)), ...
                    'lvlType must be either a string of a cell array of strings of length nInputs.');
                obj.lvlType = lvlType;
            end
            
            if nargin > 5
                assert(isscalar(sensIn), 'sensIn must be a scalar.');
                obj.sensIn = sensIn;
            end
            
            if nargin > 6
                assert(isempty(delays) || (length(delays)==nInputs),...
                    'Length of delays must be 0 or equal to nInputs.');
                assert(all(delays >= 0), 'Delays must be non-negative.');
                obj.delays = delays;
            end
            
            if nargin > 7
                assert(isempty(primaryIn) || (primaryIn > 0 && primaryIn <= nInputs && ~mod(primaryIn,1)), ...
                    'primaryIn must be empty or an integer between 1 and nInputs.');
                obj.primaryIn = primaryIn;
            end
            
            if nargin > 8 
                assert(isscalar(wrap), 'wrap must be scalar (should be logical or 0/1).');
                obj.wrap = wrap;
            end
            
            if nargin > 9
                assert(isscalar(durFade) && durFade >= 0, 'durFade must be a positive scalar.')
                obj.durFade = durFade;
            end

        end
        
        function [Y WavIn clipping] = run(obj)
            
            % get all inputs
            X = cell(1,obj.inputCount);
            for iIn = 1:obj.inputCount
                X{iIn} = obj.getInput(iIn);
            end
            
            % call processing routine
            [Y WavIn clipping] = audioMixerFunc(X{:}, obj);
            
            % set output
            obj.setOutput(1, Y);
            
            for iOut = 1:length(WavIn)
                obj.setOutput(iOut+1, WavIn{iOut});
            end
            
            % set clipping flag
            obj.clip = clipping;
        end
    end
end