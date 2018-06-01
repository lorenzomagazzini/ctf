function [ info_removed ] = anonymise_ctf_ds( dataset_orig, dataset_anon, dataset_temp )
%[ info_removed ] = anonymise_ctf_ds( dataset_orig, dataset_anon, dataset_temp )
%   
%   This function takes a CTF .ds dataset as input (dataset_orig) and
%   writes an anonymised .ds dataset (dataset_anon) as output. An
%   intermediate step is to write a temporary .ds dataset (dataset_temp).
%   If dataset_temp is not specified, the .ds name will be created by
%   appending 'AnonymisedTemp' to dataset_anon and writing to the same
%   directory as dataset_anon.
%   These datasets are written using newDs (with options -anon -includeBadChannels -includeBadSegments -includeBad).
%   Additionally, the following is done to increase anonymisation 
%   (for both .ds and /hz.ds datasets):
%   - replace values in 'run_date' and 'run_time' of .acq file 
%   - replace values in 'DATASET_COLLECTIONDATETIME' of .infods file
%   - replace values in 'data_time' 'data_date' of .res4 file (note that,
%       in doing so, the value of MAX_COILS is hard-coded to = 8).
%   - remove any .xml and default.de files
%   This is done mostly using CTF functions readCPersist and writeCPersist.
%   
%   The function returns a structure (info_removed) with fields specifying
%   the original date/time values that have been replaced with anonymised ones.

% Written by Lorenzo Magazzini (magazzinil@gmail.com)
% Revised by Lorenzo Magazzini, Feb 2018
% Updated April 2018


%% definitions

%path and name of ORIG dataset.ds
[dataset_origpath, dataset_origname, ds_ext] = fileparts(dataset_orig);

%path and name of ANON dataset.ds
[dataset_anonpath, dataset_anonname] = fileparts(dataset_anon);

%path and name of TEMP dataset.ds
if nargin > 2 && ~isempty(dataset_temp)
    [dataset_temppath, dataset_tempname] = fileparts(dataset_temp);
else
    dataset_temppath = dataset_anonpath; %better than 'dataset_origpath' in case of residual sensitive information in path/name of original dataset..
    dataset_tempname = [dataset_anonname 'AnonymisedTemp'];
    dataset_temp = fullfile(dataset_temppath, [dataset_tempname ds_ext]);
end


%% temp dataset

%create temp dataset.ds
s = unix(['newDs -anon -includeBadChannels -includeBadSegments -includeBad ' dataset_orig ' ' dataset_temp]);
if s~=0, error(['error creating dataset ' dataset_temp]); end

%create temp hz.ds
hz_orig = fullfile(dataset_orig, ['hz' ds_ext]);
if exist(hz_orig, 'dir')
    [hz_origpath, hz_origname] = fileparts(hz_orig);
    hz_temp = fullfile(dataset_temp, [hz_origname ds_ext]);
    s = unix(['newDs -anon -includeBadChannels -includeBadSegments -includeBad ' hz_orig ' ' hz_temp]);
    if s~=0, error(['error creating dataset ' hz_temp]); end
else
    hz_temp = ''; %see below ... "if ~isempty(hz_temp)"
end


%% store sensitive info in info_removed

info_removed = struct;


%% .acq

%read the .acq file using readCPersist (CTF function)
acq_ext = '.acq';
acq_file = fullfile(dataset_temp, [dataset_tempname acq_ext]);
acq = readCPersist(acq_file);

%find '_genRes' field and replace data with zeros
acq_genres_idx = find(ismember({acq(:).name},'_genRes'));
acq(acq_genres_idx).data = int16(zeros(size(acq(acq_genres_idx).data)));

%find, store and replace date
acq_rundate_idx = find(ismember({acq(:).name},'_run_date'));
acq_rundate = acq(acq_rundate_idx).data; %sensitive
acq(acq_rundate_idx).data = '11/11/1911';

%find, store and replace time
acq_runtime_idx = find(ismember({acq(:).name},'_run_time'));
acq_runtime = acq(acq_runtime_idx).data; %sensitive
acq(acq_runtime_idx).data = '11:11';

%delete existing .acq file
s = unix(['rm -v ' acq_file]);
if s~=0, error(['error deleting file ' acq_file]); end

%write new .acq file with anonymised date/time
writeCPersist(acq_file, acq);

%store sensitive info in info_removed
info_removed.acq_rundate = acq_rundate;
info_removed.acq_runtime = acq_runtime;

