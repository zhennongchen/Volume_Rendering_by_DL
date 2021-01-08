% this script can rotate the image adata + segmentation data into correct
% orientation as a pre-processing step. 
%% add path
clear all
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/matlab/NIfTI image processing/');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/matlab/iso2mesh');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/matlab/functions');
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load')
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions')
addpath(genpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/SQUEEZ functions'));
info.code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab';
info.main_data_path = '/Volumes/McVeighLab/projects/Zhennong/AI/CNN/all-classes-all-phases-1.5/';
%info.main_data_path = '/Volumes/McVeighLab/projects/Zhennong/Zhennong_CT_Data/';
%% define patient
info.patient_class = 'ucsd_bivent';  
info.patient_id = 'CVC1801031002';
cd([info.main_data_path,info.patient_class,'/',info.patient_id,'/seg-nii-sm/'])
seg_files = dir(['*.nii.gz']);
info.timeframes = [];
for i = 1: size(seg_files,1)
    n = seg_files(i).name;
    s = split(n,'.');
    info.timeframes = [info.timeframes str2num(s{1})+1];
end

cd(info.code_path);
%info.timeframes = [1,8];  % [ED,ES] corresponding to ED-1.nii.gz and ES-1.nii.gz
%% load data
for i = 1:size(info.timeframes,2)
    nii_file_name = [info.main_data_path,info.patient_class,'/',info.patient_id,'/img-nii-sm/',num2str(info.timeframes(i)-1),'.nii.gz'];
    image_data = load_nii(nii_file_name);
    image = Transform_nii_to_dcm_coordinate(double(image_data.img),0);
    
    seg_file_name = [info.main_data_path,info.patient_class,'/',info.patient_id,'/seg-nii-sm/',num2str(info.timeframes(i)-1),'.nii.gz'];
    seg_data = load_nii(seg_file_name);
    seg_raw = zeros(size(seg_data.img));
    seg_raw(seg_data.img == 1) = 1;
    seg_raw(seg_data.img == 2) = 2;
    seg_raw(seg_data.img == 4) = 4;
    seg_raw(seg_data.img == 6) = 6;
    seg_raw(seg_data.img == 7) = 7;
    seg_raw(seg_data.img == 8) = 8;
    seg_raw(seg_data.img == 9) = 9;
    seg = Transform_nii_to_dcm_coordinate(seg_raw,0);
    
    Whole_Data(info.timeframes(i)).image_metadata = image_data; 
    Whole_Data(info.timeframes(i)).image = image;
    Whole_Data(info.timeframes(i)).seg_metadata = seg_data;
    Whole_Data(info.timeframes(i)).seg = seg;
    disp(['finish loading time frame ',num2str(info.timeframes(i)-1)]);
end
%% Find ED and ES
lv_num_list = [];
for i = 1:size(info.timeframes,2)
    seg_this_frame = Whole_Data(info.timeframes(i)).seg;
    lv_num_list = [lv_num_list size(find(seg_this_frame == 1),1)];
end
ES = find(lv_num_list == min(lv_num_list));
info.timeframes = [1 info.timeframes(ES)];
timeframes = info.timeframes;
for i = 1:size(info.timeframes,2)
    Data(info.timeframes(:,i)) = Whole_Data(info.timeframes(:,i));
end
%% method: load image from nii file and then rotate based on anatomical landmarks
for i = 1:size(info.timeframes,2)
    t = info.timeframes(i);
    if i == 1
        [Irot,segrot,rot] = Rotate_LV_Correct_Orientation(Data(t).image,Data(t).seg,0,0);
    else
        [Irot,segrot,rot] = Rotate_LV_Correct_Orientation(Data(t).image,Data(t).seg,1,rot);
    end
    
    Data(t).image_rot = Irot; Data(t).seg_rot = segrot; Data(t).rotinfo = rot;
    clear t Irot segrot
end

%% plot the rotated data
figure(1)
imagesc(Data(1).image_rot(:,:,120))
figure(2)
imagesc(Data(info.timeframes(2)).image_rot(:,:,120))
%% test by volume show
load([info.code_path,'/config_default']);
scale = [2 2 2];
figure(3)
volshow(Data(1).seg_rot > 0,config,'ScaleFactors',scale);
% rotate in x-y plane to get different walls
config_rot = config;
position = config_rot.CameraPosition';
[rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,300,1);

new_position = rot_in_xy * position;
config_rot.CameraPosition = new_position';
figure(5)
volshow(Data(1).seg_rot>0,config_rot,'ScaleFactors',scale);
%% test by SQUEEZ rotation
Check_SQUEEZ_rotation(Data,info)
%% save data
info.savedata_path = '/Users/zhennongchen/Documents/Zhennong_CT_Data/AI_dataset/rotated_data/';
name = [info.patient_class,info.patient_id,'_rot.mat'];
save([info.savedata_path,name],'Data','info','timeframes')