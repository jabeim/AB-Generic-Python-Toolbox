function ampWords = f120MappingFunc(par, carrier, env, weights, idxAudioFrame)
% ampWords = f120MappingFunc(par, carrier, env, weights, idxAudioFrame)
%
% Map envelope amplitudes to elec stimulation current according to 
%   f(x)  = (M-T)/IDR * (x - SAT + 12dB + IDR + G)) + T 
%         = (M-T)/IDR * (x - SAT + 12dB + G) + M
% with  
%       x - envelope value  [dB]  (per electode and frame)
%       M - electric M-Level [uA] (per electrode)
%       T - electric T-Level [uA] (per electrode)
%     IDR - input dynamic range [dB] (per electrode)
%       G - gain [dB] (per electrode)
%     SAT - the envelope saturation level [dB] 
% and apply fine-structure carrier signal. See Nogueira et al. (2009) for details.    
% 
% INPUT:
%   carrier - nChan x nFtFrame matrix of carrier signals (range 0..1), sampled at FT rate 
%   env - nChan x nAudFrame matrix of channel envelopes (log2 power) 
%   weights - 2*nCh x nAudFrame matrix of current steering weights (in [0,1]) 
%   idxAudioFrame - index of corresponding audio frame corresponding to 
%                   each FT (forward telemetry) frame / stimulation cycle
%
% FIELDS FOR PAR:
%   parent.nChan - number of envelope channels   
%   mapM - M levels, 1 x nEl [uA]
%   mapT - T levels, 1 x nEl [uA]
%   mapIdr - IDRs, 1 x nEl [dB]
%   mapGain - electrode gains, 1 x nEl [dB] 
%   mapClip - clipping levels, 1 x nl [uA] 
%   chanToElecPair - 1 x nChan vector defining mapping of logical channels
%                    to electrode pairs (1 = E1/E2, ...)
%   carrierMode - how to apply carrier [0/1/2] [default: 1]
%                   0 - don't apply carrier (i.e. set carrier == 1)
%                   1 - apply to channel envelopes (mapper input)  [default]
%                   2 - apply to mapped stimulation amplitudes (mapper output)
%
% OUTPUT:
%   ampWords - 30 x nFrames vector of current amplitudes with 2 successive 
%              rows for each of the 15 physical electrode pairs; muAmp

% Change log:
% 04/05/2015, PH - created
% 07/22/2019, PH - add carrierMode parameter,
%                  refactoring and code documentation
strat    = par.parent;
M        = par.mapM;
T        = par.mapT;
IDR      = par.mapIdr;
Gain     = par.mapGain;
Map_Clip = par.mapClip;
chan2el  = par.chanToElecPair;
carrierMode = par.carrierMode;

nChan = strat.nChan;
nFtFrames = length(idxAudioFrame);

mSat = 30 * 10*log(2)/log(10);  % max. envelope is 30 log2 (power) units 
Map_A    = (M - T) ./ IDR;      % slope of mapping function, f(x) = A*x + K
Map_K    = M + (M - T) ./ IDR .* (-mSat + 12 + Gain);  % offset of mapping function, s.th. AGC knee-point is mapped to electric M-level for Gain=0

env = env .* 10*log(2)/log(10) ;  % combine envelopes and carrier and rescale to dB 

ampWords = zeros(30, nFtFrames);
for iChan = 1:nChan
    iElLo = chan2el(iChan);  % low stim. electrode nr. of current pair
    iElHi = iElLo + 1;       % high stim. electrode   
    iAmpLo = iElLo * 2 - 1;  % index of low electrode in ampWords array
    iAmpHi = iAmpLo + 1;     % index of high electrode in ampWords array
    % apply carrier signal (temporal fine structure)
    switch carrierMode
        case 0  % ignore carrier, no fine structure applied
            mappedLo = Map_A(iElLo) * env(iChan, idxAudioFrame) + Map_K(iElLo);
            mappedHi = Map_A(iElHi) * env(iChan, idxAudioFrame) + Map_K(iElHi);
        case 1  % apply carrier to mapper input 
            mappedLo = Map_A(iElLo) * (env(iChan, idxAudioFrame) .* carrier(iChan, :)) + Map_K(iElLo);
            mappedHi = Map_A(iElHi) * (env(iChan, idxAudioFrame) .* carrier(iChan, :)) + Map_K(iElHi);
        case 2  % apply carrier to mapper output
            mappedLo = (Map_A(iElLo) * env(iChan, idxAudioFrame) + Map_K(iElLo)) .* carrier(iChan, :);
            mappedHi = (Map_A(iElHi) * env(iChan, idxAudioFrame) + Map_K(iElHi)) .* carrier(iChan, :);
    end    
    % enforce floor and ceiling limits 
    mappedLo = max( min(mappedLo, Map_Clip(iElLo)), 0 );
    mappedHi = max( min(mappedHi, Map_Clip(iElHi)), 0 );
    % apply current steering weights
    ampWords(iAmpLo, :) = mappedLo .* weights(iChan, idxAudioFrame);
    ampWords(iAmpHi, :) = mappedHi .* weights(iChan + nChan, idxAudioFrame);
end

