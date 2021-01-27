%% Preparation: Data Organization
clear all; close all; clc;
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/';
addpath(genpath(code_path));
%% Find all patients
abnormal_patient_list = Find_all_folders('/Volumes/Seagate MacOS/top_100/Abnormal');
class_list = []; id_list = [];
for i = 1:size(abnormal_patient_list,1)
    class = split(abnormal_patient_list(i).folder,'/');
    class = class(end); class = class{1};
    class_list = [class_list;class];
    id_list = [id_list;convertCharsToStrings(abnormal_patient_list(i).name)];
end
%% Make volume rendering image for each view to check whether manual adjustment is needed
scale = [2 2 2];

num = 3;

clear seg seg_all seg_lv config config1 config_case position new_position
main_path = '/Volumes/Seagate MacOS/';
load([code_path,'configuration_list/config_default.mat']);
patient_class = class_list(num,:);
patient = convertStringsToChars(id_list(num));
disp(patient)
    
% load image
seg_path = [main_path,'mat_data/',patient_class,'/',patient,'/seg_rotate_box/pred_s_0.mat'];
if isfile(seg_path) == 0
    error('no rotated seg for this case.');
end
load(seg_path,'seg')
seg_all = seg >0;seg_lv = seg == 1;
    
angle_list = [0:60:300];
% find camera position for each 
config_case = config;
position = config.CameraPosition';
    
for i = 1:size(angle_list,2)
    [rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,angle_list(i),1);
    new_position = rot_in_xy * position;
    config_case.CameraPosition = new_position';
    h = figure('pos',[10 10 500 500]);
    volshow(seg>0,config_case,'ScaleFactor',scale); 

end
%%    
change = 1;
close all
if change == 1
    config_case.CameraUpVector = config1.CameraUpVector;
    for i = 1:size(angle_list,2)
        [rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,angle_list(i),1);
        new_position = rot_in_xy * position;
        config_case.CameraPosition = new_position';
        h = figure('pos',[10 10 500 500]);
        volshow(seg>0,config_case,'ScaleFactor',scale); 
    end
end
%%
save_path = [main_path,'mat_data/',patient_class,'/',patient,'/config.mat'];
save(save_path,'config_case');

    
   