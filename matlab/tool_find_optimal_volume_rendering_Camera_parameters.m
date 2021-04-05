% this script is used when data rotation by clicking points doesn't work
% well and manual refinement in the view orientation is needed.
%% Preparation: Data Organization
clear all; close all; clc;
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/';
addpath(genpath(code_path));
%% Define patient list
patient_list = Find_all_folders('/Volumes/Seagate MacOS/Patient_list/Retouched_Seg_Done/Normal/');
class_list = []; id_list = [];
for i = 1:size(patient_list,1)
    class = split(patient_list(i).folder,'/');
    class = class(end); class = class{1};
    class_list = [class_list;convertCharsToStrings(class)];
    id_list = [id_list;convertCharsToStrings(patient_list(i).name)];
end
patient_list = Find_all_folders('/Volumes/Seagate MacOS/Patient_list/Retouched_Seg_Done/Abnormal/');
for i = 1:size(patient_list,1)
    class = split(patient_list(i).folder,'/');
    class = class(end); class = class{1};
    class_list = [class_list;convertCharsToStrings(class)];
    id_list = [id_list;convertCharsToStrings(patient_list(i).name)];
end
%% Make volume rendering image for each view to check whether manual adjustment is needed
scale = [1.5,1.5,1.5];

num = 159;

clear seg seg_all seg_lv config config_default new_config config_per_angle position new_position

main_path = '/Volumes/Seagate MacOS/';
load([code_path,'configuration_list/config_default.mat']);
patient_class = convertStringsToChars(class_list(num,:));
patient_id = convertStringsToChars(id_list(num));
disp(patient_class)
disp(patient_id)
% load image
seg_path = [main_path,'mat_data/',patient_class,'/',patient_id,'/seg_rotate_box/pred_s_0.mat'];
if isfile(seg_path) == 0
    error('no rotated seg for this case.');
end
load(seg_path,'seg')
seg_all = seg >0;seg_lv = seg == 1;
%% Load in Volume Viewer and save the orientation (LVOT pointing to the left)
% the configuration is saved as variable "config".
%% Modify the camerater position
target_length = Calculate_Length(config_default.CameraPosition,config_default.CameraTarget);
vector_length = Calculate_Length(config.CameraPosition,config.CameraTarget);
config.BackgroundColor = config_default.BackgroundColor;
config.Colormap = config_default.Colormap;
config.Alphamap = config_default.Alphamap;
new_config = config;
new_config.CameraPosition = config.CameraPosition * (target_length/vector_length);
%% Try by volume rendering
angle_list = [0:60:300];
position = new_config.CameraPosition';
 
config_per_angle = new_config;
for i = 1:size(angle_list,2)
    [rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,angle_list(i),1);
    new_position = rot_in_xy * position;
    config_per_angle.CameraPosition = new_position';
    h = figure('pos',[10 10 500 500]);
    volshow(seg_all,config_per_angle,'ScaleFactor',scale); 
    save_folder = [code_path,'configuration_list/case_specific/',patient_id];
    mkdir(save_folder)
    saveas(gcf,[save_folder,'/',patient_id,'_rendered_volume_',num2str(angle_list(i)),'.png']);
    close all
end
%% Save the new parameter
save([code_path,'configuration_list/case_specific/',patient_id,'/',patient_id,'_config.mat'],'new_config')
   