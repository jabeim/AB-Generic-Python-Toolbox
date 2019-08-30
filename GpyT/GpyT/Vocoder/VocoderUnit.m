% VocoderUnit < ProcUnit
% FFT-based vocoder. Given time-varying amplitude envelopes for a number of 
% channels, the vocoder generates STFT-coefficients by applying each
% envelopes to the FFT bins constituting the respective channel (defined by
% anaMixingWeights). The shape of the synthesis channels can differ from
% the analysis channels used for computing the envelopes. Shape options
% include: inverse-analysis, triangular around CF, trapezoidal around
% pass-band, CF only. The phase progression across successive FFT frames 
% be either random or coherent. Together, this allows for both noise- and
% tone-vocoding. Synthesis filters can be normalised to exactly preserve 
% the power of the input (assuming that the input envelope represents the 
% input intensity within the corresponding band).
%
% VocoderUnit properties:
%  *envDomain - envelope domain:  'linear' / 'log2Pow'
%  *synthType - shape of synthesis channels: 'triang'/'triangLinCf'/'trapez'/'inverse'/'cf'/'linCf'
%  *synthSlope - synthesis channel slope [dB/oct] (irrelevant for types 'inverse'/'cf'/'linCf')
%  *phaseType - phase progression across FFT frames: 'random' / 'coherent'
%  *anaMixingWeights - analysis filters EITHER: nFft x nCh analysis mixing matrix, 
%                      OR: 2-el vector (nCh, extended low?), OR: scalar (nCh, extended low = 0),
%                      OR: [] to use the filterbank specified by shared
%  *normalization; % normalise synthesis filters? 'none' / 'power' 
%
% VocoderUnit methods:
%   VocoderUnit - constructor
%   run - execute processing
%
% See also: vocoderFunc.m

% Change log:
% 25/07/2012, P.Hehrmann - created  
% 28/08/2012, P.Hehrmann - added documentation
% 12/09/2012, P.Hehrmann - updated documentation (see change in vocoderFunc.m)
% 10/12/2012, PH - bug fix: default option for nInputs
% 02/12/2014, PH - removed optional 'scale' input (#2)
% 09/01/2015, PH - use getInput /setOutput instead getData/setData
% 01/06/2015, PH - adapted to May 2015 framework: removed shared props
% 27 Jun 2016, PH - SetObservable properties 
classdef VocoderUnit < ProcUnit
    
    properties (SetObservable)
        envDomain; % envelope domain:  'linear' / 'log2Pow'
        synthType; % shape of synthesis channels: 'triang'/'triangLinCf'/'trapez'/'inverse'/'cf'/'linCf'
        synthSlope; % synthesis channel slope [dB/oct] (irrelevant for types 'inverse'/'cf'/'linCf')
        phaseType;  % phase progression across FFT frames: 'random' / 'coherent'
        anaMixingWeights; % analysis filters EITHER: nFft x nCh analysis mixing matrix, OR: 2-el vector (nCh, extended low?), OR: scalar (nCh, extended low = 0), OR: [] to use the filterbank specified by shared
        normalization; % normalise synthesis filters? 'none' / 'power'
    end
    
    methods
        function obj = VocoderUnit(parent, ID, anaMixingWeights, envDomain, synthType, synthSlope, phaseType, normalization)
            % obj = VocoderUnit(parent, ID, anaMixingWeights, envDomain, synthType, synthSlope, phaseType, normalization)
            % See VocoderUnit class documentation for argument details
            obj = obj@ProcUnit(parent, ID, 1, 1);
            
            obj.anaMixingWeights = anaMixingWeights;
            obj.envDomain = envDomain;
            obj.synthType = synthType;
            obj.synthSlope = synthSlope;
            obj.phaseType = phaseType;
            obj.normalization = normalization;
            
        end
        
        function run(obj)
            X = obj.getInput(1);
            
            Y = vocoderFunc(X, obj);
            
            obj.setOutput(1, Y);
        end
    end
end