%% add path
clear all
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab';
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load')
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions')
%% use a cube as an example
image = zeros(30,30,30);
for i = 1:size(image,1)
    for j = 1:size(image,2)
        for k = 1:size(image,3)
            if i>=10 && i <20 && j >=10 && j<20 && k>=10 && k<20
                image(i,j,k) = 1;
            end
        end
    end
end
cube = image > 0;
%% load nii images and segmentation
% images
main_folder = '/Volumes/McVeighLab/projects/Zhennong/AI/CNN/all-classes-all-phases-1.5/';
patient = 'ucsd_siemens/279711';
nii_file_name = [main_folder,patient,'/img-nii-sm/0.nii.gz'];
data = load_nii(nii_file_name);
nii_image_siemens = Transform_nii_image(double(data.img));
%% find the cameraposition




        