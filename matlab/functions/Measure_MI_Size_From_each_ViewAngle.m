function [MI_measures] = Measure_MI_Size_From_each_ViewAngle(view_angle,seg_rot,config_label_LV,seg_MI,config_label_MI,config_label_multi,image_save_path,patient,rows_of_MV,dilate_size)

% this function measures MI sizes from each view angle. rows_of_MV,
% dilate_size are inputs for function
% Measure_MI_Patches_Size.m
scale = [2,2,2];
position = config_label_LV.CameraPosition';

for i = 1:size(view_angle,2)
    angle = view_angle(:,i);
    [rot_in_xy,~] = Rotation_Matrix_From_Three_Axis(0,0,angle,1);
    new_position = rot_in_xy * position;
    config_label_LV.CameraPosition = new_position';
    config_label_MI.CameraPosition = new_position';
    config_label_multi.CameraPosition = new_position';
    
    h = figure('pos',[10 10 100 100]);
    labelvolshow(seg_MI,config_label_MI,'ScaleFactor',scale);
    saveas(gcf,[image_save_path,'/',patient,'_label_MI_',num2str(angle),'.png']);
    close all

    h2 = figure('pos',[10 10 100 100]);
    labelvolshow(seg_rot,config_label_LV,'ScaleFactor',scale);
    saveas(gcf,[image_save_path,'/',patient,'_label_LV_',num2str(angle),'.png']);
    close all
    
    h3 = figure('pos',[10 10 100 100]);
    labelvolshow(seg_MI,config_label_multi,'ScaleFactor',scale);
    saveas(gcf,[image_save_path,'/',patient,'_label_multi_',num2str(angle),'.png']);
    close all
    
    Image_MI = imread([image_save_path,'/',patient,'_label_MI_',num2str(angle),'.png']);
    disp(size(Image_MI));
    [Image_MI_bw,num_MI] = Count_Non_White_Pixel(Image_MI,1);
    Image_MI_bw = ~Image_MI_bw;
    
    Image_LV = imread([image_save_path,'/',patient,'_label_LV_',num2str(angle),'.png']);
    [Image_LV_bw,num_LV] = Count_Non_White_Pixel(Image_LV,1);
    Image_LV_bw = ~Find_Biggest_Component(Image_LV_bw,1);
    percentage_MI = num_MI / num_LV;
    
    [Image_MI_processed,Image_MI_colored,MI_sizes] = Measure_MI_Patches_Size(Image_MI_bw,Image_LV_bw,rows_of_MV,dilate_size,0);
    
    % save data
    MI_measures(i).angle = angle;
    MI_measures(i).num_LV = num_LV;
    MI_measures(i).num_MI = num_MI;
    MI_measures(i).percentage_MI = percentage_MI;
    MI_measures(i).MI_sizes = MI_sizes;
    h3 = figure('pos',[10 10 100 100]);
    imagesc(Image_MI_colored)
    saveas(gcf,[image_save_path,'/',patient,'_label_MI_colored_',num2str(angle),'.png']);
    close all
    

end
    
    
    

