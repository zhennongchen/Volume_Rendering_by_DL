% this script can automatically exclude the disconnected parts in the
% segmentation and only keep the largest connectivity.
%%
close all;
clear all;
addpath(genpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/'));
%% List all patients
main_path = '/Volumes/Seagate MacOS/';
image_path = [main_path,'AI_plane_validation_study/Segs/Abnormal/'];
patient_list = Find_all_folders(image_path);
%% Do pixel clearning:
c = 0;
% Global_disconnect_cases = [];
% LA_disconnect_cases = [];
% LVOT_disconnect_cases = [];
for i = 1:size(patient_list,1)
    patient_name = patient_list(i).name;
    disp(patient_name)
    patient_folder = [image_path,patient_name,'/seg-pred/'];
    
    if isfolder(patient_folder) == 1
       % make save_folder
       c = c+1;
       save_folder = [image_path,patient_name,'/seg-pred-connected-mat'];
       mkdir(save_folder)
        
       nii_list = Sort_time_frame(Find_all_files(patient_folder),'_');
       
       Global_disconnect = 0;
       LA_disconnect = 0;
       LVOT_disconnect = 0;
       
       for j = 1: size(nii_list,1)
           file_name = [patient_folder,convertStringsToChars(nii_list(j))];
           data = load_nii(file_name);
           image = data.img;
           
           % exclude
           % First step: Get rid of any disconnected object
           BW = image > 0;
           [BW,image,change] = Find_largest_connected_component_3d(BW,image,0,6);
           if change == 1
               Global_disconnect = 1;
           end
           % check
           CC = bwconncomp(BW,6);
           numPixels = cellfun(@numel,CC.PixelIdxList);
           if size(numPixels,2) > 1
               error('Error occurred in exclusion');
           end
           
           
           % Second step: Turn disconnected object with label > 1 into
           % label = 1
           % (LA = 2, LVOT = 4)
           BW = image == 2;
           [BW,image,change] = Find_largest_connected_component_3d(BW,image,1,26);
           if change == 1
               LA_disconnect = 1;
           end
           BW = image == 4;
           [BW,image,change] = Find_largest_connected_component_3d(BW,image,1,26);
           if change == 1
               LVOT_disconnect = 1;
           end
           
           % Third step: Get rid of disconnected object with label = 1
           BW = image == 1;
           [BW,image,~] = Find_largest_connected_component_3d(BW,image,0,26);
           
           % put back to segmentation
           [image] = Transform_between_nii_and_mat_coordinate(image,1);
           % save
           t = Find_time_frame(convertStringsToChars(nii_list(j)),'_');
           save([save_folder,'/pred_s_',num2str(t),'.mat'],'image')
       end  
        
    else
        disp('Do NOT have seg-pred folder') 
    end          
end

        
    