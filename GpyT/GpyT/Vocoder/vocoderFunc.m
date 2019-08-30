% function vocFft = vocoderFunc(env, par)
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
%    envDomain  - 'linear' / 'log2Pow'
%    synthType - 'triang'/'triangLinCf'/'trapez'/'inverse'/'cf'/'cfLin'
%    synthSlope - slope in dB/oct (> 0)
%    phaseType  - 'random' / 'coherent'
%    anaMixingWeights - EITHER: nFft x nCh analysis mixing matrix, 
%                       OR: 2-el vector (nCh, extended low?)
%                       OR: scalar (nCh, extended low = 0)
%                       OR: [] to use the filterbank specified by 
%                           parent.startBin and parent.nBinLims
%    normalization - 'none' / 'power'
%
% SEE ALSO: computeSynthesisFilters.m 

% Change log:
% 25/07/2012, P.Hehrmann - created  
% 28/08/2012, P.Hehrmann - random starting phase even for coherent phases
%                          (bug fix to avoid phase interferences at the beginning
%                           of a new FFT frame in coherent phase mode)
% 12/09/2012, P.Hehrmann - allow anaMixingWeights to be a scalar (specifying
%                          #chan. for a default F120 filterbank w/o exteded low)
% 02/12/2014, PH - removed 'scale' input
% 01/06/2015, PH - adapted to May 2015 framework: removed shared props
function vocFft = vocoderFunc(env, par)
    strat = par.parent;    
    fs = strat.fs;
    nFrames = size(env,2);
    nFFT    = strat.nFft;
    nHop    = strat.nHop;
    
    if isempty(par.anaMixingWeights)
        anaMap = binLimsToMixingWeights(strat.startBin, strat.nBinLims, floor(nFFT/2));
    elseif isscalar(par.anaMixingWeights)
        anaMap = computeF120FilterbankWeights(par.anaMixingWeights, 0);
    elseif isvector(par.anaMixingWeights)
        anaMap = computeF120FilterbankWeights(par.anaMixingWeights(1), par.anaMixingWeights(2));
    else
        anaMap = par.anaMixingWeights;
    end

    assert(size(env,1) == size(anaMap,1), 'Mismatched dimensions: size(env,1) != size(map,2)');
    
    synthMap = computeSynthesisFilters(par.synthType, par.synthSlope, nFFT, fs, anaMap, par.normalization);
   
    % linear or log2-envelope?
    switch lower(par.envDomain)
        case {'linear','lin'}
            % nothing
        case {'log2pow'}
            env = 2.^(0.5*env);
        otherwise
            error('Illegal argument: par.envDomain == ''%s''',par.envDomain);
    end

    % check for non-negative envelope    
    assert(all(env(:) >= 0), 'Envelope values must be non-negative');
    
    % Generate phase spectrum: 
    % Start off with coherent phases, then add "phase noise" such that 
    % after one full FFT bin, phases are completely independent. Use linear 
    % interpolation of the phase noise for each FFT hop. Not the true 
    % distribution of overlapping-STFT phases of white noise, but 
    % presumably good enough.
    switch lower(par.phaseType)
        case{'random'}
            T0 = 0 : nFFT/2 : nFrames*nHop+nFFT;
            phi0 =  rand(length(T0), floor(nFFT/2)) * 2*pi; % completely indep. phases for non-overlapping FFT frames
            phi_rnd = mod(interp1(T0, phi0, (0:nFrames-1)*nHop),2*pi)' - pi; % interpolation for overlapping FFT frames inbetween the independent ones
            T = nHop * (0:nFrames-1);   % / fs; % fs cancels with T
            F = 1/nFFT * (0 : floor(nFFT/2)-1)'; % * fs; % fs cancels with F
            phi_co = F * T* 2*pi; % coherent phase progression
            phi = phi_co + phi_rnd; % add coherent and random phases 
        case{'coherent'}
            T = nHop * (0:nFrames-1);   % / fs; % fs cancels
            F = 1/nFFT * (0 : floor(nFFT/2)-1)'; % * fs; % fs cancels
            phi0 = rand(floor(nFFT/2),1)*2*pi; % random starting phases
            phi = repmat(phi0, 1, length(T)) +  F * T* 2*pi;  % coherent progression
        otherwise
            error('Illegal Argument: par.phaseType == %s',par.phaseType);
            
    end
    
    vocFft = (synthMap * env) .* exp(1i * phi);
    
end

