
function prime_stimulator(stimdata)

% function prime_stimulator(stimdata,pport)
%
% Sends stimulator instructions to TDT using the Parport control circuit
% for the stimulator. It sends 5 instructions as follows,
%
%       0. Reset code = 128;
%       1. Level: bits 0-6, Mode: bit 7 (0-current,1-voltages) (divide code by
%           5 for volt and multiply by 5 for current)
%       2. Duration: bit 0:7 (in sec, divide code by 10)
%       3. Frequency: bit 0:7 5 hz - 648 (in Hz, multiply code by 5) 
%       4,5. positive contacts
%       6,7. negative contact
%       
%   The next event code over 128 is triggers stimulation                                        
%
% stimdata is a structure with fields
%   .level  (stim level in V or uA)
%   .duration (stim duration in s)
%   .frequency (stim frequency in Hz)
%   .channel (1x2 vector with source and ref channel) 
%   .stimmode 'current' or 'voltage'
%
% Note that stimmode MUST match the TDT settings.
%

% ----------- SVN REVISION INFO ------------------
% $URL: https://saccade.neurosurgery.uiowa.edu/svn/KovachToolbox/TDT/@stimulator/prime_stimulator.m $
% $Revision: 85 $
% $Date: 2012-03-03 13:57:49 -0600 (Sat, 03 Mar 2012) $
% $Author: ckovach $
% ------------------------------------------------



reset_code =stimdata.reset_code;
% code_offset = stimdata.codeoffset;

switch stimdata.stim_mode
    case {'current',0}
%         level_sf =1./2.36;
        level_sf = 5;
    case {'voltage',1}
        level_sf =1/5;
end

duration_sf = 1/10;

freq_sf = 5;

wait = .01;
% wait = 1;


if xor(any(stimdata.pos_chan > 16),any( stimdata.neg_chan > 16))
    error(' + and - channels must be in the same bank of 16');
end

poschans=0;
for i = 1:length(stimdata.pos_chan)
 poschans = poschans + floor(2^(stimdata.pos_chan(i)-1));
end

negchans=0;
for i = 1:length(stimdata.neg_chan)
 negchans = negchans + floor(2^(stimdata.neg_chan(i)-1));
end

ilim = @(x) ceil(x.*(x>=0&x<128)./(x>0&x<128));

%%% reset
stimdata.pport.put(0);
pause(wait);
stimdata.pport.put(reset_code);
pause(wait);
stimdata.pport.put(0);
pause(wait);

%%% Level
level = ilim(stimdata.level./level_sf );
if isnan(level)
    error('Level is out of the allowable range for constant %s',stimdata.stim_mode);
end

stimdata.pport.put(level + 128*stimdata.stim_mode_val+1);
pause(wait);
stimdata.pport.put(0);
pause(wait);


%%% Duration
stimdata.pport.put(round(stimdata.duration./duration_sf)+1);
pause(wait);
stimdata.pport.put(0);
pause(wait);

%%% Frequency
stimdata.pport.put(bitand(round(stimdata.frequency./freq_sf)+1,255));
pause(wait);
stimdata.pport.put(0);
pause(wait);


%%% Contacts



%Positive contacts 1
pch=bitand(poschans,255)+1;
% if pch==0, pch=255;end
stimdata.pport.put(pch);
pause(wait);
stimdata.pport.put(0);
pause(wait);

pch=bitand(bitshift(poschans,-8)+1,255);
% if pch==0, pch=255;end
stimdata.pport.put(pch);
pause(wait);
stimdata.pport.put(0);
pause(wait);

%Negative
nch=bitand(negchans,255)+1;
stimdata.pport.put(nch);
pause(wait);
stimdata.pport.put(0);
pause(wait);

nch=bitand(bitshift(negchans,-8)+1,255);
stimdata.pport.put(nch);
pause(wait);
stimdata.pport.put(0);
pause(wait);

stimdata.isprimed = 1;


