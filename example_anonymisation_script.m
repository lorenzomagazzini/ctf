
clear

rawdata_path = '/cubric/collab/meg-partnership/Data';
orig_path = rawdata_path
anon_path = '/cubric/collab/meg-partnership/cardiff/exampledata/raw';
cd(orig_path)

dir_struct = dir('*7*');
partnership_id_list = {dir_struct(:).name}';
nsubj = length(partnership_id_list);
clear dir_struct

partnership_id = '7070';
meguk_id = 'example001';

if ~exist(fullfile(anon_path, meguk_id),'dir'), mkdir(fullfile(anon_path, meguk_id)); end

orig_name = '7070_NBack.ds';
dataset_orig = fullfile(orig_path, partnership_id, orig_name);

anon_name = strrep(orig_name, partnership_id, meguk_id);
dataset_anon = fullfile(anon_path, meguk_id, anon_name);
dataset_anon = strrep(dataset_anon,'NBack','nback');

info_removed = anonymise_ctf_ds(dataset_orig, dataset_anon);



meguk_nifti = '/cubric/collab/meg-partnership/cardiff/bids/sub-cdf019/anat/sub-cdf019_T1w.nii.gz';
example_nifti = '/cubric/collab/meg-partnership/cardiff/exampledata/raw/example001/example001.nii';

nifti = ft_read_mri(meguk_nifti);
nifti.hdr.fspec = '';
nifti.hdr.pwd = '';

V = ft_write_mri(example_nifti, nifti.anatomy, 'transform',nifti.transform, 'dataformat','nifti')