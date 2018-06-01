function [ fid ] = get_mri_fid( mri_filename )
%[ fid ] = get_mri_fid( mri_filename )


%get fieldtrip path
[ft_v, ft_path] = ft_version;

%read .mri file using CTF's CPersist reading function
addpath(fullfile(ft_path, 'external', 'ctf'))
mri_struct = readCPersist(mri_filename);
rmpath(fullfile(ft_path, 'external', 'ctf'))

%get nasion
struct_field_name = '_HDM_NASION';
struct_field_indx = find(ismember({mri_struct(:).name}, struct_field_name));
struct_field_data = mri_struct(struct_field_indx).data;
nas_vox_coord = str2num(strrep(struct_field_data, '\', ' '));

%get leftear
struct_field_name = '_HDM_LEFTEAR';
struct_field_indx = find(ismember({mri_struct(:).name}, struct_field_name));
struct_field_data = mri_struct(struct_field_indx).data;
lpa_vox_coord = str2num(strrep(struct_field_data, '\', ' '));

%get leftear
struct_field_name = '_HDM_RIGHTEAR';
struct_field_indx = find(ismember({mri_struct(:).name}, struct_field_name));
struct_field_data = mri_struct(struct_field_indx).data;
rpa_vox_coord = str2num(strrep(struct_field_data, '\', ' '));

%output
fid.pos = [nas_vox_coord; lpa_vox_coord; rpa_vox_coord];
fid.label = {'nas'; 'lpa'; 'rpa'};
