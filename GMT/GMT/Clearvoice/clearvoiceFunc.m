% [G_out, A_out, Vn, Vs, Hold] = clearvoiceFunc(par, A)
%
% Compute channel-by-channel gains as in ClearVoice. The gain function is 
% implemented following specification D000001063 (L.Litvak, 2009), with 
% added freedom in choosing the shape parameters. Note that AGC gain input
% is expected at audio sample rate (firmware uses decimated gain).
%
% INPUT:
%   par - parameter object / struct
%   A - nCh x nFrames matrix of channel amplitudes (sqrt(power), linearly scaled)
%
% OUTPUT:
%   G_out - nCh x nFrames matrix of ClearVoice gains (domain determined by par.gainDomain)
%   A_out - nCh x nFrames matrix of channel amplitudes (sqrt(power), linearly scaled)
%   Vn   - nCh x nFrames matrix of noise estimates
%   Vs   - nCh x nFrames matrix of speech estimates
%   Hold - nCh x nFrames matrix of hold states
%
% FIELDS FOR PAR:
%   parent.fs   - audio sample rate [int > 0]
%   parent.nHop - FFT hop size [int > 0]
%   gainDomain - domain of gain output ['linear','db','log2'] ['linear']
%   tau_speech - time constant of speech estimator [s]
%   tau_noise - time constant of noise estimator [s]
%   threshHold - hold threshold (onset detection criterion) [dB, > 0]
%   durHold - hold duration (following onset) [s]
%   maxAtt - maximum attenuation (applied for SNRs <= snrFloor) [dB]
%   snrFloor - SNR below which the attenuation is clipped [dB]
%   snrCeil  - SNR above which the gain is clipped  [dB]
%   snrSlope - SNR at which gain curve is steepest  [dB]
%   slopeFact  - factor determining the steepness of the gain curve [> 0]
%   noiseEstDecimation - down-sampling factor (re. frame rate) for noise estimate [int > 0]
%   enableContinuous - save final state for next execution? [boolean]

% Change log:
%   30 Jan 2012, P.Hehrmann - created
%   18 Jun 2013, S.Fredelake - added additional outputs V_nOut, V_sOut
%   18 Jun 2013, PH - bug fix: reset of hold counter
%   23 Jan 2018, PH - log-domain averaging (as on real device)
%   24 Jan 2018, PH - enableContinuous flag
%   02 Aug 2019, PH - added noiseEstDecimation and gainDomain parameter 
%                   - changed function interface
%   15 Aug 2019, PH - swapped output arguments (G and A)
function [G_out, A_out, Vn_out, Vs_out, Hold_out] = clearvoiceFunc(par, A)
    
    % basic input check
    checkParamFields(par,{'tau_speech', 'tau_noise', 'durHold', 'threshHold',...
                          'maxAtt', 'snrFloor', 'snrCeil', 'snrSlope', 'slopeFact'...
                          'noiseEstDecimation', 'enableContinuous', 'gainDomain'});
    strat = par.parent;
    initState = par.initState;       
        
    noiseDS = par.noiseEstDecimation; % decimation factor for noise estimation
    dtFrame = strat.nHop/strat.fs; % frame advance [s]
    
    nCh = size(A, 1);
    nFrame = size(A, 2);
    
    alpha_s = exp(-dtFrame/par.tau_speech);  % memory weight for speech est.
    alpha_n  = exp(-dtFrame*noiseDS/par.tau_noise);  % memory weight for noise est.
    
    threshHold = par.threshHold;
    maxHold = par.durHold / (dtFrame * noiseDS);
    maxAttLin = 10^(-abs(par.maxAtt)/20);  % max. attenuation as linear factor
    gMin = 1 + (maxAttLin - 1) / (1 - 1/(1+exp(-par.slopeFact * (par.snrFloor - par.snrSlope))));
   
    % define gain function given parameters in par
    function g__ = cvGainFunc(SNR) % CV gain function according to spec
        SNR = min( max(SNR, par.snrFloor), par.snrCeil);
        g__ = gMin + (1-gMin)./(1+exp(-par.slopeFact*(SNR-par.snrSlope)));
    end
   
    G = NaN(nCh, nFrame);
    Vs_out = NaN(nCh, nFrame);
    Vn_out = NaN(nCh, nFrame);
    Hold_out = NaN(nCh, nFrame);
       
    logA = max(-100, 20*log10(A));
    
    % set initial state
    V_s = zeros(nCh, 1);
    V_n = zeros(nCh, 1);
    Hold = false(nCh, 1);
    HoldReady = true(nCh, 1);
    HoldCount = zeros(nCh, 1) + maxHold;        
    if ~isempty(initState) % overwrite initial state variables, if supplied
        par.retrieveVarFromStruct(initState); 
    end
    
    for iFrame = 1:nFrame
        % speech energy estimation
        V_s =  alpha_s*V_s + (1-alpha_s)*logA(:,iFrame);
        
        if (mod(iFrame-1, noiseDS) == noiseDS-1)
            
            % noise energy estimation
            maskSteady = (V_s - V_n) < threshHold;   % no significant increase of noise
            maskOnset = ~maskSteady & HoldReady;     % onset of noise increase
            maskHold  = ~maskSteady & ~HoldReady & Hold; % hold state after onset
            
            maskUpdateNoise = maskSteady | (~maskSteady & ~HoldReady & ~Hold);
            
            
            V_n(maskUpdateNoise) =       alpha_n*V_n(maskUpdateNoise) ...
                + (1-alpha_n)*V_s(maskUpdateNoise);
            
            % housekeeping of state variables
            Hold(maskOnset) = true;
            HoldReady(maskOnset) = false;
            HoldCount(maskOnset) = maxHold;
            
            HoldCount(maskHold) = HoldCount(maskHold)-1;
            Hold(maskHold & (HoldCount <= 0)) = false;
            
            Hold(maskSteady) = false;
            HoldReady(maskSteady) = true;
        end
   
        % compute gains
        SNR = V_s - V_n;
        G(:,iFrame) = cvGainFunc(SNR);
        Vn_out(:,iFrame) = V_n;
        Vs_out(:,iFrame) = V_s;
        Hold_out(:, iFrame) = Hold;
    end
    
    % apply gains
    A_out = A .* G;
    
    switch lower(par.gainDomain)
        case {'linear','lin'}
            G_out = G;
        case 'db'
            G_out = 20*log10(G);
        case {'log2','log'}
            G_out = 2*log2(G);
        otherwise            
            error('Illegal value for gainDomain');
    end
    
    if par.enableContinuous % set initial states for next run
        %initState.V_s = V_s;
        %initState.V_n = V_n;
        %initState.Hold = Hold;
        %initState.HoldReady = HoldReady;
        %initState.HoldCount = HoldCount;
        par.initState = par.saveVarToStruct('V_s','V_n','Hold','HoldReady', 'HoldCount');
    end
    
end