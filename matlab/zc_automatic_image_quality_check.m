%% add path
clear all;
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load');
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions');
%% Load the patient table
year = '2019';
T = readtable(['/Users/zhennongchen/Documents/Zhennong_CT_Data/Patient_Overview/',year,'_Patient_Radiology_Records_Function.csv']);
%%
column_list = T.Properties.VariableNames;
