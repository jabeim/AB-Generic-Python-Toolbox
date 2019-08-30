% signalIn = readWavFunc(par)
%
% Read wav data from file. 
%
% INPUT:
%   par  - parameter object / struct
%
% FIELDS FOR PAR:
%   parent.fs - desireed output sampling frequency (Hz)
%   wavFile - name of wav-file (used of readWavFunc is called with a single arguement)
%   tStartEnd - 2-el vector defining start and end time of section to be read; sec
%   iChannel - index of channel to be returned [integer]
%
% OUTPUT:
%   signalIn - samples of wav-file

% Change log:
%  Apr 2012, M. Milczynski - created
%  14 Jan 2013, PH - wav file can now be specified either by an input
%                DataUnit (previous behavior), or by property 'wavFile' 
%                (new behavior); might deprecate old behavior for
%                release version
%  09 Apr 2013, PH - improved backwards compatibility with Matlab
%  09/01/2015, PH - removed option to specify name as individual argument
%  18/01/2015, PH - add property tStartEnd to ReadWavUnit
%  14/04/2015, PH - use audioread for Matlab >= 2012b (wavread otherwise)
%  29/05/2015, PH - adapted to May 2015 framework: shared props removed
%  29/02/2016, PH, added iChannel and "auto" file extension
function signalIn = readWavFunc(par)

name = par.wavFile;
stratFs = par.parent.fs;

v = version; % get Matlab version
if sscanf(v,'%d') < 8  % before Matlab 2012b -> wavread
    [signalIn, srcFs] = wavread(name);    
else
    
    [path body ext] = fileparts(name);
    if isempty(ext)
        name = [name, '.wav'];
    end
    
    [signalIn, srcFs] = audioread(name);  % 2012b or later -> audioread
end

signalIn = signalIn(:,par.iChannel);

if ~isempty(par.tStartEnd)
    iStartEnd = round(par.tStartEnd(:)*srcFs) + [1; 0];
    signalIn = signalIn(iStartEnd(1) : iStartEnd(2));
end

if srcFs ~= stratFs
    signalIn = resample(signalIn, stratFs, srcFs); 
end

