
clear

%add CTF anonymisation functions to MATLAB path
addpath('/path/to/ctf/functions/')

%define path to directory containing the original (non-anonymised) CTF dataset
orig_path = '/path/to/original/dataset/';

%define path to directory where anonymised CTF dataset will be created
anon_path = '/path/to/anonymised/dataset/';

%create output directory if it doesn't exist
if ~exist(fullfile(anon_path),'dir'), mkdir(fullfile(anon_path)); end

%full file path to original dataset
orig_name = 'NonAnonymisedDataset.ds';
dataset_orig = fullfile(orig_path, orig_name);

%full file path to anonymised dataset
anon_name = 'AnonymisedDataset.ds';
dataset_anon = fullfile(anon_path, anon_name);

%anonymise dataset
info_removed = anonymise_ctf_ds(dataset_orig, dataset_anon);

