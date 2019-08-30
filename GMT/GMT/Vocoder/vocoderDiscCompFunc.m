% function vocFft = vocoderDiscFunc(env, par)
%  FFT-based vocoder, receiving channel envelopes as input, returning FFT 
%  coefficients as output.  The FFT amplitudes are deterministically
%  determined from the channel envelopes by a linear mapping matrix. The
%  phases can either be random or coherent from bin to bin. For random 
%  phases, the vocoder attempts to match the phase characteristics of a
%  STFT of Gaussian white noise. Filter shapes can be triangular,
%  trapezoidal, or CF-only, with a user-specified filter slope. Filters can
%  be normalised to exactly preserve the power of the input (assuming that
%  the envelope represents the input intensity within the corresponding band).
%
% FIELDS FOR PAR:
%    parent.fs   - sampling rate
%    parent.nFft - FFT length
%    parent.nHop - FFT hop size
%   [parent.startBin - first FFT bin in lowest filter] needed if anaMixingWeights = [] 
%   [parent.nBinLims - number of FFT bins per channel]   "              "
%    envDomain  - 'linear' / 'log2Pow' / 'dB'
%    synthType - 'triang'/'triangLinCf'/'trapez'/'inverse'/'cf'/'cfLin'
%    synthSlope - slope in dB/oct (> 0)
%    phaseType  - 'random' / 'coherent' / 'alpha'
%    anaMixingWeights - EITHER: nFft x nCh analysis mixing matrix, 
%                       OR: 2-el vector (nCh, extended low?)
%                       OR: scalar (nCh, extended low = 0)
%                       OR: [] to use the filterbank specified by 
%                           parent.startBin and parent.nBinLims
%    normalization - 'none' / 'power'
%    compressionRatio - static envelope compression ratio [dB/dB]
%    pivotLevel - level in dB re. 1 around which compression is centered;
%    idrTopLvl  - nominal top of IDR range (excl. headroom) [dB re. 1]
%    idrWidth - input dynamic range below AGC kneepoint [dB]
%    idrHeadroom - IDR headroom above AGC kneepoint [dB]
%    stepSize - discretization step size [dB]
%    aboveIdrMode - processing when IDR headroom exceeded: 'nop' / 'bound'
%    belowIdrMode - processing when lower IDR limit exceeded: 'nop' / 'bound' / 'zero';
%    enableContinuous - enable storing of DSA and ZASTA state for continuous repeated processing
%    randGen - RandStream object (to be used as random generator if applicable)
%
% SEE ALSO: computeSynthesisFilters.m, RandStream

