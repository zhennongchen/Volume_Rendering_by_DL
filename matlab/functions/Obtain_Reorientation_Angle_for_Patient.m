function [rot_angle] = Obtain_Reorientation_Angle_for_Patient(patient_id,image_path,seg_path)

addpath(genpath(['/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions']));
addpath(genpath(['/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load']));

% load image data and seg data
image_data = load_nii([image_path,'0.nii.gz']);
image = Transform_nii_to_dcm_coordinate(double(image_data.img),0);

seg_data = load_nii([seg_path,'0.nii.gz']);
seg = zeros(size(seg_data.img));
seg(seg_data.img == 1) = 1;
seg = Transform_nii_to_dcm_coordinate(seg,0);

% rotate the image
[~,~,rot_angle] = Rotate_LV_Correct_Orientation(image,seg,0,0);



