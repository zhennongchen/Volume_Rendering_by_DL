function [output] = Transform_nii_image(nii)

% transform nii image (directly loaded from nii file) to dcm image
% coordinate system

output = permute(nii,[2 1 3]);
output = flip(output,1);
output = flip(output,2);
output = flip(output,3);