% Change log:
% 14/10/2013 - feature: envelope discretization (equidistant steps in log-domain)
% 02/12/2014, PH - removed 'scale' input
% 10/05/2015, PH - adapted to May 2015 framework: removed shared props
% 09/03/2018, PH - enableContinuous option; new phase mode 'alpha' 
function vocFft = vocoderDiscCompFunc(env, par)
    strat = par.parent;    
    fs = strat.fs;
    nFrames = size(env,2);
    nFft    = strat.nFft;
    nBins   = floor(nFft/2);
    nHop    = strat.nHop;
    randGen = par.randGen;
    
    if isempty(par.anaMixingWeights)
        anaMap = binLimsToMixingWeights(strat.startBin, strat.nBinLims);
    elseif isscalar(par.anaMixingWeights)
        anaMap = computeF120FilterbankWeights(par.anaMixingWeights, 0);
    elseif isvector(par.anaMixingWeights)
        anaMap = computeF120FilterbankWeights(par.anaMixingWeights(1), par.anaMixingWeights(2));
    else
        anaMap = par.anaMixingWeights;
    end

    assert(size(env,1) == size(anaMap,1), 'Mismatched dimensions: size(env,1) != size(map,2)');
    
    synthMap = computeSynthesisFilters(par.synthType, par.synthSlope, nFft, fs, anaMap, par.normalization);
   
    % linear or log2-envelope?
    % Converting input env in dB
    switch lower(par.envDomain)
        case {'linear','lin'}
            % nothing
        case {'log2pow'}
            env = 2.^(0.5*env);
        case {'db'}
            env = 10.^(env/20);
        otherwise
            error('Illegal argument: par.envDomain == %s',par.envDomain);
    end

    % check for non-negative envelope    
    assert(all(env(:) >= 0), 'Envelope values must be non-negative');
    
    % Generate phase spectrum: 
    % Start off with coherent phases, then add "phase noise" such that 
    % after one full FFT bin, phases are completely independent. Use linear 
    % interpolation of the phase noise for each FFT hop. Not the true 
    % distribution of overlapping-STFT phases of white noise, but 
    % presumably good enough.
    if isempty(par.initState) || isempty(par.initState.phi0)
        phi0 = 2*pi* randGen.rand(nBins,1);
    else
        phi0 = par.initState.phi0;
    end
    
    switch lower(par.phaseType)
        case{'random'}           
            dPhi = 2*pi*nHop/nFft * (0 : nBins-1)'; 

            T = nHop * (0:nFrames);
            T_support = 0: nFft :  nFrames*nHop+nFft;          
            phi_rnd_support = [phi0'; randGen.rand(length(T_support)-1, nBins) * 2*pi];
            phi_rnd_support = unwrap(phi_rnd_support, [], 1);

            phi = bsxfun(@times, dPhi, 0:nFrames);  % coherent component  
            phi = phi + interp1(T_support, phi_rnd_support, T)';  % random component        
                   
        case{'coherent'}
            dPhi = 2*pi*nHop/nFft * (0 : nBins-1)';
            phi = bsxfun(@times, dPhi, 0:nFrames);  % coherent component
            phi = repmat(phi0, 1, nFrames+1) + phi;
        
        case{'','alpha'}
            if par.alpha == 1
                phi = [phi0, 2*pi*(randGen.rand(nBins, nFrames)-0.5)];
            elseif par.alpha == 0
                dPhi = 2*pi*nHop/nFft * (0 : nBins-1)';
                phi = bsxfun(@times, dPhi, 0:nFrames);  % coherent component            
                phi = repmat(phi0, 1, nFrames+1) + phi;    
            else
                dPhi = 2*pi*nHop/nFft * (0 : nBins-1)';
                phi = bsxfun(@times, dPhi, 0:nFrames);  % coherent component            
                phi = repmat(phi0, 1, nFrames+1) + phi;
                
                phi = phi + [zeros(nBins,1), par.alpha * cumsum(2*pi*(randGen.rand(nBins, nFrames)-0.5), 2)];
            end
        otherwise
            error('Illegal Argument: par.phaseType == %s',par.phaseType);      
    end
    
    % discretize channel envelopes

    env = 20*log10(env) - par.idrTopLvl;
    env(~isfinite(env)) = -160;
    
    % alter values outside IDR as specified
    switch par.belowIdrMode
        case {'nop','none',''}
        case 'bound'
            env = max(env, -par.idrWidth);
        case 'zero'
            maskZero = env < -par.idrWidth;
            env(maskZero) = -160;
        otherwise
            error('Unknown belowIdrMode ''%s''',par.belowIdrMode);
    end
    switch par.aboveIdrMode
        case {'nop',''}
        case 'bound'
            env = min(env, par.idrHeadroom);
        otherwise
            error('Unknown aboveIdrMode ''%s''',par.aboveIdrMode);
    end
   
    % discretize envelopes as specified
    nCh = size(env,1);
    if ~isempty(par.stepSize) && ~(par.stepSize==0)
        minDb = min(env(isfinite(env(:)))) - 2*par.stepSize;
        maxDb = max(env(:)) + 2*par.stepSize;
        stepsDb = [fliplr(0:-par.stepSize:minDb), par.stepSize:par.stepSize:maxDb];
        for iCh = 1:nCh
            env(iCh,:) = interp1(stepsDb, stepsDb, env(iCh,:), 'nearest');
        end
    end
    
    % static envelope compression
    CR = par.compressionRatio;
    if ~isempty(CR) && (CR ~= 1)
        env = env / CR; % compress in log domain
    end
 
    env = 10.^((env + par.idrTopLvl)/20); % back to linear domain
     
    vocFft = (synthMap * env) .* exp(1i * phi(:,1:end-1));
    
    if par.enableContinuous
        par.initState.phi0 = phi(:,end);
    end
    
end

