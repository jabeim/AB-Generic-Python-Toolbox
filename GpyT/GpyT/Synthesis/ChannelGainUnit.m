% ChannelGainUnit < ProcUnit
%
% Apply time-varying gains defined for a number of logical channels to a
% STFT matrix, given some user-specified mapping of channels to FFT bins.
% 
% ChannelGainUnit Properties:
%  *gainDomain  - 'linear' / 'dB' / 'log2Pow'
%  *anaMixingWeights - EITHER: nCh x nFFT analysis mixing matrix, 
%                       OR: 2-el vector (nCh, extended low?)
%                       OR: scalar, specifying the number of ch. for a F120
%                           filterbank without extended low channel
%                       OR: [] to use the filterbank specified by the 
%                           parent strategy's startBin nBinLims properties
%  *maintainUnassigned - maintain input FFT coefficients for frequency bins
%                        not mapped to a channel [boolean] [true]
%
%
% See also: channelGainFunc.m
%
% Change log:
% 16/08/2012, P.Hehrmann - created
% 25/02/2013, P.Hehrmann - added doc
% 03/09/2014, PH - added option 'maintainUnassigned' 
% 02/12/2014, PH - removed optional 'scale' input (#3) and output(#2)
% 19/12/2014, PH - 'run' adjusted to new ProcUnit interface (getInput, setOutput)
% 27 Jun 2017, PH - SetObservable properties 
classdef ChannelGainUnit < ProcUnit
    
    properties (SetObservable)
        gainDomain; % 'linear' or 'log2Pow'
        anaMixingWeights; % mapping of channels to FFT bins (see channelGainFunc.m)
        maintainUnassigned = true;
    end
    
    methods
        function obj = ChannelGainUnit(parent, ID, anaMixingWeights, gainDomain, maintain)
            
            obj = obj@ProcUnit(parent, ID, 2, 1);
                        
            obj.anaMixingWeights = anaMixingWeights;
            obj.gainDomain = gainDomain;
            
            if nargin > 4
                obj.maintainUnassigned = maintain;
            end
            
        end
        
        function run(obj)
            X = obj.getInput(2);

            if  ~obj.getInputUnit(1).dataIsEmpty
                G = obj.getInput(1);
            else
                G = []; 
            end

                        
            Y = channelGainFunc(G, X, obj);
                        
            obj.setOutput(1, Y);
        end
    end
end