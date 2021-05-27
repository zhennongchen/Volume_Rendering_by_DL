%%
% this script uses the segmentation (rotated by pre-defined matrix)
% and the SQUEEZ results (pre-measured in 2mm)
% to generate labeled-volume-show with infarct colored.
%% add path
clear all;
addpath(genpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/'));
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/';
data_path = '/Volumes/Seagate MacOS/';
load([code_path,'configuration_list/config_label_MI.mat'])
load([code_path,'configuration_list/config_label_LV.mat'])
load([code_path,'configuration_list/config_label_multi.mat'])
load([code_path,'configuration_list/config_label_overlaid_moderate_WMA.mat'])
load([code_path,'configuration_list/config_label_overlaid_multi_class_for_WMA.mat'])
load([code_path,'configuration_list/config_label_overlaid_severe_WMA.mat'])
load([code_path,'configuration_list/config_label_overlaid_single_class_for_WMA.mat'])
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
%%
% WMA_region_size_counting: yellow: RSct>-0.15, red: RSct>-0.10
% WMA_region_size_counting_0.2_0.1: yellow: RSct>-0.20, red: RSct>-0.10
for num = 226%1:size(class_list,1)
    
    patient_class = convertStringsToChars(class_list(num,:));
    patient_id = convertStringsToChars(id_list(num));
    disp(patient_class)
    disp(patient_id)
    
    
    save_folder = [data_path,'Volume_Rendering_Movies_MATLAB/',patient_class,'/',patient_id];
    
    region_measure_done = isfile([save_folder,'/WMA_region_size_counting.txt']);
    movie_done = isfile([save_folder,'/SQUEEZ_movies/',patient_id,'_AllViews_4DSqueez.mp4']);

    if region_measure_done == 1 && movie_done == 1
         disp('already done')
         continue
    end
     
    mkdir(save_folder)

     % Load SQUEEZ result
    squeez_file = [data_path,'/SQUEEZ_results/',patient_class,'/',patient_id,'/results/SQUEEZ_data.mat'];
    if isfile(squeez_file) == 0
        error('No SQUEEZ pre-calculated')
    end
    load(squeez_file);
    clear squeez_file

    if movie_done == 0
        % make SQUEEZ movie
        info.save_movie_path = [save_folder,'/SQUEEZ_movies/'];
        mkdir(info.save_movie_path);
        [Mesh,info] = squeez_4D_movie_modified(Mesh,info);
        close all
    else
        disp(['squeez movie done']);
    end
        

    % Load segmentation (2mm) and rotate
    if region_measure_done == 0

    rot_angle_file = [data_path,'/SQUEEZ_results/',patient_class,'/',patient_id,'/rot_angle_2mm.mat'];
    if isfile(rot_angle_file) == 0
        error('No pre-defined rotation angle, end the process');
    end
    load(rot_angle_file,'rot')
    clear rot_angle_file
    
    seg_folder = [data_path,'/predicted_seg/',patient_class,'/',patient_id,'/seg-pred-0.625-4classes-connected-retouch-downsample'];
    if isfolder(seg_folder) == 0
        error('No downsampled segmentation, end the process');
    end
    seg_files = Sort_time_frame(Find_all_files(seg_folder),'_');
    count = 1;
    for i = 1:size(seg_files,1)
        seg_data = load_nii([seg_folder,'/',convertStringsToChars(seg_files(i))]);
        seg = Transform_nii_to_dcm_coordinate(double(seg_data.img),0);
        [Data(count).seg_rot] = Rotate_Volume_by_Rotation_Angles(seg,rot,0,3);
        count = count +1 ;
    end
    clear seg seg_data seg_files seg_folder
    
    
    % Assign ED and ES
    ed = 1;
    es = find(info.vol == min(info.vol));
    
    % assign MI pixels (with RSct > threshold) in the segmentation
    threshold_RSct_moderate = -0.15;
    threshold_RSct_severe = -0.10;
    slice_show = 0;%round(size(Data(ed).seg_rot,3)/2) -10;
    % in seg_WMA_multi, moderate pixels' vale = 9, severe pixels = 20
    [seg_WMA,seg_WMA_multi] = Label_WMA_in_segmentation(Data(ed).seg_rot,Mesh,ed,es,threshold_RSct_severe,threshold_RSct_moderate,slice_show);

    % make labeled_vol_show
    view_angle = [0:60:350];
    image_save_folder = [save_folder,'/WMA_labeled_pngs'];
    mkdir(image_save_folder);
    Make_Labeled_Volshow_For_WMA(view_angle,Data(ed).seg_rot,seg_WMA,seg_WMA_multi,config_label_LV,config_label_MI,config_label_overlaid_multi_class_for_WMA,config_label_overlaid_severe_WMA,...
    config_label_overlaid_moderate_WMA,image_save_folder,patient_class,patient_id)
    
    % measure WMA patches size
    rows_of_Mitral_Valve = 20; 
    rows_of_Mitral_Valve_center = rows_of_Mitral_Valve + 5; % when MV is at the center of image
    dilate_size = 2;
    if size(unique(seg_WMA),1) == 3
        WMA_exist = 1;
    else
        WMA_exist = 0;
    end
    multi_class_in_WMA_measure = 1;  

    [WMA_patches_measures] = Measure_Region_of_WMA_Size_From_Labeled_Volshow(WMA_exist, seg_WMA_multi,patient_id,image_save_folder,view_angle,rows_of_Mitral_Valve,rows_of_Mitral_Valve_center, dilate_size,multi_class_in_WMA_measure,config_label_MI);
   
    % save as txt file
    fid = fopen([save_folder,'/WMA_region_size_counting.txt'],'wt');
    for ii = 1:size(WMA_patches_measures,2)
        w = WMA_patches_measures(ii);
        if multi_class_in_WMA_measure == 0
            txt = ['angle is: ',num2str(w.angle),'; WMA_size_not_processed: ',num2str(w.num_WMA_no_processed),...
                '; percentage_no_processed: ',num2str(round(w.percentage_WMA_no_processed,2)),...
                '; WMA_size_processed: ',num2str(w.num_WMA_processed),'; percentage_processed: ',num2str(round(w.percentage_WMA_processed,2))];
        else
            txt = ['angle is: ',num2str(w.angle),'; WMA_size_not_processed: ',num2str(w.num_WMA_no_processed),...
                '; percentage_no_processed: ',num2str(round(w.percentage_WMA_no_processed,2)),...
                '; WMA_size_processed: ',num2str(w.num_WMA_processed),'; percentage_processed: ',num2str(round(w.percentage_WMA_processed,2)),...
                '; moderate_percent: ',num2str(round(w.percentage_moderate_processed,2)),...
                '; severe_percent: ',num2str(round(w.percentage_severe_processed,2))];
        end    
        
        fprintf(fid, txt);
        if ii ~= size(WMA_patches_measures,2)
            fprintf(fid,'\n');
        end
    end
    fclose(fid);

    else
        disp(['region measure done'])
end

%     
   
    
end
