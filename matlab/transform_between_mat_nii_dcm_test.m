%% add path
clear all
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab';
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load')
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions')
%%
load('/Users/zhennongchen/Documents/GitHub/AI_reslice_orthogonal_view/Matlab code/patient_list.mat')
%% Test our algorithm to transform mat file coordinate system to dcm file coordinate system
nii_main_folder = '/Volumes/McVeighLab/projects/Zhennong/AI/CNN/all-classes-all-phases-1.5/';
for patient_num = 18%size(patient_list,1)


p_class = convertStringsToChars(patient_list(patient_num,1));
p_id = convertStringsToChars(patient_list(patient_num,2));
main_path = '/Users/zhennongchen/Documents/Zhennong_AI project/Patient mat data/';
load_path = [main_path,p_class,'_',p_id,'.mat'];
load(load_path,'image');

nii_file_name = [nii_main_folder,p_class,'/',p_id,'/img-nii-sm/0.nii.gz'];
data = load_nii(nii_file_name);
nii_image = Transform_nii_image(double(data.img));

if patient_num < 74 % for cases that are not toshiba
    output = flip(image,3);
    output = permute(output,[2 1 3]);
    output = flip(output,1);
else % for toshiba
    output = permute(image,[2 1 3]);
end
figure('Name',[p_class,'_',p_id,'_dcm']);imagesc(nii_image(:,:,48));
figure('Name',[p_class,'_',p_id,'_mat']);imagesc(output(:,:,48));
end