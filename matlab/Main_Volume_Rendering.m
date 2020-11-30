%% add path
clear all;
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load');
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions');
addpath(genpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/SQUEEZ functions'));
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/';
%data_path = '/Volumes/McVeighLab/projects/Zhennong/AI/CNN/all-classes-all-phases-1.5/';
data_path = '/Volumes/McVeighLab/projects/Zhennong/Zhennong_VR_Data/Abnormal/';
%% Step 1: Define patient and parameters
patient = 'CVC1809171438';
MN_or_DL = 'MN'; % MN = manual segmentation, DL = deep learning segmentation

save_path = ['/Users/zhennongchen/Documents/Zhennong_CT_Data/VR_dataset/examples/',patient];

image_folder_high = 'img-nii';image_folder_low = 'img-nii-1.5';
seg_folder_high = 'seg-nii';seg_folder_low = 'seg-nii-1.5';

cd([data_path,patient,'/',image_folder_high])
files = dir(['*.nii.gz']);
timeframes = [];
for i = 1: size(files,1)
    n = files(i).name;
    s = split(n,'.');
    timeframes = [timeframes str2num(s{1})+1];
end
timeframes = sort(timeframes);
cd(code_path)
clear s n

% parameters for movie making
load([code_path,'config_image.mat']);
save_movie_path = [save_path,'/Volume_Rendering_Movie_examples']; mkdir(save_movie_path);
view_angle = [0];
position = config_image.CameraPosition';
scale = [1,1,1];

%% Step 2: Load the data
load([save_path,'/',patient,'_rot_angle.mat'])
for i = 1:size(timeframes,2)
    t = timeframes(i);
    
    image_data = load_nii([data_path,patient,'/',image_folder_high,'/',num2str(t-1),'.nii.gz']);
    image = Transform_nii_to_dcm_coordinate(double(image_data.img),0);
    
    seg_data = load_nii([data_path,patient,'/',seg_folder_high,'/',num2str(t-1),'.nii.gz']);
    seg = Transform_nii_to_dcm_coordinate(double(seg_data.img),0);
    
    image_masked = Apply_Mask_To_Image(image,seg,[1]);
    
    min_value = min(image_masked(:));
    tic
    [~,M_z] = Rotation_Matrix_From_Three_Axis(0,0,-rot_angle.first_z,0);
    tform_z = affine3d(M_z);
    Irot = imwarp(image_masked,tform_z,'FillValue',min_value);
    disp(['finish first rot'])
    [~,M_x] = Rotation_Matrix_From_Three_Axis(-rot_angle.second_x,0,0,0);
    tform_x = affine3d(M_x);
    Irot = imwarp(Irot,tform_x,'FillValue',min_value);
    disp(['finish second rot'])
    [~,M_y] = Rotation_Matrix_From_Three_Axis(0,0,rot_angle.third_z,0);
    tform_y = affine3d(M_y');
    Irot = imwarp(Irot,tform_y,'FillValue',min_value);
    toc
    
    [box] = Bounding_box(Irot,20);
    Image_LV(t).box = box; 
    Image_LV(t).image = Irot(box(1):box(2),box(3):box(4),box(5):box(6));
    disp(['finish time frame ',num2str(t-1)]);
    clear image_masked Irot 
end
%% apply bounding box uniform to all time frames
box_list = [];
for i = 1:size(timeframes,2)
    t = timeframes(i);
    box_list = [box_list; Image_LV(t).box];
end
box = [max(box_list(:,1)),  min(box_list(:,2)), max(box_list(:,3)), min(box_list(:,4)), max(box_list(:,5)), min(box_list(:,6))]; 

for i = 1:size(timeframes,2)
    t = timeframes(i); II = Image_LV(t).image;
    box_t = Image_LV(t).box;
    Image_LV(t).image = II(1+box(1)-box_t(1):size(II,1)-(box_t(2)-box(2)),1+box(3)-box_t(3):size(II,2)-(box_t(4)-box(4)),1+box(5)-box_t(5):size(II,3)-(box_t(6)-box(6)));
    clear II t
end
save([save_path,'/',patient,'_rot_image.mat'],'Image_LV');
%% Step 2a: Dilation and threshold setting for LV mask (only if it's DL segmentation)
%% Step 3: set WL and WW
decrease = 100;
if isfile([save_path,'/',patient,'_thresholding.mat']) == 1
    load([save_path,'/',patient,'_thresholding.mat'])
else
WL = Set_WindowLevel_Based_on_CenterIntensityProfile(Data(1).image,Data(1).seg,5,decrease);
WW = 150;
save([save_path,'/',patient,'_thresholding.mat'],'WW','WL');
fid = fopen([save_path,'/',patient,'_thresholding.txt'],'wt');
fprintf(fid, [num2str(WL),'\n',num2str(WW)]);
fclose(fid);
end
%% Step 4: make Volume rendering movie
load([save_path,'/',patient,'_rot_image.mat'])

for i = 1:size(view_angle,2)
    angle = view_angle(:,i);

    save_name = [save_movie_path,'/',patient,'_volume_rendering_',num2str(angle)];
    writerObj = VideoWriter(save_name,'Motion JPEG AVI');
    writeObj.Quality = 100;
    writerObj.FrameRate = 5;
    
    % open the video writer
    open(writerObj);

    % write the frames to the video
    
    for t = timeframes
        disp(t)
        close all;
        I = Image_LV(t).image;
        J = Turn_data_into_greyscale(I,WL,WW);
        
        config_image_new = config_image;
        [rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,angle,1);
        new_position = rot_in_xy * position;
        config_image_new.CameraPosition = new_position';
        
        h = figure('pos',[10 10 500 500]);
        volshow(J,config_image_new,'ScaleFactor',scale); 
        frame = getframe(h);
        writeVideo(writerObj, getframe(gcf));
    end
   
    close(writerObj);
    close all
    disp(['Done making movie for degree ',num2str(angle)])
end
% Step 4b: Generate rotating LV movie
num_of_cardiac_cycle = 4;
angle_increment = 360/num_of_cardiac_cycle/size(timeframes,2);
angle = 0;
save_name = [save_movie_path,'/',patient,'_volume_rendering_rotating',];
writerObj = VideoWriter(save_name,'Motion JPEG AVI');
writerObj.Quality = 100;
writerObj.FrameRate = 5;
open(writerObj);
for i = 1:num_of_cardiac_cycle
    for t = timeframes
        disp([i,t])
        close all
        I = Image_LV(t).image;
        J = Turn_data_into_greyscale(I,WL,WW);
        
        config_image_new = config_image;
        [rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,angle,1);
        new_position = rot_in_xy * position;
        config_image_new.CameraPosition = new_position';
        
        h = figure('pos',[10 10 500 500]);
        volshow(J,config_image_new,'ScaleFactor',scale); 
        frame = getframe(h);
        writeVideo(writerObj, getframe(gcf));
        
        angle = angle + angle_increment;
    end
end
close(writerObj);
close all
disp(['Done making movie rotating'])
%% Step 5 (additional): save dicom image
dicom_path = [data_path,patient,'/img-dcm/'];
dicom_folders = Find_all_folders(dicom_path);
dicom_folder = [dicom_path,dicom_folders(1).name];
dicom_files = dir([dicom_folder,'/*.dcm']);
metadata = dicominfo([dicom_folder,'/',dicom_files(1).name]);metadata_new = metadata;
% save
dicom_save_main_folder = [save_path,'/img-dcm-segmented'];mkdir(dicom_save_main_folder);
series_num = 10;
for t = timeframes
    F = [dicom_save_main_folder,'/',num2str(t)];mkdir(F);
    metadata_new.SeriesNumber = series_num;
    metadata_new.SeriesDescription=['segmented_image_',num2str(t)];
    metadata_new.RescaleIntercept = 0;

    I = int16(Image_LV(t).image);
    I = flip(I,3);
    
    for z = 1:size(I,3)
        X=[F,'/',num2str(z),'.dcm'];
        metadata_new.SliceLocation = metadata.SliceLocation - metadata.SliceThickness * (z-1);
        metadata_new.ImagePositionPatient(3,:) = metadata_new.SliceLocation;
        metadata_new.InstanceNumber = z + size(I,3) * (t-1);
        %metadata_new.PixelSpacing(3,:) = metadata_new.SliceThickness;
        dicomwrite(I(:,:,z),X,metadata_new);
    end
    series_num = series_num + 10;
end
disp(['finish']);   