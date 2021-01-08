%% add path
clear all;
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load');
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions');
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/SQUEEZ functions');
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/';
%%
patient_class = '';  
patient_id = 'CVC1809171438';
load([code_path,'SQUEEZ_Temp_Results/',patient_class,patient_id,'/',patient_class,patient_id,'_step4_MeshRotation.mat'])
data_path = '/Users/zhennongchen/Documents/Zhennong_CT_Data/AI_dataset/Rotated_Data/';
load([data_path,patient_class,patient_id,'_rot.mat'],'Data','timeframes')
imageraw = Data(1).image_rot;
%% find low RS pixels
% set a threshold for RSct of 
rs_list = Mesh(timeframes(2)).RSct_vertex';
threshold = max(rs_list) - (max(rs_list) - min(rs_list)) * 0.2

v_list = Mesh(timeframes(1)).vertices;
low_strain_idx = find(rs_list > threshold);
low_strain_p = v_list(low_strain_idx,:,:);
%% assign different class of pixel value to low RS pixel
segraw = double(Data(1).seg_rot == 1);
seg = double(Data(1).seg_rot == 1);

slice = 120;
figure()
imagesc(imageraw(:,:,slice));
figure()
imagesc(seg(:,:,slice));

for i = 1: size(low_strain_p,1)
    p = low_strain_p(i,:);
    seg(p(2),p(1),p(3)) = 9; % background = 0, LV = 1, infarct = 9
end

figure()
imagesc(seg(:,:,slice));

%% Additional: make a segmentation w/ regional strain labeled
segrs = zeros(size(seg));
for i = 1: size(v_list,1)
    p = v_list(i,:);
    segrs(p(2),p(1),p(3)) = rs_list(i,:)+1;
  
end
%% make volume rendering
load([code_path,'/config_default']);
config_label.CameraPosition = config.CameraPosition;
config_label.CameraUpVector = config.CameraUpVector;
config_label.CameraTarget = config.CameraTarget;
config_label.CameraViewAngle = config.CameraViewAngle;
config_label.BackgroundColor = [1 1 1];
config_label.ShowIntensityVolume = 0;
config_label.LabelColor= [0 0 0;1 1 1;1 0 0];
config_label.LabelVisibility = logical([0;1;1]);
config_label.LabelOpacity = [0;1;1];
config_label.VolumeOpacity = 0.5;
config_label.VolumeThreshold = 0.3922;

% rotate
angle = -60;
position = config_label.CameraPosition';
[rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,angle,1);
new_position = rot_in_xy * position;
config_label.CameraPosition = new_position';

%
scale = [3,3,3];
h = figure('pos',[10 10 100 100]);
labelvolshow(seg,config_label,'ScaleFactor',scale);
saveas(gcf,[code_path,info.patient,'_label_VR_MI.png']);
close all

h2 = figure('pos',[10 10 100 100]);
config_label_raw = config_label;
config_label_raw.LabelColor= [0 0 0;0 0 0];
config_label_raw.LabelVisibility = logical([0;1]);
config_label_raw.LabelOpacity = [0;1];
labelvolshow(segraw,config_label_raw,'ScaleFactor',scale);
saveas(gcf,[code_path,info.patient,'_label_VR.png']);
close all

config_label_multi = config_label;
config_label_multi.LabelColor= [0 0 0;0 0 0;1 0 0];
labelvolshow(seg,config_label_multi,'ScaleFactor',scale);

%% count red pixels as MI
Image_MI = imread([info.patient,'_label_VR_MI.png']);
[Image_MI_bw,num_MI] = Count_Non_White_Pixel(Image_MI,1);
Image_MI_bw = ~Image_MI_bw;
%% count black pixels as LV blood pool 
Image_LV = imread([info.patient,'_label_VR.png']);
[Image_LV_bw,num_LV] = Count_Non_White_Pixel(Image_LV,1);
Image_LV_bw = ~Find_Biggest_Component(Image_LV_bw,1);
percentage_MI = num_MI / num_LV;
%% process MI pixels to measure MI size
[Image_MI_processed,MI_sizes] = Measure_MI_Patches_Size(Image_MI_bw,Image_LV_bw,20,2,1);
