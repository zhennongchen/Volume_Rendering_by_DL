%% 
% this script can check the rotation (angles determined by clicking points) via 
% making the segmentation volshow in each angle
%% Preparation: Data Organization
clear all; close all; clc;
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/';
addpath(genpath(code_path));
main_path = '/Volumes/Seagate MacOS';
%% Define patient
patient_class = 'Normal';
patient_id = 'CVC1908301550';
%% 
save_file = [main_path,'/SQUEEZ_results/',patient_class,'/',patient_id,'/rot_angle_2mm.mat'];

% image:
image_path = [main_path,'/downsample-nii-images-2mm/',patient_class,'/',patient_id,'/img-nii-2/0.nii.gz'];
if isfile(image_path) == 0
    error('no image, end the process');
end
image_data = load_nii(image_path);
image = Transform_nii_to_dcm_coordinate(double(image_data.img),0);
    
% seg:
seg_path = [main_path,'/predicted_seg/',patient_class,'/',patient_id,'/seg-pred-0.625-4classes-connected-retouch-downsample/pred_s_0.nii.gz'];
if isfile(seg_path) == 0
    error('no seg, end the process');
end
seg_data = load_nii(seg_path);
seg = Transform_nii_to_dcm_coordinate(double(seg_data.img),0);
    
%
[rot,Irot,segrot] = Obtain_Rotation_Angle_By_Clicking_Anatomical_Landmarks(image,seg);
%

% get volshow
seg_rot = Rotate_Volume_by_Rotation_Angles(seg,rot,0,3);
angle_list = [0:60:300];
load([code_path,'configuration_list/config_default.mat']);
position = config_default.CameraPosition';
   
for i = 1:size(angle_list,2)
    [rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,angle_list(i),1);
     new_position = rot_in_xy * position;
     config_default.CameraPosition = new_position';
     h = figure('pos',[10 10 500 500]);
     volshow(seg_rot > 0,config_default,'ScaleFactor',[2,2,2]); 
       
end
%% Save
[save_folder,~,~] = fileparts(save_file);
mkdir(save_folder)
save(save_file,'rot')