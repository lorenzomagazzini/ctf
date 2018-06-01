function [ fid_nii ] = convert_mri2nii_fid( mri_filename, nii_filename, mri_dim, mri_fid)
%[ fid_nii ] = convert_mri2nii_fid( mri_filename, nii_filename, mri_dim, mri_fid)
%   
%   If no CTF .mri file is available, then set mri_filename = [] and 
%   provide two additional input variables:
%       mri_dim (1x3 vector, number of slices in the X,Y,Z dimension)
%       mri_fid (structure, with fields .pos and .label)

% Written by Lorenzo Magazzini (magazzinil@gmail.com)
% Updated in June 2018


%read .mri file and get n slices
nii = ft_read_mri(nii_filename);
nii_xslices = nii.dim(1);
nii_yslices = nii.dim(2);
nii_zslices = nii.dim(3);

%read .nii file and get n slices
if ~isempty(mri_filename)
    mri = ft_read_mri(mri_filename);
    mri_xslices = mri.dim(1);
    mri_yslices = mri.dim(2);
    mri_zslices = mri.dim(3);
else
    mri_xslices = mri_dim(1);
    mri_yslices = mri_dim(2);
    mri_zslices = mri_dim(3);
end

%calculate padding in MRI file
mri_padding = [(mri_xslices-nii_xslices)/2 (mri_yslices-nii_yslices)/2 (mri_zslices-nii_zslices)/2];

%get fiducial voxel coordinates for .mri file
if ~isempty(mri_filename)
    fid_mri = get_mri_fid(mri_filename);
else
    fid_mri = mri_fid;
end

%convert to NIfTI voxel coordinates
fid_nii = struct;
fid_nii.pos(:,1) = (mri_xslices-mri_padding(1)) - fid_mri.pos(:,1) + 1;
fid_nii.pos(:,2) = (mri_yslices-mri_padding(2)) - fid_mri.pos(:,2) + 1;
fid_nii.pos(:,3) = (mri_zslices-mri_padding(3)) - fid_mri.pos(:,3) + 1;
fid_nii.label = fid_mri.label;