clear acq
clear acq_file
clear acq_rundate_idx
clear acq_runtime_idx


%same but for hz.ds
if ~isempty(hz_temp) && exist(hz_temp, 'dir')
    
    %read the .acq file using readCPersist (CTF function)
    acq_ext = '.acq';
    acq_file = fullfile(hz_temp, [hz_origname acq_ext]);
    acq = readCPersist(acq_file);
    
    %find '_genRes' field and replace data with zeros
    acq_genres_idx = find(ismember({acq(:).name},'_genRes'));
    acq(acq_genres_idx).data = int16(zeros(size(acq(acq_genres_idx).data)));
    
    %find and replace date
    acq_rundate_idx = find(ismember({acq(:).name},'_run_date'));
    acq(acq_rundate_idx).data = '11/11/1911';
    
    %find and replace time
    acq_runtime_idx = find(ismember({acq(:).name},'_run_time'));
    acq(acq_runtime_idx).data = '11:11';
    
    %delete existing .acq file
    s = unix(['rm -v ' acq_file]);
    if s~=0, error(['error deleting file ' acq_file]); end
    
    %write new .acq file with anonymised date/time
    writeCPersist(acq_file, acq);
    
    clear acq
    clear acq_file
    clear acq_rundate_idx
    clear acq_runtime_idx
    
end


%% .infods

%read the .infods file using readCPersist (CTF function)
infods_ext = '.infods';
infods_file = fullfile(dataset_temp, [dataset_tempname infods_ext]);
infods = readCPersist(infods_file);

%find, store and replace date/time
infods_datetime_idx = find(ismember({infods(:).name},'_DATASET_COLLECTIONDATETIME'));
infods_datetime = infods(infods_datetime_idx).data; %sensitive
infods(infods_datetime_idx).data = '19111111111111';

%delete the existing .infods file
s = unix(['rm -v ' infods_file]);
if s~=0, error(['error deleting file ' infods_file]); end

%write new .infods file with anonymised date/time
writeCPersist(infods_file, infods);

%delete OTHER *** .infods *** files (e.g., ".infods~")
tmp = dir(fullfile(dataset_temp, '*infods*'));
for tmp_idx = 1:length(tmp)
    if ~strcmp(fullfile(dataset_temp, tmp(tmp_idx).name), infods_file)
        s = unix(['rm -v ' fullfile(dataset_temp, tmp(tmp_idx).name)]);
        if s~=0, error(['error deleting file ' tmp(tmp_idx).name]); end
    end
end
clear tmp*

%store sensitive info in info_removed
info_removed.infods_datetime = infods_datetime;

clear infods
clear infods_file
clear infods_datetime_idx


%same but for hz.ds
if ~isempty(hz_temp) && exist(hz_temp, 'dir')
    
    %read the .acq file using readCPersist (CTF function)
    infods_ext = '.infods';
    infods_file = fullfile(hz_temp, [hz_origname infods_ext]);
    infods = readCPersist(infods_file);
    
    %find and replace date/time
    infods_datetime_idx = find(ismember({infods(:).name},'_DATASET_COLLECTIONDATETIME'));
    infods(infods_datetime_idx).data = '19111111111111';
    
    %delete existing .acq file
    s = unix(['rm -v ' infods_file]);
    if s~=0, error(['error deleting file ' infods_file]); end
    
    %write new .acq file with anonymised date/time
    writeCPersist(infods_file, infods);
    
    %delete OTHER *** .infods *** files (e.g., ".infods~")
    tmp = dir(fullfile(hz_temp, '*infods*'));
    for tmp_idx = 1:length(tmp)
        if ~strcmp(fullfile(hz_temp, tmp(tmp_idx).name), infods_file)
            s = unix(['rm -v ' fullfile(hz_temp, tmp(tmp_idx).name)]);
            if s~=0, error(['error deleting file ' tmp(tmp_idx).name]); end
        end
    end
    clear tmp*
    
    clear infods
    clear infods_file
    clear infods_datetime_idx
    
end


%% .res4

%read .ds dataset using readCTFds (CTF function)
ctfds = readCTFds(dataset_temp);

%get .res4, store date/time fields and edit them
res4 = ctfds.res4;
res4_time = res4.data_time;
res4.data_time = '11:11 ';
res4_date = res4.data_date;
res4.data_date = '11-Nov-1911 ';

%delete the existing .res4 file
res4_ext = '.res4';
res4_file = fullfile(dataset_temp, [dataset_tempname res4_ext]);
s = unix(['rm -v ' res4_file]);
if s~=0, error(['error deleting file ' res4_file]); end

