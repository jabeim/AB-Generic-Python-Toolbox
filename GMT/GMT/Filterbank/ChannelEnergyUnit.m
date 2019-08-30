% ChannelEnergyUnit < SubsampProcUnit
% Estimate the frame-by-frame channel energy of an FFT-based filterbank.
% Filterbank channels are defined by the parameters of the parent
% FftStrategy object.
% 
% Properties
%    gainDomain - domain of gain input on port #2 (if applicable) ['linear','db','log2'] ['linear']
%
% Input Ports:
%    #1  - FFT coefficient matrix, nFreq x nFrames
%   [#2] - AGC gain to be compensated in power calculation, 
%          1 x nFrames or 1 x nSamples, where nFrames ~~ nSamples/nHop (optional)
%
% Output Ports:
%    #1  - linear envelopes (nCh x nFrames)
%   [#2] - FFT bin index with highest power per channel (nCh x nFrames)
%
% See also: channelEnergyFunc, SubsampProcUnit, ProcUnit, FftStrategy

% Change log:
% 21/10/2015, PH - created
% 21/Jun/2017, PH - SetObservable properties
% 05/Aug/2019, PH - re-purpose for simple energy estimation (cf. FftFilterbankEnvUnit)
classdef ChannelEnergyUnit < SubsampProcUnit
    
    properties(SetObservable)
        gainDomain = 'linear';  % domain of gain input on port #2 (if applicable) ['linear','db','log2'] ['linear']
    end
    
    properties(Constant)
        DEF_dsFactor = 1; % default down-sampling factor [1, i.e. no downsampling] 
    end
        
    methods
        function obj = ChannelEnergyUnit(parent, ID, nInput, gainDomain, dsFactor, dsSkip)
            % obj = ChannelEnergyUnit(parent, ID [, dsFactor [, dsSkip]])
            % Class constructor.
            % Input:
            %   parent - containing FftStrategy object
            %   ID - string identifier
            %   dsFactor - down-sampling factor
            %   dsSkip - nr of initial frames to skip when downsampling
            % Output:
            %   obj - new instance of class ChannelEnergyUnit
            if nargin < 3
                nInput = 1;
            end
            if nargin < 5
                dsFactor = ChannelEnergyUnit.DEF_dsFactor;
            end
            if nargin < 6
                dsSkip = dsFactor-1;
            end
            
            obj = obj@SubsampProcUnit(parent, ID, nInput, 1, dsFactor, dsSkip);
            
            if nargin > 3
                obj.gainDomain = gainDomain;
            end
        end
        
        function run(obj)
            STFT = obj.getInput(1);
            if obj.inputCount > 1
                gAgc = obj.getInput(2);
            else
                gAgc = [];
            end            
            engy = channelEnergyFunc(obj, STFT, gAgc);                
            obj.setOutput(1, engy);                   
        end
    end
end