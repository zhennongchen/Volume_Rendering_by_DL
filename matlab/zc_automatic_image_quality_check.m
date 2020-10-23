%% add path
clear all;
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load');
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions');
%% Load the patient table
year = '2017';
filename = ['/Users/zhennongchen/Documents/Zhennong_CT_Data/Patient_Overview/',year,'_Patient_Radiology_Records_Function_no_report.csv'];

T = readtable(filename);
column_list = T.Properties.VariableNames;
%% load the patient image and measure
main_folder = ['/Volumes/McVeighLab/dicom_images/',year,'/'];

quality_check_list = struct([]);
for i = [5,1]
    patient_id = T.Patient_ID{i};
    disp([patient_id,' index = ',num2str(i)])
    
    if all(T.Dicom_{i}(1:2) == 'No') == 1
        disp(['no dicom image for this patient'])
        continue
    end
   
    
    function_folder = strsplit(T.Directories_Function{i},', ');
    if size(function_folder,2) ~= T.Timeframes(i)
        error('wrong split of function folders')
    end
    
    % pick one time frame starts from 3rd (avoid the folder with all
    % timeframes)
    tf = 3;
    tic
    while 1 == 1
        tf_folder = function_folder(tf); 
        tf_folder = Remove_prefix_suffix_in_string(tf_folder{1},[]);
        %
        dicom_files=dir([main_folder,patient_id,'/',tf_folder,'/','*.dcm']);
        if size(dicom_files,1) ~= 0
            disp(tf)
            break
        end
        if tf == T.Timeframes(i)
            disp('no dicom')
            break
        end
        tf = tf + 1;
    end
    toc
    
    % find the middle slice
    slice_num = round(size(dicom_files,1)/2);
    file_name = [main_folder,patient_id,'/',tf_folder,'/',dicom_files(slice_num).name];
    info=dicominfo(file_name);
    img = double(dicomread(file_name));
    img = info.RescaleSlope.*img + info.RescaleIntercept;
    
    % also get slice n-3 and n + 3
    file_name2 = [main_folder,patient_id,'/',tf_folder,'/',dicom_files(slice_num-3).name];
    img2 = double(dicomread(file_name2));
    img2 = info.RescaleSlope.*img2 + info.RescaleIntercept;
    
    file_name3 = [main_folder,patient_id,'/',tf_folder,'/',dicom_files(slice_num+3).name];
    img3 = double(dicomread(file_name3));
    img3 = info.RescaleSlope.*img3 + info.RescaleIntercept;
   
    % plot figure and make graphy input
    f1 = figure();
    imagesc(img); hold on
    axis equal;  colormap gray
    title('click one point in LV')
    [yp,xp] = ginput(1); 
    yp = round(yp); xp = round(xp);
    close(f1)
    
    % make a circular ROI 
    roi = [];
    for r1 = -30:30
        for r2 = -30:30
            if round(sqrt(sum(([xp+r1,yp+r2]-[xp,yp]).^2))) == 20
                roi = [roi;xp+r1,yp+r2];
            end
        end
    end
    
    % calculate the mean and std
    roi_index = sub2ind(size(img),roi(:,1),roi(:,2));
    I = [img(roi_index'), img2(roi_index'), img3(roi_index')];
    LV_mean = mean(I(:));
    LV_std = std(I(:));
    LV_snr = max(I(:))/LV_std;
    
    % plot ROI and click whether the quality is good
    figure(2)
    set(gcf,'Position',[100,100,900,900])
    subplot(2,2,1)
    imagesc(img); colormap gray;hold on
    plot(yp,xp,'marker','o','MarkerFaceColor','b','MarkerSize',5)
    hold on
    scatter(roi(:,2),roi(:,1),1,'r','filled')
    title(['mean: ',num2str(round(LV_mean)),' std: ',num2str(round(LV_std)),' SNR: ',num2str(LV_snr)],'FontSize',12)
    
    subplot(2,2,2)
    imagesc(img2); colormap gray;hold on
    plot(yp,xp,'marker','o','MarkerFaceColor','b','MarkerSize',5)
    hold on
    scatter(roi(:,2),roi(:,1),1,'r','filled')
    title(['slice n-'])
    
    subplot(2,2,3)
    imagesc(img3); colormap gray;hold on
    plot(yp,xp,'marker','o','MarkerFaceColor','b','MarkerSize',5)
    hold on
    scatter(roi(:,2),roi(:,1),1,'r','filled')
    title(['slice n+2'])
    
    % define image quality
    subplot(2,2,4)
    a = zeros(size(img));
    for w = (round(size(img,1))/2 - 120) : (round(size(img,1))/2 -20)
        for h = (round(size(img,2))/2 - 50) : (round(size(img,2))/2 + 50)
            a(w,h) = 1;
        end
    end
    for w = (round(size(img,1))/2 +20 ) : (round(size(img,1))/2 +120)
        for h = (round(size(img,2))/2 - 50) : (round(size(img,2))/2 + 50)
            a(w,h) = 2;
        end
    end
    imagesc(a)
    title(['click inside the upper box for suspicious quality,lower for bad'])
    [yp,xp] = ginput(1); 
    yp = round(yp); xp = round(xp);
    if a(xp,yp) == 1
        quality = 'suspicious';
    elseif a(xp,yp) == 2
        quality = 'bad';
    else
        quality = 'good';
    end
    
    % leave my notes:
    clear note
    note = input('Please leave the note: ','s');
    if isempty(note)
        note = '';
    end
    
    % put the results into list
    quality_check_list(i).patient_id = patient_id;
    quality_check_list(i).LV_mean = LV_mean;
    quality_check_list(i).LV_std = LV_std;
    quality_check_list(i).LV_SNR = LV_snr;
    quality_check_list(i).quality = quality;
    quality_check_list(i).note = note;
    
    pause(2)
    close all
    end

%%
reply = input('Do you want more? Y/N [Y]:','s');
       if isempty(reply)
          reply = 'Y';
       end
       

