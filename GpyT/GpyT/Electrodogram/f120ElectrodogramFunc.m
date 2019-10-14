% elGram = f120ElectrodogramFunc(par, ampIn)
% Generate scope-like electrodogram from matrix of F120 amplitude frame. 
% Amplitude frames are expected to represent the amplitude( pair)s for each
% channel by a pair of consecutive rows each (as provided e.g. by 
% F120MappingUnit)
%
% Input:
%   par - parameter object/struct
%   ampIn - 2*nChan x nFtFrames matrix of stimulation amplitudes [uA]
%
% Fields of par:
%   channelOrder - 1 x nChan vector defining the firing order among channels  
%                  [1..nChan, unique] [[1 5 9 13 2 6 10 14 3 7 11 15 4 8 12]]
%   outputFs - output sampling frequency; [] for native FT rate  [Hz] [[]]
%              (resampling is done using zero-order hold method)
%   cathodicFirst - start biphasic pulse with cathodic phase [bool] [true]
%   resistance - load-board resistance; [] (or 1) to return values in uA  [Ohm] [[]]
%   enablePlot - generate electrodogram plot? [bool] 
%   colorScheme - color scheme for plot; [1..4] 1/2 more subdued, 3/4 more strident colors; odd/even affects color order
%
% Output: 
%   elGram - 16 x nSamp matrix of electrode current flow; [uA]/[V] depending on resistance 

