%% Run this script to obtain ITK threshold used for LV segmentation %%

clear all; close all; clc;
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/';
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions');
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load');
%%  Load all patients
%main_path = '/Volumes/McVeighLab/projects/Zhennong/AI/AI_datasets/';
main_path = '/Volumes/Seagate MacOS/';
image_path = [main_path,'downsample-nii-images-1.5mm/Normal/'];
save_path = main_path;
patient_list = Find_all_folders(image_path);
%% select one patient
num = 163;
patient = patient_list(num).name;
disp(patient)
nii_file_name = [image_path,patient,'/img-nii-1.5/0.nii.gz'];
data = load_nii(nii_file_name);
image = Transform_nii_to_dcm_coordinate(data.img,0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% CHANGE TO PATH WHERE MID-AXIAL SLICE IS LOCATED %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

slice = round(size(image,3)/2);
IM = double(image(:,:,slice));
[x,y]=size(IM);

%%%%%%%%%%%% Draw boundary around Myocardium + LV blood pool %%%%%%%%%%%%

figure;
imagesc(IM); axis equal; colormap(gray)
title('Draw Boundary Around Myocardium & LV Blood pool')

h=drawpolyline;
bw = poly2mask(h.Position(:,1),h.Position(:,2),x,y);


MASK = bw.*double(IM);
imagesc(MASK);
truesize([300 300])

THRESH = multithresh(MASK,1);

figure;

x = zeros(size(IM));
idx = MASK >= THRESH;
x(idx) = 1;

imagesc(x)

THRESH = round(THRESH,-1);

%%%%%%%%%%%% DISPLAY THRESHOLD VALUE TO USER %%%%%%%%%%%%

disp('Your threshold is:')
disp(THRESH)

fid = fopen([save_path,'predicted_seg/Normal/',patient,'/threshold.txt'], 'wt');

fprintf(fid, '%d', THRESH);

fclose(fid);
close all
