function [grids fileCell]=nk_process(subj,nk_dir,tagNameOrder,badTagNames)
%
% FUNCTION:
%   nk_process.m
% 
% DESCRIPTION:
%   This function automates the re-referencing process and reduces
%   manual creation of various post-processing files.
%
%   This function writes and returns the contents of the
%   electrodes.m file.  It also makes the leads.txt file and the
%   good_leads.txt file.   It also returns the cell array of file
%   handles that are input into reref.m
%
% INPUTS:
%   subj........... 'TJ037'
%   nk_dir.........'/data/eeg/TJ037/raw/2012-01-26'
%   tagNameOrder...{'LAH';'ROF';'RST'; ..etc }
%   badTagNames....{'Penn','EKG'};
%
% OUTPUTS:
%   grids.......contents of electrodes.m
%   fileCell....cell array of file names
%   
%   It also creates the following files (if they don't exist)
%      1. electrodes.m in '/data/eeg/[subj]/docs
%      2. leads.txt in '/data/eeg/[subj]/tal
%      3. good_leads.txt in '/data/eeg/[subj]/tal
%
% NOTES:
%   (1) written by jfburke on 2012-01-17 (john.fred.burke@gmail.com)
%
%

if ~exist('badTagNames','var')||isempty(badTagNames)
  badTagNames ={};
end

d=dir([nk_dir '/*.EEG']);  EEG_file=fullfile(nk_dir,d.name);
assert(length(d)==1,'Expected 1 .EEG file, found %d',length(d));
d=dir([nk_dir '/*.21E']);  ELEC_file=fullfile(nk_dir,d.name);
assert(length(d)==1,'Expected 1 .21E file, found %d',length(d));
fid = fopen(EEG_file);

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% skipping EEG device block
%%%%%%%%%%%%%%%%%%%%%%%%%%%
deviceBlockLen=128;
fseek(fid,deviceBlockLen,'bof');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% reading EEG1 control Block (contains names and addresses for EEG2 blocks)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x=fread(fid,1,'*uint8');  %fprintf('block ID: %d\n',x);
x=fread(fid,16,'*char');  %fprintf('device type: %s\n',x);
x=fread(fid,1,'*uint8');  %fprintf('number of EEG2 control blocks: %d\n',x);
numberOfBlocks=x;
if numberOfBlocks > 1
  % we think we will never have this
  % throw an error for now and re-write code if necessary
  fprintf('ERROR: %d EEG2 control blocks detected (only expecting 1).\n');
  return
end
% if numberOfBlocks is ever > 1, the following should be a for loop
blockAddress=fread(fid,1,'*int32');  %fprintf('address of block %d: %d\n',i,blockAddress);
x=fread(fid,16,'*char');  %fprintf('name of EEG2 block: %s\n',x);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Reading EEG2m control block (contains names and addresses for waveform blocks)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fseek(fid,blockAddress,'bof'); %fprintf('\nin EEG21 block!\n')
x=fread(fid,1,'*uint8');  %fprintf('block ID: %d\n',x);
x=fread(fid,16,'*char');  %fprintf('data format: %s\n',x);
numberOfBlocks=fread(fid,1,'*uint8');  %fprintf('number of waveform blocks: %d\n',numberOfBlocks);
if numberOfBlocks > 1
  % we think we will never have this
  % throw an error for now and re-write code if necessary
  fprintf('ERROR: %d waveform blocks detected (only expecting 1).\n');
  return
end
% if numberOfBlocks is ever > 1, the following should be a for loop
blockAddress=fread(fid,1,'*int32');  %fprintf('address of block %d: %d\n',i,blockAddress);
x=fread(fid,16,'*char');  %fprintf('name of waveform block: %s\n',x);

%%%%%%%%%%%%%%%%%%%%%%%
%Reading waveform block
%%%%%%%%%%%%%%%%%%%%%%%
fseek(fid,blockAddress,'bof'); %fprintf('\nin EEG waveform block!\n')
x=fread(fid,1,'*uint8');  %fprintf('block ID: %d\n',x);
x=fread(fid,16,'*char');  %fprintf('data format: %s\n',x);
x=fread(fid,1,'*uint8');  %fprintf('data type: %d\n',x);
L=fread(fid,1,'*uint8');  %fprintf('byte length of one data: %d\n',L);
M=fread(fid,1,'*uint8');  %fprintf('mark/event flag: %d\n',M);
% get the start time
T_year=bcdConverter(fread(fid,1,'*uint8'));
T_month=bcdConverter(fread(fid,1,'*uint8'));
T_day=bcdConverter(fread(fid,1,'*uint8'));
T_hour=bcdConverter(fread(fid,1,'*uint8'));
T_minute=bcdConverter(fread(fid,1,'*uint8'));
T_second=bcdConverter(fread(fid,1,'*uint8'));
fprintf('Date of session: %d/%d/%d\n',T_month,T_day,T_year)
fprintf('Time at start: %02d:%02d:%02d\n',T_hour,T_minute,T_second)
% get the sampling rate
x=fread(fid,1,'*uint16');  %fprintf('sample rate (coded): %d\n',x);
switch(x)
 case hex2dec('C064'),
  actSamplerate=100;
 case hex2dec('C068'),
  actSamplerate=200;
 case hex2dec('C1F4'),
  actSamplerate=500;
 case hex2dec('C3E8'),
  actSamplerate=1000;
 case hex2dec('C7D0'),
  actSamplerate=2000;
 case hex2dec('D388'),
  actSamplerate=5000;
 case hex2dec('E710'),
  actSamplerate=10000;
 otherwise
  fprintf('UNKNOWN SAMPLING RATE\n');
end
fprintf('Sampling rate: %d Hz\n',actSamplerate);
% get the number of 100 msec block
num100msBlocks=fread(fid,1,'*uint32');  fprintf('Length of Session: %2.2f hours\n',double(num100msBlocks)/10/3600);
numSamples=actSamplerate*num100msBlocks/10; %fprintf('number of samples: %d\n',numSamples);
AD_off=fread(fid,1,'*int16');   %fprintf('AD offset at 0 volt: %d\n',AD_off);
AD_val=fread(fid,1,'*uint16');  %fprintf('AD val for 1 division: %d\n',AD_val);
bitLen=fread(fid,1,'*uint8');   %fprintf('bit length of one sample: %d\n',x);
comFlag=fread(fid,1,'*uint8');  %fprintf('data compression: %d\n',x);
numChannels=fread(fid,1,'*uint8');  %fprintf('number of RAW recordings: %d\n',numChannels);
% set the look-up tables to get the electrode names
[allCodes,allNames]=textread(ELEC_file,'%s%s','delimiter','=');
endRange=find(strcmp(allCodes,'[SD_DEF]'));
allCodes=allCodes(1:endRange-1);
allNames=allNames(1:endRange-1);
goodCodes=[0:36 50 51 74 75 100:253];
badNames={'E'};
actualName_ALL = {};
actualName_ALL_BAD_AND_GOOD = {};
for i=1:numChannels
  x=fread(fid,1,'*int16');  %fprintf(' chan %d ''name'': %d\n',i,x);
  chanCode(i)=x;
  chanCodeString=sprintf('%04d',x);
  matchingRow=find(strcmp(chanCodeString,allCodes));
  actualName=allNames{matchingRow};
  actualName_ALL_BAD_AND_GOOD(end+1)=allNames(matchingRow);
  if ~ismember(chanCode(i),goodCodes)
    %fprintf(' chan %d (%s) is a bad channel code and excluded\n',chanCode(i),actualName);
    goodElec(i)=false;
  elseif any(strcmp(actualName,badNames))
    %fprintf(' chan %d (%s) is a bad address\n',chanCode(i),actualName);
    goodElec(i)=false;
  else
    %fprintf(' chan %d (%s) is good!\n',chanCode(i),actualName);
    goodElec(i)=true;
  end
  
  % save out the names for the jacksheet
  if goodElec(i); actualName_ALL(end+1)=allNames(matchingRow); end
  
  fseek(fid,6,'cof'); %skipping the six most sig. bits of 'name'
  chan_senstivity=fread(fid,1,'*uint8');  %fprintf('         sensitivity: %d\n',x);
  switch fread(fid,1,'*uint8');  %fprintf('         unit: %d\n',chan_unit);
   case 0; CAL=1000;%microvolt
   case 1; CAL=2;%microvolt
   case 2; CAL=5;%microvolt
   case 3; CAL=10;%microvolt
   case 4; CAL=20;%microvolt
   case 5; CAL=50;%microvolt
   case 6; CAL=100;%microvolt
   case 7; CAL=200;%microvolt
   case 8; CAL=500;%microvolt
   case 9; CAL=1000;%microvolt
  end
  GAIN(i)=CAL/double(AD_val);%OK TO ASSUME THIS IS CONSTANT FOR ALL ELECS?
end
fclose(fid);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get rid of non-neural channels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sometimes Dale and TEd will record from channels that have
% nothing plugged into them.  This doesn't affect the clinical
% data at all, because nothing is displayed.  But we will get the
% raw data from these channels.  The names of the channels will
% always be the default names, i.e. AXX, BXX, CXX, and DXX where
% XX=[1...64] and A-D correspond to which amplifer the channels
% came from.
%
% Here I will:
%  (1) find those channels
%  (2) display a warning that I found them
%  (3) set their goodElecs field to 'false'
%
% This will remove them from the data matrix below.
%    jfburke (john.fred.burke@gmail.com) 09-May-2012


% First find the empty amplifier recordings, if they exist
% jfburke (Dec-13-2012)
% this will fail in the rare case in which they call a channel 
% 'A' 'B' 'C' or 'D' and also, simultaneously, leave the amplifier on
% 'A' 'B' 'C' or 'D' open.  It will fail by including the open 
% amplifier into the montage.  This will be a problem if they stop 
% recording form the open amplifier... then the jacksheets won''t match
AMP_NAMES     = {'A','B','C','D'};
%AMP_NAMES     = {'A','B','C'};
AMP_NAMES     = AMP_NAMES(~ismember(AMP_NAMES,tagNameOrder));
emptyAmpNames = {};
for eInd=1:length(actualName_ALL)
  thisELEC     = actualName_ALL{eInd};  
  thisELEC_tag = thisELEC(regexp(thisELEC,'\D'));
  thisELEC_num = thisELEC(regexp(thisELEC,'\d'));
  if ismember(thisELEC_tag,AMP_NAMES);
    emptyAmpNames = cat(1,emptyAmpNames,thisELEC);
  end  
end

% now have to remove the empty amp channels
if ~isempty(emptyAmpNames)
  
  % print a warning
  fprintf('\n\nWARNING!!: Found %d empty amplifier recordings:\n',...
	  length(emptyAmpNames))
  for emptyAmpInd=1:length(emptyAmpNames)
    thisEmptyAmpName = emptyAmpNames{emptyAmpInd};
    fprintf('\t %s\n',thisEmptyAmpName);
  end
  
  % remove them
  fprintf('Removing the empty amplifier recordings...')  

  % remove the empty amplifier channels from actualName_ALL
  actualName_ALL(ismember(actualName_ALL,emptyAmpNames))=[];
  
  % remove the empty amplifier channels from goodElecs
  goodElec(ismember(actualName_ALL_BAD_AND_GOOD,emptyAmpNames))=false;
  
  % pause beause I am slow
  pause(.3);fprintf('done\n')  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% reorder the jacksheet and the electrodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
originalTagNames=regexprep(actualName_ALL','\d','');
originalTagNums=str2double(regexprep(actualName_ALL','[\D]',''));
newElectrodeOrderIdx = [];
newElectrodeNames    = [];
justToCheck = actualName_ALL';
for t=1:length(tagNameOrder)
  thisTagIdx = find(strcmp(originalTagNames,tagNameOrder{t}));
  if isempty(thisTagIdx)
    fprintf('\n\n  ERROR!\n')
    fprintf('  ''tagNameOrder'' ELEMENT ''%s'' NOT FOUND\n',tagNameOrder{t})
    fprintf('\n  No output written. Exiting\n\n')
    return
  end
  
  theseTags  = actualName_ALL(thisTagIdx)';
  theseNums  = originalTagNums(thisTagIdx);
  
  % only permit EKG to not have nuymbers
  if sum(isnan(theseNums))>0; 
    if strcmp('EKG',tagNameOrder{t})||strcmp('GRD',tagNameOrder{t})||strcmp('DCS',tagNameOrder{t})
      newElectrodeNames     = [newElectrodeNames;   theseTags];
      newElectrodeOrderIdx  = [newElectrodeOrderIdx; thisTagIdx];
      keyboard;
      justToCheck(thisTagIdx) = {'THIS_WAS_USED'};
      continue
    else
      error('A TAGNAME OTHER THAN ''EKG'' OR ''GRD'' WAS NOT FOLLOWED BY A NUMBER'); 
    end
  end
  
  % order them in case they are out of order
  [theseNums_sorted sortIdx] = sort(theseNums);
  newElectrodeNames     = [newElectrodeNames;    theseTags(sortIdx)];
  newElectrodeOrderIdx  = [newElectrodeOrderIdx; thisTagIdx(sortIdx)];
  
  justToCheck(thisTagIdx(sortIdx)) = {'THIS_WAS_USED'};
end

unusedNameIdx = find(~strcmp(justToCheck,'THIS_WAS_USED'));


% NOTES ABOUT THE CODE BELOW:
% For TJ038_1 there was an empty imput value.  SKIP ALL EMPTY INPUTS
%
% For TJ061 there were also 4 empty channels.  For TJ061, channels
% 61, 62, 63, and 64 on Box A were left open (originally, Penn1,2
% and EKG1,2 were plugged into them, but those channels did not
% work, so Dale moved Penn1,2 and EKG into 61,62 63, and 64 on Box
% B, leaving the last four channels on A open).  Thus, when a
% channel is recorded, but unnamed, it appears that this means that
% the chanenl is left completely open.  Therefore, it should be
% documented and skipped, which is accomplished int he code below.
%
% NOTE: you dont really have to do anything different if you find
% an empty channel, because the empty channels were not in
% tagName_order_Script.m, they will not be included in
% 'newElectrodeOrderIdx' or 'newElectrodeNames', so they will not
% be written in eeg.noreref or included int he jacksheet.  However,
% I think it is useful to know that they are there, which is why I
% included the code below (burke: 04-2013).
if ~isempty(unusedNameIdx)
  fprintf('\n\n  WARNING!\n')
  fprintf('FOUND CHANNELS THAT WERE NOT ACCOUNTED FOR IN TAG_NAME_ORDER.\n')
  fprintf('THESE COULD BE ''EMPTY'' OR MISSING TAG NAMES.\n')
  fprintf('CHECKING THAT NOW....\n'); pause(.2)
  
  % Right now, it could be that the strings for these channels were
  % (1) empty or (2) occupied by an unrecognized string.  The code
  % below tells the difference between these possibilities.
  missingNamesInds = false(1,length(unusedNameIdx));  
  for k=1:length(unusedNameIdx)
    thisUnusedStr = justToCheck{unusedNameIdx(k)};
    if isempty(thisUnusedStr)
      missingNamesInds(k)=true;
    end
  end
  
  % if you found empty names
  if sum(missingNamesInds)>0
    fprintf('\n\n  WARNING!\n')
    fprintf('  I FOUND AN EMPTY NAME.\n')
    fprintf('  THE FOLLOWING CHANNELS ARE EMPTY:\n')
    emptyCHANNELS_FOO = unusedNameIdx(missingNamesInds);
    for foofoo = 1:length(emptyCHANNELS_FOO)
      fprintf('\t%d\n',emptyCHANNELS_FOO(foofoo))
    end
    fprintf('  DOES TAHT AMKE SENSE?.\n')
    fprintf('  KEYBOARDING SO YOU CAN MAKE SURE YOU KNOW WHAT IS UP (OR GET HELP).\n')
    fprintf('  PRESS ''DBCONT'' TO CONTINUE.\n')
    keyboard
    %if unusedNameIdx~=length(justToCheck)
    %  fprintf('  I DON''T THINK THIS IS A GOOD IDEA.\n')
    %  fprintf('\n  No output written. Exiting\n\n')
    %  return      
    %end
    unusedNameIdx(missingNamesInds)=[];
  end
end

% now check again
if ~isempty(unusedNameIdx)
  fprintf('\n\n  ERROR!\n')
  fprintf('  THE FOLLOWING CHANNELS MUST BE INCLUDED IN ''tagNameOrder'' INPUT\n')
  for k=1:length(unusedNameIdx)
    fprintf('    %s\n',justToCheck{unusedNameIdx(k)})
  end
  fprintf('\n  No output written. Exiting\n\n')
  return
end

%%%%%%%%%%%%%%%%%%%%%
% get the file name
%%%%%%%%%%%%%%%%%%%%%
[x mm]=month2(sprintf('%02d',T_month),'mm');
sessName=sprintf('%s_%02d%s%02d_%02d%02d',subj,T_day,mm,T_year,T_hour,T_minute);
fileCell = {fullfile('/Users/brad/ExperimentData/subjFiles',subj,'eeg.noreref',sessName)};
fprintf('\n')
fprintf('File Stem: %s\n',fileCell{1});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make the electrodes.m file if it doesn't exist
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
docsDir=fullfile('/Users/brad/ExperimentData/subjFiles',subj,'docs');
if ~exist(docsDir,'dir');
  fprintf('\n\n\tMake the %s dir',docsDir);
  fprintf('...I don''t want to do it for you\n\n')
  return
end
elecsFile=fullfile(docsDir,'electrodes.m');
badTagNames_FINAL = {'PENN','REF','EKG','DXL','DRXL','GND','GRD','DC'};
badTagNames_FINAL = cat(2,badTagNames_FINAL,badTagNames);
if ~exist(elecsFile,'file')
  fprintf('Making new electrodes.m file\n');
  elecTagNames=regexprep(newElectrodeNames,'\d','');  
  fout4=fopen(elecsFile,'w','l');
  fprintf(fout4,'\n');
  fprintf(fout4,'r = [\n');
  for t=1:length(tagNameOrder)
    if sum(ismember(upper(badTagNames_FINAL),upper(tagNameOrder{t})))>0
      fprintf(' \n  %.10s: **NOT** Including in reference',tagNameOrder{t})
      continue
    else
      fprintf(' \n  %.10s: Including in reference',tagNameOrder{t})
    end
    elecindices=find(strcmp(elecTagNames,tagNameOrder{t}));
    minElec=min(elecindices);
    maxElec=max(elecindices);
    fprintf(fout4,'%3.0d,%3.0d;  %%%s\n',minElec,maxElec,tagNameOrder{t});
  end
  fprintf(fout4,'];\n');
  fclose(fout4);
  fprintf('\n');
else
  fprintf('Using previously made electrodes.m file\n');
end
run(elecsFile)
grids = r;

%%%%%%%%%%%%%%%%%%%%%%%%%
% make the good_leads.txt file
%%%%%%%%%%%%%%%%%%%%%%%%%
talDir=fullfile('/Users/brad/ExperimentData/subjFiles',subj,'tal');
if ~exist(talDir,'dir');
  fprintf('\n\n\tMake the %s dir',talDir);
  fprintf('...I don''t want to do it for you\n\n')
  return
end
goodleadsDotTxtFile=fullfile(talDir,'good_leads.txt');
if ~exist(goodleadsDotTxtFile,'file')
  fprintf('Making new good_leads.txt file...');
  fout5=fopen(goodleadsDotTxtFile,'w','l');
  for stripInd=1:size(grids,1)
    thisStripElecs = grids(stripInd,1):grids(stripInd,2);
    for foo=1:length(thisStripElecs)
      fprintf(fout5,'%d\n',thisStripElecs(foo));
    end
  end
  fclose(fout5);
  fprintf('done\n');
else
  fprintf('good_leads.txt exists\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make the leads.txt file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd(fullfile(talDir));
LeadsDotTxtFile=fullfile(talDir,'leads.txt');
jackFile=fullfile('/Users/brad/ExperimentData/subjFiles',subj,'docs','jacksheet.txt');
if ~exist(LeadsDotTxtFile,'file')
  fprintf('Making new leads.txt file ');
  copyfile(jackFile,LeadsDotTxtFile)
  
  %gets rid of electrode names
  fid = fopen('leads.txt','r');
  C = textscan(fid, '%d %*s');
  C = C{1};
  fid = fopen('leads.txt','w');
  formatSpec = '%d\n';
  [nrows, ncols] = size(C);
  for row = 1:nrows
      fprintf(fid, formatSpec,C(row,:));
  end
  
  
  
  fprintf('done\n');
else
  fprintf('leads.txt exists\n');
end

function out=bcdConverter(bits_in)
  x = dec2bin(bits_in,8);
  out = 10*bin2dec(x(1:4)) + bin2dec(x(5:8));