% Change log:
% 16 Aug 2019, PH - created
% 08 Oct 2019, PH - added color scheme option 
%                 - improved plotting performance
function elGram = f120ElectrodogramFunc(par, ampIn)
    strat = par.parent;
    
    fsOut = par.outputFs;
    rOut = par.resistance;
    nFrameFt = size(ampIn,2);
    nChan = strat.nChan;
    pulseWidth = strat.pulseWidth;  % us
    phasesPerCyc = 2 * nChan;
    dtIn = (phasesPerCyc * pulseWidth * 1e-6); % s  
    durIn = nFrameFt * dtIn;
    chanOrder = par.channelOrder;
    
    
    % restriction: only 15 channels strategy supported
    assert(nChan == 15, 'Only strategies 15 channels are supported.');
    % check consistency
    assert(length(chanOrder) == nChan, 'length(channelOrder) (%g) must match nChan (%g)', ...
                                        length(chanOrder), nChan);

    nFrameOut = nFrameFt * phasesPerCyc;
    idxLowEl   = 1 : 15;   % index of low (apical) electrode per channel
    idxHighEl  = 2 : 16;   % index of low (apical) electrode per channel
    nEl = 16;
    
    % assemble matrix of "Dirac impulses" 
    elGram = zeros(nFrameOut, nEl);
    for iCh = 1:nChan
        phaseOffset = 2*(chanOrder(iCh)-1) + 1;
        elGram(phaseOffset:phasesPerCyc:end, idxLowEl(iCh))  = ampIn(2*iCh-1, :)';
        elGram(phaseOffset:phasesPerCyc:end, idxHighEl(iCh)) = ampIn(2*iCh, :)';       
    end
    
    % convolve with biphasic pulse template
    if par.cathodicFirst
        kernel = [-1 1];
    else
        kernel = [1 -1];        
    end
    elGram = filter(kernel, 1, elGram);  % elGram has size nSamp x 16 
    
    % resample (zero-order hold)
    if ~isempty(fsOut)
        dtOut = 1/fsOut;
        tPhase = (0:nFrameOut-1) * pulseWidth*1e-6; %  (pulse width in us)
        tOut = (0 : floor(durIn/dtOut)-1) * dtOut;       
        elGram = interp1(tPhase, elGram, tOut, 'previous', 'extrap');
    else
        tOut = (0:nFrameOut-1) * pulseWidth*1e-6;
    end
    
    % apply load-board resistance 
    if ~isempty(rOut)
        elGram = elGram*1e-6 * rOut;  %  [A * Ohm]
    end
    
    elGram = sparse(elGram); % make sparse and 'horizontal'
    
    if par.enablePlot 
        figure;
        cols = myColorMap(par.colorScheme); % apply magical 16-element color map (see below)
        
        hSub1 = subplot(5, 1, 1:4); hold on;
        hSub2 = subplot(5, 1, 5); hold on;
        set(hSub1, 'ColorOrder', cols);
        set(hSub2, 'ColorOrder', cols);          
        normalizer = 2 * max(abs(elGram(:))) * 1.01;
        
        % naively:
        % stairs(hSub1, tOut, bsxfun(@plus, elGram / normalizer, (1 : 16)));   % nomalize and offset channels
        % stairs(hSub2, tOut, elGram);            
        
        % more efficient (fewer line segments, faster drawing)
        for iEl = 1:16
                idxChange = find(diff(elGram(:,iEl)));
                % create line segments only where change occurs
                idxPlotX = [1, reshape(idxChange' + [1; 1], 1, 2*length(idxChange)), length(tOut)];
                idxPlotY = [1, reshape(idxChange' + [0; 1], 1, 2*length(idxChange)), length(tOut)];
                
                xx = tOut(idxPlotX);
                yy = elGram(idxPlotY, iEl);
                plot(hSub1, xx, yy  / normalizer + iEl);
                plot(hSub2, xx, yy);
        end

        ylim(hSub1, [0.5 16.5]);
        set(hSub1, 'YTick', 1:16);
        set(hSub1, 'XLimMode', 'auto');
        ylabel(hSub1, 'Normalized output');
        if isempty(rOut)
            ylabel('Current [{\mu}A]');
        else
            ylabel('Voltage [V]');
        end
        xlabel(hSub2, 'Time [s]');
        set(hSub2, 'XLimMode', 'auto');
        linkaxes([hSub1, hSub2], 'x');
    end
    
    elGram = elGram.';
end


function C = myColorMap(scheme)
if (scheme <= 2) % subdued tones
    C = [
        0.1216      0.4706      0.8059  ;
        0.6510      0.8078      0.8902  ;
        0.4118      0.6745      0.6314  ;
        0.2000      0.7275      0.1725  ;
        0.6980      0.8745      0.5412  ;
        0.5922      0.6157      0.3882  ;
        0.9702      0.2020      0.1798  ;
        0.9843      0.6039      0.6000  ;
        0.9373      0.4275      0.2745  ;
        1.0000      0.5980      0       ;
        0.9922      0.7490      0.4353  ;
        0.9412      0.6000      0.4196  ;
        0.5657      0.2392      0.7039  ;
        0.7422      0.5480      0.7892  ;
        0.7098      0.6196      0.6039  ;
        0.7441      0.3990      0.2069  ;
        ];
    if (scheme == 2)
        C = C([1,4,7,10,13,16,3,6,9,12,14,15,2,5,8,11],:);
    end
else % strident tones
    C = [
        0.1216      0.4706      0.8059  ;
        0.0         0.82        0.78    ;
        0.2000      0.7275      0.1725  ;
        1.0000      0.6480      0       ;
        0.7441      0.3990      0.2069  ;
        0.9702      0.2520      0.1798  ;
        0.9800      0.07        0.75	;
        0.4557      0.2392      0.8539	;
        0.4510      0.8078      0.9902  ;
        0.6         0.92        0.87    ;
        0.6980      0.8745      0.5412  ;
        0.9922      0.7490      0.4353  ;
        0.7373      0.5775      0.3745  ;
        1.0000      0.6039      0.5000  ;
        1.0000      0.52        0.85    ;
        0.7422      0.5480      0.7892  ;
        ];
    if (scheme == 3)
        C = C([1 9 2 10 3 11 4 12 5 13 6 14 7 15 8 16],:);
    end
    
end
end
