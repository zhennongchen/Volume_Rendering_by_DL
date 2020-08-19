%% add path
clear all
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/matlab/NIfTI image processing/');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/matlab/iso2mesh');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/matlab/functions');
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load')
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions')
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab';
%% load images
patient_class = 'ucsd_toshiba';   
patient_id = '000';%'CVC1803071006';
% images
image_file_name = ['/Volumes/McVeighLab/projects/Zhennong/AI/CNN/all-classes-all-phases-1.5/',patient_class,'/',patient_id,'/img-mat-sm/0.mat'];
load(image_file_name)

seg_file_name = ['/Volumes/McVeighLab/projects/Zhennong/AI/CNN/all-classes-all-phases-1.5/',patient_class,'/',patient_id,'/seg-mat-sm/0.mat'];
load(seg_file_name)
seg = zeros(size(segmentation));
seg(segmentation==1) = 1;
seg(segmentation==2) = 1;
seg(segmentation==4) = 1;
seg(segmentation == 6) = 1;
seg(segmentation == 7) = 1;
seg(segmentation == 8) = 1;
seg(segmentation == 9) = 1;

%% apply segmentation as a mask
[x,y,z] = ind2sub(size(seg),find(seg == 1));
new_image = zeros(size(image));
for i = 1 : size(x,1)
    new_image(x(i),y(i),z(i)) = image(x(i),y(i),z(i));
end
%% set WL and WW
WL = 430;
WW = 200;
J = Turn_data_into_greyscale(image,WL,WW);
J_new = Turn_data_into_greyscale(new_image,WL,WW);
figure()
imshow(J(:,:,54));

truesize([300,300]);