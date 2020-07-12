%% add path
clear all
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/matlab/NIfTI image processing/');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/matlab/iso2mesh');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/matlab/functions');
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load')
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions')
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab';
%% load images
% images
image_file_name = '/Volumes/McVeighLab/projects/Zhennong/AI/CNN/all-classes-all-phases-1.5/ucsd_bivent/CVC1801081753/img-mat-sm/0.mat';
load(image_file_name)

seg_file_name = '/Volumes/McVeighLab/projects/Zhennong/AI/CNN/all-classes-all-phases-1.5/ucsd_bivent/CVC1801081753/seg-mat-sm/0.mat';
load(seg_file_name)
seg = zeros(size(segmentation));
seg(segmentation==1) = 1;
seg(segmentation==2) = 1;
seg(segmentation==4) = 1;
seg_binary = seg > 0;

%% get LV axis vector from MV plane
load('/Users/zhennongchen/Documents/Zhennong_AI project/Patient mat data/Patient SAX plane vector/ucsd_bivent_CVC1801081753_par.mat');
LV_axis = Normalize_Vector(cross(final_x,final_y));
% get transformation (rotation) matrix
[r1,m1,~,~] = Find_Transform_Matrix_For_Two_Vectors(Normalize_Vector(LV_axis),[0,0,-1]);%nontoshiba: only final_y to [1,0,0], toshiba: only final_t to [0,0,-1]
R = [m1(1,1) m1(1,2) m1(1,3) 0 ;m1(2,1) m1(2,2) m1(2,3) 0;m1(3,1) m1(3,2) m1(3,3) 0;0 0 0 1];
R_form = affine3d(R);
seg_rot_from_mv = imwarp(seg,R_form);
%
%[r1,m1,~,~] = Find_Transform_Matrix_For_Two_Vectors([0,1,0],[0,-1,0]);
%R = [m1(1,1) m1(1,2) m1(1,3) 0 ;m1(2,1) m1(2,2) m1(2,3) 0;m1(3,1) m1(3,2) m1(3,3) 0;0 0 0 1];
%R_form = affine3d(R);
%seg_rot_from_mv2 = imwarp(seg_rot_from_mv,R_form);
%nii_seg_rot_from_mv = permute(nii_seg_rot_from_mv,[3 1 2]);
%toshiba:
%nii_seg_rot_from_mv = flip(nii_seg_rot_from_mv_2,3);
%% view in volshow
scale = [2,2,2];
volshow(seg_rot_from_mv,config_028_raw,'ScaleFactors',scale);

%%
% patient_class: "ucsd_bivent", patient_num = 1~17
% patient_class: "ucsd_ccta", patient_num = 1
% patient_class: "ucsd_lvad", patient_num = 1
% patient_class: "ucsd_pv", patient_num = 1~19
% patient_class: "ucsd_siemens", patient_num = 1~11
% patient_class: "ucsd_tavr_1", patient_num = 1~24
% patient_class: "ucsd_toshiba", patient_num = 1~21
clear all
load('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/matlab/patient_list.mat')
patient_class = "ucsd_toshiba";
patient_num = 21; % the Patinet no. in that patient class

% get the patient_class, p_class and patient_id, p_id
[p_class,p_id] = find_patient(patient_list,patient_class,patient_num);
fr = 0;
image_name = ['/Volumes/McVeighLab/projects/Zhennong/AI/CNN/all-classes-all-phases-1.5/',p_class,'/',p_id,'/seg-nii-sm/',num2str(fr),'.nii.gz'];
%%
info.tf = 20; %number of time frames to systole
% should set it to 0.5 if need high resolution
info.iso_res = 1.5; %Isotropic resolution for rotation (prior to rotation)
% get patient_specific rotation angle
data = load_nii(image_name);
dx = data.hdr.dime.pixdim(2);
dy = data.hdr.dime.pixdim(3);
dz = data.hdr.dime.pixdim(4);
res = info.iso_res;
I = zeros(size(data.img));
I(data.img==1) = 1;
I = Transform_nii_image(I);
%%
ind = find(I==1);
[row,col,zz] = ind2sub(size(I),ind);
xmin = min(row); xmax = max(row);
ymin = min(col); ymax = max(col);
zmin = min(zz);  zmax = max(zz);
tol = 5; 
I = I(xmin-tol:xmax+tol,ymin-tol:ymax+tol,zmin-tol:zmax+tol);
x = (1:size(I,2)).*dy;
y = (1:size(I,1)).*dx;
z = (1:size(I,3)).*dz;
xq = linspace(1*dy,size(I,2)*dy,round(length(x)*(dy/res)));
yq = linspace(1*dx,size(I,1)*dx,round(length(y)*(dx/res)));
zq = linspace(1*dz,size(I,3)*dz,round(length(z)*(dz/res)));
I = interp3(x,y,z,I,xq,yq',zq);
figure('pos',[10 10 1000 1000])
imagesc(I(:,:,round(size(I,3)/2))); hold on
axis equal; colormap gray; caxis([0 1])
title('Rotate about Z axis: Click at base FIRST, THEN at apex','FontSize',30)
[yp,zp] = ginput(2);
info.th_rot_z = atan2(abs(diff(yp)),abs(diff(zp)));
th_rot_z = info.th_rot_z;
t_z = [cos(th_rot_z) -sin(th_rot_z) 0 0; sin(th_rot_z) cos(th_rot_z) 0 0; 0 0 1 0; 0 0 0 1];
tform_z = affine3d(t_z);
I_rot_z = imwarp(I,tform_z);
%
%%
figure('pos',[10 10 1000 1000])
imagesc(squeeze(I_rot_z(:,round(size(I_rot_z,2)/2),:)));
axis equal; colormap gray; caxis([0 1])
title('Rotate about X axis: Click at base FIRST, THEN at apex','FontSize',30)
[yp,zp] = ginput(2);
th_rot_x = -atan2(abs(diff(yp)),abs(diff(zp)));
save(['/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/angle_info/',p_class,'_',p_id,'_angle','.mat'],'th_rot_z','th_rot_x')