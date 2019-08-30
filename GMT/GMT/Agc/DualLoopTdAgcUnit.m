% DualLoopTdAgcUnit < ProcUnit
% Single-channel, dual-loop time-domain AGC. 
% Based on Teak model (agc17.c, agca_c.c) but using floating-point precision.
% Does not currently support changes in input sensitivity. Can be used with 
% one or two inputs. If two inputs are provided, the AGC gain is derived 
% from the second ("control signal") and applied to the first ("audio signal").
% Otherwise, audio and control signal are considered identical.
%
% DualLoopTdAgcUnit Properties:
%  *kneePt - compression threshold (in log2 power)
%  *compRatio -  compression ratio above kneepoint (in log-log space)
%  *tauRelFast - fast release [ms]
%  *tauAttFast - fast attack [ms]
%  *tauRelSlow - slow release [ms]
%  *tauAttSlow - slow attack [ms]
%  *maxHold - max. hold counter value
%  *g0 - gain for levels < kneepoint  (log2)
%  *fastThreshRel - relative threshold for fast loop [dB]
%  *clipMode   - output clipping behavior: 'none' / 'limit' / 'overflow'
%   decFact    - decimation factor
%   envBufLen  - buffer length for envelope computation
%   gainBufLen - buffer length for gain smoothing
%   cSlowInit - initial value for slow averager, 0..1, [] for auto; default: 1
%   cFastInit - initial value for fast averager, 0..1, [] for auto; default: 1
%   envCoefs - data window for envelope computation
%   controlMode - how to use control signal, if provided on port #2? [string]; 
%                   'naida'  - actual control signal is 0.75*max(abs(control, audio))
%                   'direct' - control signal is used verbatim without further processing
%                 default: 'naida'
%
% Input Ports:
%   #1  - input audio signal, 1 x nSamp
%  [#2] - input "control" signal from which gain is derived and applied to
%         the audio signal on port #1; if empty, control signal = audio signal
%
% Output Ports:
%   #1  - audio signal with AGC gain applied, 1 x nSamp
%   #2  - 1 x nSamp linear gain vector 
%
% See also: dualLoopTdAgcFunc, ProcUnit

% Change log:
% 27/10/2012, P. Hehrmann - created
% 03/05/2013, PH - added second input for control signal
% 08/01/2015, PH - use getInput/setOutput instead of getData/setData
% 01/06/2015, PH - adapted to May 2015 framework: removed shared props
% 29/07/2015, PH - added doc
% 28/09/2015, PH - added 'auto' option (cXxxxInit = []) for initial conditions
% 21/Jun/2017, PH - SetObservable properties
% 01/Dec/2017, PH - add "controlMode" property
% 12 Aug 2019, PH - updated documentation
% 15 Aug 2019, PH - swapped dualLoopTdAgcFunc arguments
classdef DualLoopTdAgcUnit < ProcUnit
    properties (SetObservable)
        kneePt = 4.476 ;% compression threshold [log2] [4.476; approx. -53.6 dB FS peak for sine input]
        compRatio = 12; % compression ratio above knee-point (in log-log space) [> 1] [12]
        tauRelFast = -8 / (17400 * log(0.9901)) * 1000; % fast release time const [ms] [46.21]
        tauAttFast = -8 / (17400 * log(0.25)) * 1000;   % fast attack time const  [ms] [0.33]
        tauRelSlow = -8 / (17400 * log(0.9988)) * 1000; % slow release time const [ms] [382.91]
        tauAttSlow = -8 / (17400 * log(0.9967)) * 1000; % slow attack time const  [ms] [139.09]
        maxHold    = 1305;  % max. hold counter value [int >= 0] [1305]
        g0         = 6.908; % gain for levels < kneepoint [log2] [6.908; approx = 41.6dB]
        fastThreshRel = 8; % relative threshold for fast loop [dB] [8]

        cSlowInit = 1; % initial value for slow averager, 0..1, [] for auto; default: 1 
        cFastInit = 1; % initial value for fast averager, 0..1, [] for auto; default: 1 
        controlMode = 'naida'; % how to use control signal, if provided on port #2? ['naida' / 'direct'] ['naida']
        clipMode = 'none'; % output clipping behavio ['none' / 'limit' / 'overflow'] ['none']
    end
    properties (SetAccess = protected)
        decFact    = 8;    % decimation factor (i.e. frame advance)
        envBufLen  = 32;   % buffer (i.e. frame) length for envelope computation
        gainBufLen = 16;   % buffer length for gain smoothing
        envCoefs = [-19,  55,   153,  277,  426,  596,	784,  983,   ...  % tapered envelope data window  
                    1189, 1393, 1587, 1763,	1915, 2035,	2118, 2160,  ...
                    2160, 2118,	2035, 1915, 1763, 1587,	1393, 1189,  ...
                    983,  784,	596,  426,	277,  153,  55,   -19 ] / (2^16);
    end
    
    methods
        function obj = DualLoopTdAgcUnit(parent, ID)
            % obj = DualLoopTdAcUnit(parent, ID)
            % Create new object with speficied parent and ID.
            obj = obj@ProcUnit(parent, ID, 2, 2);
        end
        
        function [x_out, gain] = run(obj)
            x = obj.getInput(1);
            
            if obj.getInputUnit(2).dataIsEmpty() 
                ctrl = [];
            else
                ctrl = obj.getInput(2);
            end
                        
            [x_out, gain] = dualLoopTdAgcFunc(obj, x, ctrl);
            
            obj.setOutput(1, x_out);
            obj.setOutput(2, gain);
        end
    end
end