% mapFft2Ch = computeF120FilterbankWeights(nCh [, extendedLow] )
%
% Return mixing matrix for a standard F120 filterbank with user-specified
% number of channels.
%
% INPUT:
%    nCh - number of analysis channels (3..15)
%    extendedLow - use "extended low" filter bank (lowest cutoff 238 Hz) ?
%                  default = 0;
% OUTPUT:
%    mapFft2Ch - nCh x 128 mixing matrix (linear weights, 0 or 1)
%
% Change log:
%  25/07/2012, P. Hehrmann - created
%  19/03/2013, M. Milczynski - added iStart, iEnd as outputs for
%                              binToLocMap calculation
function [mapFft2Ch, iStart, iEnd] = computeF120FilterbankWeights(nCh, extendedLow)
    
    showInfo = 0;
    
    df = 17400/256;
    
    if nargin < 2
        extendedLow = 0;
    end
    
    if extendedLow
        fLowest = 238;
    else
        fLowest = 306;
    end
    
    switch(nCh)
        case 3
            fC = [fLowest,986,2005,8054];
        case 4
            fC = [fLowest,782,1393,2481,8054];
        case 5
            fC = [fLowest,714,1121,1733,2821,8054];
        case 6
            fC = [fLowest,646,918,1393,2073,3093,8054];
        case 7
            fC = [fLowest,578,850,1189,1665,2345,3364,8054];
        case 8
            fC = [fLowest,578,782,1054,1393,1869,2549,3500,8054];
        case 9
            fC = [fLowest,510,714,918,1189,1597,2073,2753,3636,8054];
        case 10
            fC = [fLowest,510,646,850,1054,1393,1801,2277,2957,3772,8054];
        case 11
            fC = [fLowest,510,646,782,986,1257,1529,1937,2481,3093,3908,8054];
        case 12
            fC = [fLowest,510,646,714,918,1121,1393,1733,2141,2617,3229,4044,8054];
        case 13
            fC = [fLowest,510,578,714,850,1054,1257,1529,1869,2277,2753,3364,4112,8054];
        case 14
            fC = [fLowest,442,578,646,782,986,1189,1393,1665,2005,2413,2889,3500,4180,8054];
        case 15
            fC = [fLowest,442,578,646,782,918,1054,1257,1529,1801,2141,2549,3025,3568,4248,8054];
        case 22
            fC = [187.5 312.5 437.5 562.5 687.5 812.5 937.5 1062.5 1187.5 1312.5 1562.5 1812.5 2062.5 2312.5 2687.5 3062.5 3562.5 4062.5 4687.5 5312.5 6062.5 6937.5 7937.5];
        otherwise
            error('Invalid number of channels');
    end
    
    iStart = NaN(1, nCh);
    iEnd = NaN(1, nCh);
    
    mapFft2Ch = zeros(nCh, 128);
    
    for iCh = 1:nCh
        iStart(iCh) = ceil(fC(iCh) / df) + 1;
        iEnd(iCh) = floor(fC(iCh+1) / df) + 1;
        mapFft2Ch(iCh,iStart(iCh):iEnd(iCh)) = 1;
    end
    
    if (showInfo)
        disp('Filterbank frequency range:');
        fprintf('     fLo = '); fprintf('%5.0f ', (iStart-1)*df); fprintf('\n');
        fprintf('     fHi = '); fprintf('%5.0f ', (iEnd-1)*df); fprintf('\n');
        fprintf('  iStart = '); fprintf('%5.0d ', iStart); fprintf('\n');
        fprintf('    iEnd = '); fprintf('%5.0d ', iEnd); fprintf('\n');
        fprintf('   nBins = '); fprintf('%5d ', iEnd-iStart+1); fprintf('\n');
    end
    
