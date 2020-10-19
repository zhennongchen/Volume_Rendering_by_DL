%% add path
clear all;
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load');
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions');
addpath(genpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/SQUEEZ functions'));
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/';
%data_path = '/Volumes/McVeighLab/projects/Zhennong/AI/CNN/all-classes-all-phases-1.5/';
data_path = '/Volumes/McVeighLab/projects/Zhennong/Zhennong_CT_Data/';
%% Step 1: Define patient and parameters
patient = 'CVC1809171438';
savepath = ['/Users/zhennongchen/Documents/Zhennong_CT_Data/VR_dataset/',patient];
mkdir(savepath)
image_folder_high = 'img-nii';image_folder_low = 'img-nii-1.5';
seg_folder_high = 'seg-nii';seg_folder_low = 'seg-nii-1.5';

cd([data_path,patient,'/',seg_folder_high])
files = dir(['*.nii.gz']);
timeframes = [];
for i = 1: size(files,1)
    n = files(i).name;
    s = split(n,'.');
    timeframes = [timeframes str2num(s{1})+1];
end
timeframes = sort(timeframes);
cd(code_path)
clear s n
%% Step 2: Get ED/ES
% if already defined in es.txt, then no need to do this step
ed = 1;
if isfile([data_path,'/',patient,'/es.txt']) == 1
    fID = fopen([data_path,'/',patient,'/es.txt'],'r');
    es = fscanf(fID,'%d');
    edes = [ed,es+1];
else
    [es,lv_volume_list] = Find_ES_by_LV_Volume_List([data_path,'/',patient,'/',seg_folder_low,'/'],timeframes);
    edes = [ed,timeframes(es)];
    es = timeframes(es);
    fid = fopen([data_path,patient,'/es.txt'],'wt');
    fprintf(fid, '%d',es-1);
    fclose(fid);
end
clear ed es fID
%% Step 3: Obtain Re-orientation angle 
rot_angle = Obtain_Reorientation_Angle_for_Patient(patient,[data_path,patient,'/',image_folder_low,'/'],[data_path,patient,'/',seg_folder_low,'/']);
%% Step 4: Get Data for SQUEEZ test
save_data = 1;
for i = 1:size(edes,2)
    t = edes(i);
    image_data = load_nii([data_path,patient,'/',image_folder_low,'/',num2str(t-1),'.nii.gz']);
    image = Transform_nii_to_dcm_coordinate(double(image_data.img),0);
    
    seg_data = load_nii([data_path,patient,'/',seg_folder_low,'/',num2str(t-1),'.nii.gz']);
    seg = Transform_nii_to_dcm_coordinate(double(seg_data.img),0);
    
    [Irot,segrot,rot_angle] = Rotate_LV_Correct_Orientation(image,seg,1,rot_angle);
    Data(t).image_hdr = image_data.hdr; Data(t).image = image; Data(t).seg_hdr = seg_data.hdr; Data(t).seg = seg; 
    Data(t).image_rot = Irot; Data(t).seg_rot = segrot; Data(t).rotinfo = rot_angle;
end
%% Step 4b: use volshow to assess the orientation angle
load([code_path,'config_default.mat']);
view_angle = [0:60:350];
[position_list] = Make_Volshow_all_Angle(Data(1).seg_rot > 0,view_angle,config);
%% Step 4c: save
if save_data == 1
    save([savepath,'/',patient,'_rot_angle.mat'],'Data','rot_angle','edes');
end
clear t Irot segrot
%% Step 5: run SQUEEZ (go to Main_SQUEEZ.m)
% it should save SQUEEZ result in save_path/SQUEEZ_result
clear Mesh full_cycle figs figV
load([savepath,'/SQUEEZ_Results/',patient,'_step4_MeshRotation.mat'],'Mesh','info')
%% Step 6: assign MI pixels different pixel value in segmentation
set_threshold_manual = 1;
if set_threshold_manual == 1
    threshold = -0.1;
else
    rs_list = Mesh(edes(2)).RSct_vertex';
    threshold = max(rs_list) - (max(rs_list) - min(rs_list)) * 0.2;
end

[seg_MI,seg_rot] = Localize_MI(Data(edes(1)).seg_rot,Mesh,threshold,edes,120);
%% Step 7: get MI size for each view angle
save_data = 1;
load([code_path,'config_label_MI.mat'])
load([code_path,'config_label_LV.mat'])
load([code_path,'config_label_multi.mat'])
image_save_path = [savepath,'/png_image']; mkdir(image_save_path);
view_angle = [0:60:350];
rows_of_MV = 20; 
dilate_size = 2;
[MI_measures] = Measure_MI_Size_From_each_ViewAngle(view_angle,seg_rot,config_label_LV,seg_MI,config_label_MI,config_label_multi,image_save_path,patient,rows_of_MV,dilate_size);
if save_data == 1
    save([savepath,'/',patient,'_MI_measures.mat'],'MI_measures','view_angle');
end