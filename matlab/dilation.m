%% add path
clear all
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab';
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load')
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions')
%% load nii image
nii_file_name = '/Users/zhennongchen/Documents/Zhennong_VR/Data/CVC1805021118/img-nii/0.nii.gz';
data = load_nii(nii_file_name);
nii_image = Transform_nii_image(double(data.img));
%% load nii segmentation
seg_file_name = '/Users/zhennongchen/Documents/Zhennong_VR/Data/CVC1805021118/seg-nii/0.nii.gz';
seg = load_nii(seg_file_name);
nii_seg = zeros(size(seg.img));
nii_seg(seg.img==1) = 1;
nii_seg(seg.img==2) = 2;
nii_seg = Transform_nii_image(nii_seg);
%% dilate
SE = strel('sphere',6);
dilated = imdilate(nii_seg,SE);
%% pick a slice of segmentation with holes
s = 130;
slice = nii_seg(:,:,s);
figure(1)
imagesc(slice);
figure(2)
imagesc(dilated(:,:,s));
%% only keep LV and LA in the greyscale image
[lv_x,lv_y,lv_z] = ind2sub(size(dilated),find(dilated == 1));
[la_x,la_y,la_z] = ind2sub(size(dilated),find(dilated == 2));

new_image = zeros(size(nii_image));
for i = 1 : size(lv_x,1)
    new_image(lv_x(i),lv_y(i),lv_z(i)) = nii_image(lv_x(i),lv_y(i),lv_z(i));
end
for i = 1 : size(la_x,1)
    new_image(la_x(i),la_y(i),la_z(i)) = nii_image(la_x(i),la_y(i),la_z(i));
end
close all
figure(1)
imagesc(nii_image(:,:,130));
figure()
imagesc(new_image(:,:,130));
%% save the filtered image
dicom_folder = '/Users/zhennongchen/Documents/Zhennong_VR/Data/CVC1805021118/img-dcm/Cardiac_Morphology_CTA_301_200%';
dicom_files=dir([dicom_folder,'/','*.dcm']);
cd(dicom_folder);

main_path = fileparts(fileparts(dicom_folder));
save_folder = [main_path,'/','dilated-img-dcm'];
mkdir(save_folder)

%%export as Dicom
cd(dicom_folder)
new_image_int = int16(new_image);

for i= 1:numel(dicom_files)
X=[save_folder,'/dilated_image',num2str(i),'.dcm'];
metadata=dicominfo(dicom_files(i).name);
metadata.SeriesDescription='dilated_timeframe_1';
metadata.SeriesNumber = 1000; % key parameter to differentiate time frames
metadata.RescaleIntercept = 0; % important
a =(new_image_int(:,:,i));
dicomwrite(a,X,metadata);
end