% ClearvoiceUnit < ProcUnit
%
% Compute channel-by-channel gains as in ClearVoice. This unit can be used 
% with 1 to 4 outputs (see below). The gain function is  implemented 
% following specification D000001063  (L.Litvak, 2009), with  added freedom
% in choosing the shape parameters of the gain function.
%
% Input ports:
%   #1  - nCh x nFrames channel envelope matrix [sqrt(power), linearly scaled]
%
% Output ports:
%   #1  - channel gain matrix (linear, dB, or log2 power units; nCh x nFrames)
%  [#2] - modified channel envelope matrix (nCh x nFrames)
%  [#3] - noise energy estimates (nCh x nFrames)
%  [#4] - speech enegergy estimates (nCh x nFrames)
%
% ClearvoiceUnit Properties:
%  *gainDomain - domain of gain output on port 2 (if applicable) ['linear','db','log2'] ['linear']
%  *tau_speech -  time constant of speech estimator [s] [0.0258]
%  *tau_noise - time constant of noise estimator [s] [0.219]
%  *threshHold - hold threshold (onset detection criterion) [dB, > 0] [3]
%  *durHold - hold duration (following onset) [s] [1.6]
%  *maxAtt - maximum attenuation (applied for SNRs <= snrFloor) [dB] [-12]
%  *noiseEstDecimation - down-sampling factor (re. frame rate) for noise estimate [int > 0] [1]  (firmware: 3)
%  *snrFloor - SNR below which the attenuation is clipped [dB] [-2]
%  *snrCeil  - SNR above which the gain is clipped  [dB] [45]
%  *snrSlope - SNR at which gain curve is steepest  [dB] [6.5]
%  *slopeFact  - factor determining the steepness of the gain curve [> 0] [2]
%  enableContinuous - save/restore states across repeated calls of run [bool] [false]
%
% See also: clearvoiceFunc

% Change log:
% 07 Feb 2013, P.Hehrmann - created
% 18 Jun 2013, S.Fredelake - added optional outputs 3 & 4
% 18 Jun 2013, PH - updated documentation
% 19 Dec 2014, PH - 'run' adjusted to new ProcUnit interface (getInput, setOutput)
% 04 May 2015, PH - removed unused sharep prop (NFFT)
% 02 Jul 2015, PH - adapted to May 2015 framework: removed shared props
% 21/Jun/2017, PH - SetObservable properties
% 24 Jan 2018, PH - add enableContinuous property
% 02 Aug 2019, PH - added noiseEstDecimation and gainDomain parameter 
%                 - changed ...Func interface
% 15 Aug 2019, PH - swapped clearvoiceFunc output arguments
classdef ClearvoiceUnit < ProcUnit
    properties (SetObservable)
       gainDomain = 'linear'; % domain of gain output on port 2 (if applicable) ['linear','db','log2'] ['linear']
       tau_speech = 0.0258 % time constant of speech estimator [s] [0.0258]
       tau_noise = 0.219   % time constant of noise estimator [s] [0.219]
       threshHold = 3      % hold threshold (onset detection criterion) [dB, > 0] [3]
       durHold = 1.6       % hold duration (following onset) [s] [1.6]
       maxAtt = -12        % maximum attenuation (applied for SNRs <= snrFloor) [dB] [-12]
       snrFloor = -2       % SNR below which the attenuation is clipped [dB] [-2]
       snrCeil = 45        % SNR above which the gain is clipped  [dB] [45]
       snrSlope = 6.5      % SNR at which gain curve is steepest  [dB] [6.5]
       slopeFact = 0.2     % factor determining the steepness of the gain curve [> 0] [0.2]
       noiseEstDecimation = 1; % down-sampling factor (re. frame rate) for noise estimate [int > 0] [1]  (firmware: 3)
    end
    
    properties (SetAccess=immutable)
        enableContinuous = false; % save/restore states across repeated calls of run [bool] [false]
    end
    
    methods
        function obj = ClearvoiceUnit(parent, ID, nOutput, gainDomain, enableContinuous)
            % obj = ClearvoiceUnit(parent, ID, nOutput, gainDomain, enableContinuous)
            % Create new object with speficied parent and ID string.
            % Input:
            %    parent - parent FftStrategy object
            %    ID - string identifier 
            %    nOutput - nr. of output ports [1..4] [2] (see class description above)
            %    gainDomain - domain of gain output on port 2 (if applicable) ['linear','db','log2']
            %    enableContinuous - save/restore states across repeated calls of run [bool]
            if nargin < 3 || isempty(nOutput)
                nOutput = 1;
            end
            
            obj = obj@ProcUnit(parent, ID, 1, nOutput);

            if nargin > 3
                obj.gainDomain = gainDomain;
            end
            if nargin > 4    
                obj.enableContinuous = enableContinuous;
            end
        end
        
        
        function [gain, engy_out, V_nOut, V_sOut] = run(obj)
            engy = obj.getInput(1); % input envelopes
            
            [gain, engy_out, V_nOut, V_sOut] = clearvoiceFunc(obj, engy);
            
            obj.setOutput(1, gain);  % gain 
            if obj.outputCount >=2   
                obj.setOutput(2, engy_out); % modified envelopes
            end
            if obj.outputCount >= 3  
                obj.setOutput(3, V_nOut); % noise energy estimate
            end
            if obj.outputCount >= 4
                obj.setOutput(4, V_sOut);  % speech energy estimate
            end
            
        end        
    end
end