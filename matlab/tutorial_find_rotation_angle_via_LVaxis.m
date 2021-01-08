%% add path
clear all
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/matlab/NIfTI image processing/');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/matlab/iso2mesh');
addpath('/Users/zhennongchen/Documents/GitHub/Synthesize_heart_function_movie/matlab/functions');
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load')
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions')
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab';
%% load images
patient_class = 'ucsd_toshiba';   % if use 4C to rotate:wrong: ccta, tilt: bivent_CVC1708311422,CVC1708071113
patient_id = '028';
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
seg_binary = seg > 0;

%%
figure()
scale = [1,1,1];
f = volshow(seg,config_001,'ScaleFactors',scale);

%% get LV axis vector from 4C plane and rotate LV based on this
load(['/Users/zhennongchen/Documents/Zhennong_AI project/Patient mat data/',patient_class,'_',patient_id,'.mat']);
load(['/Users/zhennongchen/Documents/Zhennong_AI project/Patient mat data/Patient SAX plane vector/',patient_class,'_',patient_id,'_par.mat']);
LV_axis = Normalize_Vector(cross(final_x,final_y));

% get transformation (rotation) matrix
% if LV_axis from MV plane: nontoshiba - final_y to [1,0,0], toshiba - LV_axis to [0,0,-1]
% if LV_axis from 4C plane: nontoshiba - z_4C to [0,0,1], toshiba - y_4C to
% [0,0,1]
[~,R1,M1] = Find_Transform_Matrix_For_Two_Vectors(Normalize_Vector(LV_axis),[0,0,-1]);

% tips: matlab-generated transformation matrix is the transverse of the
% transmation matrix we usually write
% so if this M is not generated automatically by matlab (e.g.from three
% axis rotation degree), then matlab applys M' to the image
M1_form = affine3d(M1);
seg_rot = imwarp(seg,M1_form);

% view in volshow
scale = [2,2,2];

figure()
volshow(seg_rot,config_001,'ScaleFactors',scale);
%% then rotate LV in x-y plane 
% find the new position of orthogonal view's x,y,z in the new image
% coordinate system
z_4C_new = Normalize_Vector(New_Position_In_Transformed_Image(z_4C,R1,size(seg),size(seg_rot),0))
x_4C_new = Normalize_Vector(New_Position_In_Transformed_Image(x_4C,R1,size(seg),size(seg_rot),0))
y_4C_new = Normalize_Vector(New_Position_In_Transformed_Image(y_4C,R1,size(seg),size(seg_rot),0))
%%
[rot2,R2,~] = Find_Transform_Matrix_For_Two_Vectors(Normalize_Vector(z_4C_new),[0,1,0]);


config_rot = config_001;
position = config_rot.CameraPosition';
rot_degree = rot2(4) / pi * 180;
[rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,rot_degree);
new_position = rot_in_xy * position;
config_rot.CameraPosition = new_position';
figure()
volshow(seg_rot,config_rot,'ScaleFactors',scale);

%% rotate in x-y plane to get different walls
config_rot = config_001;
position = config_rot.CameraPosition';
[rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,-240);

new_position = rot_in_xy * position;
config_rot.CameraPosition = new_position';
figure()
volshow(seg_rot,config_rot,'ScaleFactors',scale);


% %%
% p = [100,100,50];
% disp(image(p(1),p(2),p(3)))
% pp = Apply_Transformation_On_Point(M,p);
% disp(image_test(pp(1),pp(2),pp(3)));
% %%
% [M_center] = Transform_Offset_Center(M,size(image));
% R_form_center = affine3d(M_center');
% image_test_center = imwarp(image,R_form_center);

