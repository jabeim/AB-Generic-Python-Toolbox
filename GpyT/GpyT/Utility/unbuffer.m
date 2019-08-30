% Overlap-add synthesis of buffered data 'buff_in' with hop size 'hop'
function out = unbuffer(buff_in, hop)

lenBuff = size(buff_in, 1);
nFrames = size(buff_in, 2);

out = zeros(hop * (nFrames-1) + lenBuff,1);
for iFrame = 0:nFrames-1
    idxWav = iFrame*hop+1:iFrame*hop+lenBuff;
    out(idxWav) = out(idxWav) + buff_in(:,iFrame+1);
end

end
