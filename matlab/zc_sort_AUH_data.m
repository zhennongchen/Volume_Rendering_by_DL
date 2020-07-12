%% add path for matlab functions
clear all
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab';
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions')
%% define the main path where all patient studies are saved
main_path = '/Users/zhennongchen/Documents/Zhennong_CT_Data/AUH';
% find all patients
patient_list = Find_all_folders(main_path);
% find all studies (pre and post)
for i = 1:size(patient_list,1)
    p = patient_list(i).name;
    studies = Find_all_folders([main_path,'/',p]);
    for j = 1:size(studies,1)
        if i==1 && j == 1
            study_list = char(studies(j).name);
            path_list = char([main_path,'/',p,'/',studies(j).name]);
        else
            study_list = char(study_list,studies(j).name);
            path_list = char(path_list,[main_path,'/',p,'/',studies(j).name]);
        end
    end
end 
%% define the patient no. (1~182) whose data you want to sort
patient_choice = [1];
paths = Find_paths_belong_to_patients(patient_choice,path_list);
%% sort the data
tic
for i = 1%:size(paths,1)
    path = strtrim(paths(i,:)); % delete the trailing whitespace
    output_path = [path,'/img_sorted'];
    if ~exist(output_path,'dir')
        mkdir(output_path)
    end
    
    % find all the dicom files under that study
    dicom_files = dir([path,'/*/*/*/*']);
    dicom_files(ismember( {dicom_files.name}, {'.', '..'})) = [];
    for j = 1:size(dicom_files,1)
        f = dicom_files(j).folder;
        cd(f)
        % find the TF (time frame)
        info = dicominfo(dicom_files(j).name);
        scanoption = info.ScanOptions;
        [TF_string,TF_num] = Find_Time_Frame_From_Scanoption(scanoption);
        % make the folder for each time frame
        if TF_num == 0 || TF_num == 5
           output_folder = [output_path,'/0',TF_string];
        elseif TF_num == 100
                continue
        else
            output_folder = [output_path,'/',TF_string];
        end
        if ~exist(output_folder,'dir')
            mkdir(output_folder)
        end
        % copy the dicom file to the corresponding time frame folder
        copyfile(dicom_files(j).name,output_folder)
        
    end
end
toc
    