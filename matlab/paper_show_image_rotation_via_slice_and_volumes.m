% description: this script can generate z-axis slices and binary volume
% rendering of original & rotated image data
%% Preparation: Data Organization
clear all; close all; clc;
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/';
addpath(genpath(code_path));
main_path = '/Volumes/Seagate MacOS';
%% Define patient
patient_class = 'Abnormal';
patient_id = 'CVC1904291452';
%% 
rotate_file = [main_path,'/SQUEEZ_results/',patient_class,'/',patient_id,'/rot_angle_2mm.mat'];
load(rotate_file)

% image_original:
image_path = [main_path,'/upsampled-nii-images/',patient_class,'/',patient_id,'/img-nii-0.625/0.nii.gz'];
if isfile(image_path) == 0
    error('no image, end the process');
end
image_data = load_nii(image_path);
image = Transform_nii_to_dcm_coordinate(double(image_data.img),0);
    
% seg_original:
seg_path = [main_path,'/predicted_seg/',patient_class,'/',patient_id,'/seg-pred-0.625-4classes-connected-retouch/pred_s_0.nii.gz'];
if isfile(seg_path) == 0
    error('no seg, end the process');
end
seg_data = load_nii(seg_path);
seg = Transform_nii_to_dcm_coordinate(double(seg_data.img),0);

if size(image,1) > 500 || size(image,2) > 500
    image = image(100:size(image,1)-100,140:size(image,2)-40,:);
    seg = seg(100:size(seg,1)-100,140:size(seg,2)-40,:);    
        
elseif (size(image,1) >= 450 && size(image,1) <= 500) || (size(image,2) >= 450 && size(image,2) <= 500)
    image = image(80:size(image,1)-50,100:size(image,2)-40,:);
    seg = seg(80:size(seg,1)-50,100:size(seg,2)-40,:);
end
        
if size(image,3)>300
    image = image(:,:,20:size(image,3)-20);
    seg = seg(:,:,20:size(seg,3)-20);
end

%% rotate
tic
[image_rot] = Rotate_Volume_by_Rotation_Angles(image,rot,1,3);
[seg_rot] = Rotate_Volume_by_Rotation_Angles(seg,rot,0,3);
toc
%% Plot z-axis
h = figure('pos',[10 10 500 500]);
I = Turn_data_into_greyscale(image,500,900);
imshow(I(:,:,size(image,3)/2 ));
saveas(gcf,'/Users/zhennongchen/Documents/Zhennong_VR/Paper/pictures_collections/z_axis_view_original1.png');
close all;
h = figure('pos',[10 10 500 500]);
imshow(I(:,:,size(image,3)/2+ 10));
saveas(gcf,'/Users/zhennongchen/Documents/Zhennong_VR/Paper/pictures_collections/z_axis_view_original2.png');
close all;
h = figure('pos',[10 10 500 500]);
imshow(I(:,:,size(image,3)/2 + 20));
saveas(gcf,'/Users/zhennongchen/Documents/Zhennong_VR/Paper/pictures_collections/z_axis_view_original3.png');
close all;

I_rot = Turn_data_into_greyscale(image_rot,500,900);
h = figure('pos',[10 10 500 500]);
imshow(I_rot(:,:,size(I_rot,3)/2  ));
saveas(gcf,'/Users/zhennongchen/Documents/Zhennong_VR/Paper/pictures_collections/z_axis_view_rotated1.png');
close all;
h = figure('pos',[10 10 500 500]);
imshow(I_rot(:,:,size(I_rot,3)/2 - 50 ));
saveas(gcf,'/Users/zhennongchen/Documents/Zhennong_VR/Paper/pictures_collections/z_axis_view_rotated2.png');
close all;
h = figure('pos',[10 10 500 500]);
imshow(I_rot(:,:,size(I_rot,3)/2 - 70 ));
saveas(gcf,'/Users/zhennongchen/Documents/Zhennong_VR/Paper/pictures_collections/z_axis_view_rotated3.png');
close all;

%%
load([code_path,'configuration_list/config_default.mat'])
h = figure('pos',[10 10 500 500]);
volshow(seg > 0,config_default,'ScaleFactor',[2,2,2]);
saveas(gcf,'/Users/zhennongchen/Documents/Zhennong_VR/Paper/pictures_collections/volume_rendering_segmentation_original.png');
close all;

h = figure('pos',[10 10 500 500]);
volshow(seg_rot > 0,config_default,'ScaleFactor',[2,2,2]);
saveas(gcf,'/Users/zhennongchen/Documents/Zhennong_VR/Paper/pictures_collections/volume_rendering_segmentation_rotated.png');
close all;

