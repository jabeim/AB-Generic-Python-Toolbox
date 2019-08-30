% HarmonyPreemphasisUnit < TdFilterUnit
% Harmony pre-emphasis filter (IIR). Filter coefficients are:
%     coeffNom   = [0.7688   -1.5376    0.7688]
%     coeffDenom = [1.0000   -1.5299    0.5453]
% Assumes fs = 17400 Hz. 
%
% Input Ports:
%   #1 - input audio signal vector
% 
% Output Ports:
%   #1 - filtered audio signal

% Change log:
% 16/04/2012 P.Hehrmann - created
% 09/10/2015, PH - adjusted spelling of parent class
classdef HarmonyPreemphasisUnit < TdFilterUnit
    properties (Constant)
        HARMONY_PREEMPH_A = [1.0000   -1.5299    0.5453];
        HARMONY_PREEMPH_B = [0.7688   -1.5376    0.7688];
    end
       
    methods
        function obj = HarmonyPreemphasisUnit(parent, ID, enable)
            % obj = HarmonyPreemphasisUnit(parent, ID, enable)
            % Create new object with speficied parent and ID. 
            if nargin < 3
                enable = true;
            end
            obj = obj@TdFilterUnit(parent, ID, ...
                HarmonyPreemphasisUnit.HARMONY_PREEMPH_B, ...
                HarmonyPreemphasisUnit.HARMONY_PREEMPH_A, ...
                enable);
            
        end
    end
end