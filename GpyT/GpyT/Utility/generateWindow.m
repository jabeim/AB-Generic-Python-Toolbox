function window = generateWindow(wName, wLength)
% Generate data window.
% INPUT:
%    wName - name of window (string) or function handle;  
%            As a string, wName can either be the name of an existing Matlab
%            function (e.g. 'hann', 'hamming', 'blackman') or one of the following:
%              'blackHann' - mean of a hann and a blackman window
%              'kaiser' - Kaiser window with beta=2.5
%              'rect' - rectangular with amp. 1
%            As a handle, the function must accept the window length as (its only) parameter          
%    wLength - window length
% OUTPUT:
%    window - generated data window
%
% Change log:
% 2012, MM/PH - created
% 19 Dec 2014, PH - removed case sensitivity
% 04 Jun 2018, PH - added option to specify function handle 

if isa(wName, 'function_handle')
    window = feval(wName, wLength);
    return
end

switch lower(wName)
    case 'blackhann'
        window = 1/2*(hanning(wLength) + blackman(wLength));
    case 'blackhanndisc'
        window = round((hanning(wLength) + blackman(wLength))*2^14)/2^15;
    case 'kaiser'
        window = kaiser(wLength, 2.5);
    case 'rect'
        window = ones(wLength, 1);
    otherwise
        window = feval(wName, wLength);
end