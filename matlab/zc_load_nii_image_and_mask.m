%% add path
clear all
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab';
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load')
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions')
%% load nii image
nii_file_name = '/Users/zhennongchen/Documents/Zhennong_VR/Data/028/img-nii-sm-1.5/0.nii.gz';
data = load_nii(nii_file_name);
%% pixel spacing:
% data.hdr can obtain the hdr dataset
dx = data.hdr.dime.pixdim(2);
dy = data.hdr.dime.pixdim(3);
dz = data.hdr.dime.pixdim(4);
%% obtain the image data from nii
raw_image = double(data.img);
%% transform the image from nii coordinate to mat coordinate
nii_image = permute(raw_image,[2 1 3]);
nii_image = flip(nii_image,1);
nii_image = flip(nii_image,2);
nii_image = flip(nii_image,3);
%% obtain the image data from dicom
dicom_folder = '/Users/zhennongchen/Documents/Zhennong_VR/Data/028/img-dcm/HALF 0% 0.73s Cardiac 0.5 CE - 2';
dicom_files=dir([dicom_folder,'/','*.dcm']);
cd(dicom_folder);

info=dicominfo(dicom_files(1).name);
for l=1:numel(dicom_files)
    img=dicomread(dicom_files(l,1).name);
    img = info.RescaleSlope.*img + info.RescaleIntercept;
    dicom_image(:,:,l) = img;
end
%dicom_image = double(dicom_image);

pixel_size=[];
for l=1:numel(dicom_files)
info=dicominfo(dicom_files(l).name);pixel_size(l)=info.PixelSpacing(1);
end
pixel_size=pixel_size(1);
cd(code_path)
%% view nii_image and dicom_image
figure(1)
imagesc(dicom_image(:,:,6));
figure(2)
imagesc(nii_image(:,:,2));
cd(code_path)
%% view both images as greyscale
window_level = 500;
window_width = 900;
slice_number = 1;
nii_image_slice = Turn_data_into_greyscale(nii_image(:,:,slice_number),window_level,window_width);
dicom_image_slice = Turn_data_into_greyscale(dicom_image(:,:,slice_number),window_level,window_width);
figure(3)
imshow(nii_image_slice);
figure(4)
imshow(dicom_image_slice);
%% load nii segmentation
seg_file_name = '/Users/zhennongchen/Documents/Zhennong_VR/Data/CVC1805021118/seg-nii/0.nii.gz';
seg = load_nii(seg_file_name);


nii_seg = zeros(size(seg.img));
nii_seg(seg.img==1) = 1;
nii_seg(seg.img==2) = 2;

nii_seg = Transform_nii_image(nii_seg);
%% view segmentation
close all
figure(1)
imagesc(dicom_image(:,:,170));
figure(2)
imagesc(nii_image(:,:,170));
figure(3)
imagesc(nii_seg(:,:,170));
%% only keep LV and LA in the greyscale image
[lv_x,lv_y,lv_z] = ind2sub(size(nii_seg),find(nii_seg == 1));
[la_x,la_y,la_z] = ind2sub(size(nii_seg),find(nii_seg == 2));

new_image = zeros(size(dicom_image));
for i = 1 : size(lv_x,1)
    new_image(lv_x(i),lv_y(i),lv_z(i)) = dicom_image(lv_x(i),lv_y(i),lv_z(i));
end
for i = 1 : size(la_x,1)
    new_image(la_x(i),la_y(i),la_z(i)) = dicom_image(la_x(i),la_y(i),la_z(i));
end
close all
figure(1)
imagesc(nii_image(:,:,130));
figure()
imagesc(new_image(:,:,130));
%% save the filtered image
main_path = fileparts(fileparts(dicom_folder));
save_folder = [main_path,'/','masked-img-dcm'];
mkdir(save_folder)

%%export as Dicom
cd(dicom_folder)
new_image_int = int16(new_image);

for i= 1:numel(dicom_files)
X=[save_folder,'/masked_image',num2str(i),'.dcm'];
metadata=dicominfo(dicom_files(i).name);
metadata.SeriesDescription='masked_timeframe_1';
metadata.SeriesNumber = 1100; % key parameter to differentiate time frames
metadata.RescaleIntercept = 0; % important
a =(new_image_int(:,:,i));
dicomwrite(a,X,metadata);
end