%write new .res4 file
MAX_COILS = 8; %WARNING: hard-coded value...
writeRes4(res4_file, res4, MAX_COILS);

%store sensitive info in info_removed
info_removed.res4_date = res4_date;
info_removed.res4_time = res4_time;

clear ctfds
clear res4
clear res4_file
clear res4_time
clear res4_date


%same but for hz.ds
if ~isempty(hz_temp) && exist(hz_temp, 'dir')
    
    %read .ds dataset using readCTFds (CTF function)
    ctfds = readCTFds(hz_temp);
    
    %get .res4 and edit date/time fields
    res4 = ctfds.res4;
    res4.data_time = '11:11 ';
    res4.data_date = '11-Nov-1911 ';
    
    %delete the existing .res4 file
    res4_ext = '.res4';
    res4_file = fullfile(hz_temp, [hz_origname res4_ext]);
    s = unix(['rm -v ' res4_file]);
    if s~=0, error(['error deleting file ' res4_file]); end
    
    %write new .res4 file
    MAX_COILS = 8; %WARNING: hard-coded value...
    writeRes4(res4_file, res4, MAX_COILS);
    
    clear ctfds
    clear res4
    clear res4_file
    clear res4_time
    clear res4_date
    
end


%% .xml

%delete ANY *** .xml *** files in temp dataset.ds (e.g., ".bak")
tmp = dir(fullfile(dataset_temp, '*.xml*'));
for tmp_idx = 1:length(tmp)
    s = unix(['rm -v ' fullfile(dataset_temp, tmp(tmp_idx).name)]);
    if s~=0, error(['error deleting file ' fullfile(dataset_temp, tmp(tmp_idx).name)]); end
end
clear tmp*


%same but for hz.ds
if ~isempty(hz_temp) && exist(hz_temp, 'dir')
    
    %delete ANY *** .xml *** files in temp hz.ds (e.g., ".bak")
    tmp = dir(fullfile(hz_temp, '*.xml*'));
    for tmp_idx = 1:length(tmp)
        s = unix(['rm -v ' fullfile(hz_temp, tmp(tmp_idx).name)]);
        if s~=0, error(['error deleting file ' fullfile(hz_temp, tmp(tmp_idx).name)]); end
    end
    clear tmp*
    
end


%% default.de

%delete ANY *** default.de *** files in temp dataset.ds (e.g., ".bak")
tmp = dir(fullfile(dataset_temp, '*default.de*'));
for tmp_idx = 1:length(tmp)
    s = unix(['rm -v ' fullfile(dataset_temp, tmp(tmp_idx).name)]);
    if s~=0, error(['error deleting file ' fullfile(dataset_temp, tmp(tmp_idx).name)]); end
end
clear tmp*


%% creare anon dataset

% %finally, rename dataset by copying it (with copyDs) as requested
% s = unix(['copyDs ' dataset_temp ' ' dataset_anon]);
% if s~=0, error(['error creating dataset ' dataset_anon]); end

%instead of copying, call the -anon option again, just to be on the safe side
%create anon dataset.ds
s = unix(['newDs -anon -includeBadChannels -includeBadSegments -includeBad ' dataset_temp ' ' dataset_anon]);
if s~=0, error(['error creating dataset ' dataset_anon]); end

%create anon hz.ds
% hz_temp = fullfile(dataset_temp, ['hz' ds_ext]);
if ~isempty(hz_temp) && exist(hz_temp, 'dir')
    [hz_temppath, hz_tempname] = fileparts(hz_temp);
    hz_anon = fullfile(dataset_anon, [hz_tempname ds_ext]);
    s = unix(['newDs -anon -includeBadChannels -includeBadSegments -includeBad ' hz_temp ' ' hz_anon]);
    if s~=0, error(['error creating dataset ' hz_anon]); end
end


%delete ANY *** default.de *** files in anon dataset.ds
tmp = dir(fullfile(dataset_anon, '*default.de*'));
for tmp_idx = 1:length(tmp)
    s = unix(['rm -v ' fullfile(dataset_anon, tmp(tmp_idx).name)]);
    if s~=0, error(['error deleting file ' fullfile(dataset_anon, tmp(tmp_idx).name)]); end
end
clear tmp*


%% remove temp dataset

s = unix(['rm -Rv ' dataset_temp]);
if s~=0, error(['error removing dataset ' dataset_temp]); end


end
