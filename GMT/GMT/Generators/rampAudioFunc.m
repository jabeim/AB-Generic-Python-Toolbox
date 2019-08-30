% sOut = rampAudioFunc(par, sIn)
% Apply onset and/or offset ramp to input audio data
%
% INPUT:
%   par - parameter object / struct
%   sIn - input audio vector 
% OUTPUT:
%   sOut - output audio vector (same length as input)
% FIELDS FOR PAR: 
%   parent.fs - sample rate [Hz]    
%   durRampOn  - onset ramp duration (included in total) [sec] 
%   durRampOff - offset ramp duration (included in total) [sec]
%   rampTypeOn  - onset ramp shape: 'lin'/'cos'/'cos2'/'zero' 
%   rampTypeOff - onset ramp shape: 'lin'/'cos'/'cos2'/'zero' 
%
% Change log:
% 17/08/2015, PH - created
% 13 Jul 2017, PH - added 'zero' ramp option
% 25 May 2018, PH - fix input/ramp dimension issues

function s = rampAudioFunc(par, s)

fs = par.parent.fs;

if par.durRampOn > 0
    lenRampOn = round(fs*par.durRampOn);
    rampOn = genOnsetRamp(par.rampTypeOn, lenRampOn);
    if size(s,2) == 1 
        rampOn = rampOn';
    end  
    s(1:lenRampOn) = s(1:lenRampOn) .* rampOn;
end

if par.durRampOff > 0
    lenRampOff = round(fs*par.durRampOff);
    rampOff = fliplr(genOnsetRamp(par.rampTypeOff, lenRampOff));
    if size(s,2) == 1 
        rampOff = rampOff';
    end
    s(end-lenRampOff+1:end) = s(end-lenRampOff+1:end) .* rampOff;
end

end

% generate ramp from 0 to 1
function ramp = genOnsetRamp(rampType, lenRamp)
    switch lower(rampType)
        case 'lin'
            ramp = linspace(0,1,lenRamp); % linear
        case 'cos'
            ramp = 0.5*(cos(linspace(-pi, 0, lenRamp))+1); % cosine
        case {'cos2','cos^2'}
            ramp = 0.25*(cos(linspace(-pi, 0, lenRamp))+1).^2; % squared cosine
        case {'zero'}
            ramp = zeros(1, lenRamp);
        otherwise
            error('Unknown ramp type: ''%s''', rampType);
    end
end