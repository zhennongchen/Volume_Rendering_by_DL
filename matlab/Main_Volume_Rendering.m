%% 
% this script automatically makes the volume rendering movie.]
%% add path
clear all;
addpath(genpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/'));
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/';
main_path = '/Volumes/Seagate MacOS/';

%% Define patient list
patient_list = Find_all_folders('/Volumes/Seagate MacOS/Patient_list/Retouched_Seg_Done/Normal/');
class_list = []; id_list = [];
for i = 1:size(patient_list,1)
    class = split(patient_list(i).folder,'/');
    class = class(end); class = class{1};
    class_list = [class_list;convertCharsToStrings(class)];
    id_list = [id_list;convertCharsToStrings(patient_list(i).name)];
end
patient_list = Find_all_folders('/Volumes/Seagate MacOS/Patient_list/Retouched_Seg_Done/Abnormal/');
for i = 1:size(patient_list,1)
    class = split(patient_list(i).folder,'/');
    class = class(end); class = class{1};
    class_list = [class_list;convertCharsToStrings(class)];
    id_list = [id_list;convertCharsToStrings(patient_list(i).name)];
end
%% Step 1: Load case
for num = 20%1:size(class_list,1)
    clear Image Image_LV Seg angle_list angle_increment I J image_files seg_files seg_raw WL WW
    patient_class = convertStringsToChars(class_list(num,:));
    patient_id = convertStringsToChars(id_list(num));
    disp(patient_class)
    disp(patient_id)
    
    
    save_folder = [main_path,'Volume_Rendering_Movies_MATLAB/',patient_class,'/',patient_id];
    mkdir(save_folder)
    
    if isfile([save_folder,'/',patient_id,'_volume_rendering_movie_all_angles.avi']) == 1
        if isfile([save_folder,'/',patient_id,'_volume_rendering_movie_all_angles.mp4']) == 1
            disp(['already done'])
            %continue
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % load rotated segmentation & image(non-masked)
    seg_folder = [main_path,'mat_data/',patient_class,'/',patient_id,'/seg_rotate_box/'];
    if isfolder(seg_folder) == 0
        error('No rotated segmentation, end the process');
    end
    seg_files = Sort_time_frame(Find_all_files(seg_folder),'_');
    img_folder = [main_path,'mat_data/',patient_class,'/',patient_id,'/image_rotate_box/'];
    if isfolder(img_folder) == 0
        error('No rotated image, end the process');
    end
    img_files = Sort_time_frame(Find_all_files(img_folder),'_');
    
    if size(seg_files,1) ~= size(img_files,1)
        error('The number of segmentations is not equal to that of images, end the process')
    end
    
    for t = 1:size(seg_files,1)
        load([seg_folder,convertStringsToChars(seg_files(t))]);
        Seg(t).seg = seg;
        load([img_folder,convertStringsToChars(img_files(t))]);
        Image(t).img = image;
        clear seg image   
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % apply a bounding box
    bounding_box = 1;
    buff = [20,20,20,20,30,30];
    if bounding_box == 1
        [box] = Bounding_box_new(Seg(1).seg,'LV',buff);
        for tt = 1:size(Image,2)
            a = Image(tt).img; 
            Image(tt).img = a(box(1):box(2),box(3):box(4),box(5):box(6));
            b = Seg(tt).seg;
            Seg(tt).seg = b(box(1):box(2),box(3):box(4),box(5):box(6));
        end     
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Undeveloped:add top layer removal feature here
    % Undeveloped: Dilation and threshold setting for LV mask (only if it's DL segmentation)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % make rendered volume
    % find camera position for each 
    Render_Volume_save_folder = [save_folder,'/Rendered_Volume'];
    mkdir(Render_Volume_save_folder)
    angle_list = [0:60:300];
    load([code_path,'configuration_list/config_default.mat']);
    position = config_default.CameraPosition';
   
    for i = 1:size(angle_list,2)
        if isfile([Render_Volume_save_folder,'/',patient_id,'_rendered_volume_',num2str(angle_list(i)),'.png']) == 1
            disp(['already done rendered volume',num2str(angle_list(i))]);
            continue
        end
        [rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,angle_list(i),1);
        new_position = rot_in_xy * position;
        config_default.CameraPosition = new_position';
        h = figure('pos',[10 10 500 500]);
        volshow(Seg(1).seg > 0,config_default,'ScaleFactor',[1,1,1]); 
        saveas(gcf,[Render_Volume_save_folder,'/',patient_id,'_rendered_volume_',num2str(angle_list(i)),'.png']);
        close all
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set WL and WW for rendering
    decrease = 100;
    if isfile([save_folder,'/thresholding.mat']) == 1
        load([save_folder,'/thresholding.mat'])
    else
    WL = Set_WindowLevel_Based_on_CenterIntensityProfile(Image(1).img,Seg(1).seg,15,decrease);
    WW = 150;
    save([save_folder,'/thresholding.mat'],'WW','WL');
    end
    fid = fopen([save_folder,'/thresholding.txt'],'wt');
    fprintf(fid, [num2str(WL),'\n',num2str(WW)]);
    fclose(fid);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % apply segmentation mask to the image
    for t = 1:size(Image,2)
        % mask for LV only
         I = Image(t).img;
         min_val = min(I(:));
         I(Seg(t).seg ~= 1)= min_val; 
         Image_LV(t).img = I;
         
         % mask for LV + LVOT
         II = Image(t).img;
         min_val = min(II(:));
         II(Seg(t).seg ~= 1 & Seg(t).seg ~= 4)= min_val; 
         Image_LV_LVOT(t).img = II;
         clear I II
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%% AVI movie (without LVOT) %%%%%%%%%%%%%%%%%%%%%%%%%
    % make volume rendering movies 
    load([code_path,'configuration_list/config_image.mat']);
    position = config_image.CameraPosition';
    movie_save_folder = [save_folder,'/Volume_Rendering_Movies'];
    mkdir(movie_save_folder);
    
    angle_list = [0:60:300];
    scale = [1.5,1.5,1.5];
    figure_size = [10 10 300 300];
    
    for i = 1:size(angle_list,2)
        angle = angle_list(:,i);

        save_name = [movie_save_folder,'/',patient_id,'_volume_rendering_movie_',num2str(angle)];
        if isfile([save_name,'.avi']) == 1
            disp(['already done avi movie for angle ',num2str(angle)])
            %continue
        end
        
        writerObj = VideoWriter(save_name,'Motion JPEG AVI');
        writeObj.Quality = 100;
        writerObj.FrameRate = 5;
    
        % open the video writer
        open(writerObj);

        % write the frames to the video
        for t = 1:size(Image,2)
            close all;
            I = Image_LV(t).img;
            J = Turn_data_into_greyscale(I,WL,WW); % apply WL and Ww
        
            config_image_new = config_image;
            [rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,angle,1);
            new_position = rot_in_xy * position;
            config_image_new.CameraPosition = new_position';
        
            h = figure('pos',figure_size);
            volshow(J,config_image_new,'ScaleFactor',scale); 
            frame = getframe(h);
            writeVideo(writerObj, getframe(gcf));
            close all
        end
   
        close(writerObj);
        close all
        disp(['Done making AVI smovie for degree ',num2str(angle)])
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Generate rotating LV movie as well (two heartbeats for each angle)
%     %num_of_cardiac_cycle = 3;
%     %angle_increment = 360/num_of_cardiac_cycle/size(Image,2);
%     %angle = 0;
%     
%     if isfile([save_folder,'/',patient_id,'_volume_rendering_movie_all_angles.avi']) == 1
%         disp(['already done avi movie for all_angles'])
%     else
%     
%     save_name = [save_folder,'/',patient_id,'_volume_rendering_movie_all_angles'];
%     writerObj = VideoWriter(save_name,'Motion JPEG AVI');
%     writerObj.Quality = 100;
%     writerObj.FrameRate = 5;
%     open(writerObj);
%    
%         
%     for i = 1:size(angle_list,2)
%         angle = angle_list(i);
%         for cycle = 1:2
%          for t = 1:size(Image,2)
%             close all
%             I = Image_LV(t).img;
%             J = Turn_data_into_greyscale(I,WL,WW);
%         
%             config_image_new = config_image;
%             [rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,angle,1);
%             new_position = rot_in_xy * position;
%             config_image_new.CameraPosition = new_position';
%         
%             h = figure('pos',figure_size);
%             volshow(J,config_image_new,'ScaleFactor',scale); 
%             frame = getframe(h);
%             writeVideo(writerObj, getframe(gcf));
%             close all
%             %angle = angle + angle_increment;
%          end
%         end
%     end
%     close(writerObj);
%     close all
%     disp(['Done making AVI movie for all_angles '])
%     end
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     
%     
%     %%%%%%%%%%%%%%%%%%% MP4 MOVIE (WITH LVOT)%%%%%%%%%%%%%%%
%     movie_save_folder_mp4 = [save_folder,'/Volume_Rendering_Movies_MP4'];
%     mkdir(movie_save_folder_mp4);
%     
%     for i = 1:size(angle_list,2)
%         angle = angle_list(:,i);
% 
%         save_name = [movie_save_folder_mp4,'/',patient_id,'_volume_rendering_movie_',num2str(angle)];
%         if isfile([save_name,'.mp4']) == 1
%             disp(['already done MP4 movie for angle ',num2str(angle)])
%             continue
%         end
%         
%         writerObj = VideoWriter(save_name,'MPEG-4');
%         writeObj.Quality = 100;
%         writerObj.FrameRate = 5;
%     
%         % open the video writer
%         open(writerObj);
% 
%         % write the frames to the video
%         for t = 1:size(Image,2)
%             %disp(t)
%             close all;
%             I = Image_LV_LVOT(t).img;
%             J = Turn_data_into_greyscale(I,WL,WW); % apply WL and Ww
%         
%             config_image_new = config_image;
%             [rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,angle,1);
%             new_position = rot_in_xy * position;
%             config_image_new.CameraPosition = new_position';
%         
%             h = figure('pos',figure_size);
%             volshow(J,config_image_new,'ScaleFactor',scale); 
%             frame = getframe(h);
%             writeVideo(writerObj, getframe(gcf));
%             close all
%         end
%    
%         close(writerObj);
%         close all
%         disp(['Done making MP4 movie for degree ',num2str(angle)])
%     end
%     
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Generate rotating LV movie as well (two heartbeats for each angle)
%     if isfile([save_folder,'/',patient_id,'_volume_rendering_movie_all_angles.mp4']) == 1
%         disp(['already done MP4 movie for all_angles'])
%     else
%     
%     save_name = [save_folder,'/',patient_id,'_volume_rendering_movie_all_angles'];
%     writerObj = VideoWriter(save_name,'MPEG-4');
%     writerObj.Quality = 100;
%     writerObj.FrameRate = 5;
%     open(writerObj);
%     
%     for i = 1:size(angle_list,2)
% 
%         angle = angle_list(i);
%         for cycle = 1:2
%          for t = 1:size(Image,2)
%             %disp([angle,t])
%             close all
%             I = Image_LV_LVOT(t).img;
%             J = Turn_data_into_greyscale(I,WL,WW);
%         
%             config_image_new = config_image;
%             [rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,angle,1);
%             new_position = rot_in_xy * position;
%             config_image_new.CameraPosition = new_position';
%         
%             h = figure('pos',figure_size);
%             volshow(J,config_image_new,'ScaleFactor',scale); 
%             frame = getframe(h);
%             writeVideo(writerObj, getframe(gcf));
%             close all
%             
%          end
%         end
%     end
%     close(writerObj);
%     close all
%     disp(['Done making MP4 movie for all_angles '])
%     end

end
    
    
    
    
    
    
%% 
   
% %% Step 5 (additional): save dicom image
% dicom_path = [data_path,patient,'/img-dcm/'];
% dicom_folders = Find_all_folders(dicom_path);
% dicom_folder = [dicom_path,dicom_folders(1).name];
% dicom_files = dir([dicom_folder,'/*.dcm']);
% metadata = dicominfo([dicom_folder,'/',dicom_files(1).name]);metadata_new = metadata;
% % save
% dicom_save_main_folder = [save_path,'/img-dcm-segmented'];mkdir(dicom_save_main_folder);
% series_num = 10;
% for t = timeframes
%     F = [dicom_save_main_folder,'/',num2str(t)];mkdir(F);
%     metadata_new.SeriesNumber = series_num;
%     metadata_new.SeriesDescription=['segmented_image_',num2str(t)];
%     metadata_new.RescaleIntercept = 0;
% 
%     I = int16(Image_LV(t).image);
%     I = flip(I,3);
%     
%     for z = 1:size(I,3)
%         X=[F,'/',num2str(z),'.dcm'];
%         metadata_new.SliceLocation = metadata.SliceLocation - metadata.SliceThickness * (z-1);
%         metadata_new.ImagePositionPatient(3,:) = metadata_new.SliceLocation;
%         metadata_new.InstanceNumber = z + size(I,3) * (t-1);
%         %metadata_new.PixelSpacing(3,:) = metadata_new.SliceThickness;
%         dicomwrite(I(:,:,z),X,metadata_new);
%     end
%     series_num = series_num + 10;
% end
% disp(['finish']);   