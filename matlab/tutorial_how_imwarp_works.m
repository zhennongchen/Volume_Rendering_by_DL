%% Description:
% this script is a rotation test in which we apply a rotation matrix R to a
% image by imwarp, then we want to find out the new coordinates of one
% point in the new image.

%% 
clear all
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/';
addpath(genpath(code_path));
%% load one patient as example
patient_class = 'ucsd_toshiba';   % if use 4C to rotate:wrong: ccta, tilt: bivent_CVC1708311422,CVC1708071113
patient_id = '028';
% images
image_file_name = ['/Volumes/McVeighLab/projects/Zhennong/AI/CNN/all-classes-all-phases-1.5/',patient_class,'/',patient_id,'/img-mat-sm/0.mat'];
load(image_file_name)

seg_file_name = ['/Volumes/McVeighLab/projects/Zhennong/AI/CNN/all-classes-all-phases-1.5/',patient_class,'/',patient_id,'/seg-mat-sm/0.mat'];
load(seg_file_name)
seg = zeros(size(segmentation));
seg(segmentation>=1) = 1;
seg_binary = seg > 0;
%% rotation test
rot_x = 0;
rot_y = 0;
rot_z = 45;
[R,M] = Rotation_Matrix_From_Three_Axis(rot_x,rot_y,rot_z,1);
R_form = affine3d(M);
seg_test = imwarp(seg,R_form);
image_test = imwarp(image,R_form);
%%
center1 = size(seg)' / 2;
center2 = size(seg_test)'/2;
p = [99,59,70]';
so = R' * (p-center1)+center2;
sso = New_Coordinate_of_a_Point_In_Transformed_Image(p,R',size(seg),size(seg_test),1);
%%
figure()
imagesc(image(:,:,70));
hold on
plot(p(1),p(2),'rx')
axis equal
%%
figure()
imagesc(image_test(:,:,70));
hold on
axis equal
plot(round(sso(1)),round(sso(2)),'rx')