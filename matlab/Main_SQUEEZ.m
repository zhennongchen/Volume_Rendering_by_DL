%% Preparation: Data Organization
clear all; close all; clc;
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/';
addpath(genpath(code_path));

%% Find patient list
patient_list = Find_all_folders('/Volumes/Seagate MacOS/Patient_list/RSNA/Normal/');
class_list = []; id_list = [];
for i = 1:size(patient_list,1)
    class = split(patient_list(i).folder,'/');
    class = class(end); class = class{1};
    class_list = [class_list;convertCharsToStrings(class)];
    id_list = [id_list;convertCharsToStrings(patient_list(i).name)];
end
patient_list = Find_all_folders('/Volumes/Seagate MacOS/Patient_list/RSNA/Abnormal/');
for i = 1:size(patient_list,1)
    class = split(patient_list(i).folder,'/');
    class = class(end); class = class{1};
    class_list = [class_list;convertCharsToStrings(class)];
    id_list = [id_list;convertCharsToStrings(patient_list(i).name)];
end
%%
for num =1:size(id_list,1)
    clear info Data Mesh
    
    info.main_path = '/Volumes/Seagate MacOS';
    info.patient_class = convertStringsToChars(class_list(num,:));
    info.patient = convertStringsToChars(id_list(num));
    disp(info.patient)
    rot_angle_file = [info.main_path,'/SQUEEZ_results/',info.patient_class,'/',info.patient,'/rot_angle_2mm.mat'];
    if isfile(rot_angle_file) == 0
        error('No pre-defined rotation angle, end the process');
    end
    load(rot_angle_file,'rot')
    
    % Paths
    info.save_path = [info.main_path,'/SQUEEZ_results/',info.patient_class,'/',info.patient,'/'];
    mkdir(info.save_path)
    info.save_num_path = [info.save_path,'results/'];
    mkdir(info.save_num_path)
    info.save_image_path =[info.save_path,'plots/']; 
    mkdir(info.save_image_path)
    info.save_movie_path =[info.save_path,'movies/']; 
    mkdir(info.save_movie_path)
    
    if isfile([info.save_num_path,'SQUEEZ_data.mat']) == 1
        disp('already done')
        continue
    end
    
    % load the segmentation
    seg_folder = [info.main_path,'/predicted_seg/',info.patient_class,'/',info.patient,'/seg-pred-0.625-4classes-connected-retouch-downsample'];
    if isfolder(seg_folder) == 0
        error('No downsampled segmentation, end the process');
    end
    seg_files = Sort_time_frame(Find_all_files(seg_folder),'_');
    count = 1;
    for i = 1:size(seg_files,1)
        seg_data = load_nii([seg_folder,'/',convertStringsToChars(seg_files(i))]);
        Data(count).image_hdr = seg_data.hdr;
        seg = Transform_nii_to_dcm_coordinate(double(seg_data.img),0);
        [Data(count).seg_rot] = Rotate_Volume_by_Rotation_Angles(seg,rot,0,3);
        count = count +1 ;
    end
    
    
    %%%%%%%%%% Define parameters%%%%%%%%%%%%%%
    info.matlab = 0;    % 1 - if you have R2018b and later, else 0 (Not yet developed: DON'T USE!!!)

    % whether the Data already has rotated image and seg
    info.already_rotated = 1;           %the Data already have rotated image and seg

    % Image preparation parmeters
    info.pixel_size = Data(1).image_hdr.dime.pixdim(2:4);
    if length(unique(round(info.pixel_size,1))) == 1
        info.iso_res = info.pixel_size(1);%Standardized starting resolution in mm
        info.desired_res = info.iso_res;
    else
        info.iso_res = 0.5; info.desired_res = 2;
    end
    info.averaging_threshold = 0.5;     %Threshold for voxels post averaging
    info.fill_paps = 0;                 %Flag for filling in pap muscles using 3D convex hull: Need MATLAB 2017b or above


    % Segmentation labels
    info.lv_label = 1;
    info.la_label = 2;
    info.lvot_label = 4;

    % Time frame list
    info.timeframes = linspace(1,size(Data,2),size(Data,2));           %Desired time frames for analysis
    info.template = 1;                  %Used as template mesh for CPD warping
    info.reference = 1 ;                 %Used as reference phase for strain calculations

    % volume curve parameter list
    info.percent_rr = round(linspace(0,100,size(Data,2)));
    info.time_ms = round(linspace(0,740,size(Data,2))); %0043,101e in the metadata

    full_cycle = 1; % whether have full cardiac cycle
    if full_cycle == 1
        info.smooth_verts = 1; %Flag for temporally smoothing CPD vertices using Fourier decomposition. Use only when there is one complete period (1 full periodic cycle)
    else
        info.smooth_verts = 0;
    end

    info.resqueez = 0;                  %Flag for resqueez

    if info.smooth_verts == 1 && length(info.timeframes) <= 5
        error('Please check temporal smoothing flag for periodicity of entered time frames')
    % elseif info.smooth_verts == 0 && length(info.timeframes) >= 5
    %     error('Temporal smoothing switched off')
    end    
    
    % Axes limits for plotting
    %When plotting just use 'xlim([info.xlim]); ylim([info.ylim]); zlim([info.zlim])' for non-rotated LV
    %When plotting just use 'xlim([info.rot_xlim]); ylim([info.rot_ylim]); %zlim([info.rot_zlim])' for rotated LV
    %When plotting just use 'xlim([info.high_xlim]); ylim([info.high_ylim]); %zlim([info.high_zlim])' for Hi-Res rotated LV

    disp('xxxxxxxxx - Analysis Parameters Saved - xxxxxxxxx')


    %%%%%%%%%% Step 1:Image Processing and Mesh Extraction %%%%%%%%%%

    [Mesh,info] = Mesh_Extraction_modified(info,Data);
    %save([info.save_num_path,'step1_MeshExtraction.mat'],'Mesh','info')
    disp('xxxxxxxxx - Meshes Extracted - xxxxxxxxx')
    
    %%%%%%%%%% Step 1b: Volume Curves %%%%%%%%%%
    close all;

    EF = round(((info.vol(info.reference)-min(info.vol(info.timeframes)))/info.vol(info.reference))*100,1);
    save([info.save_num_path,'EF.mat'],'EF')

    figV = figure(1); plot(info.percent_rr,info.vol(info.timeframes),'LineWidth',4);
    grid on; grid minor
    title(['Ejection Fraction: ' num2str(EF),'%'])
    set(gca,'FontSize',50)
    axis([-10 110 0 max(info.vol)+50])
    xlabel('R-R interval (%)'); ylabel('Volume (mL)')

    figV.Units='normalized';
    figV.Position=[0 0 0.8 1]; 
    figV.PaperPositionMode='auto';

    savefig([info.save_image_path,info.patient,'_VolvsRRper.fig'])
    close all
    figs = openfig([info.save_image_path,info.patient,'_VolvsRRper.fig']);
    saveas(figs,[info.save_image_path,info.patient,'_VolvsRRper.jpg']);
    close all;

    %%%%%%%%%% Step 2: Registration - SQUEEZ %%%%%%%%%%

    % CPD Parameters
    opts.corresp = 1;
    opts.normalize = 1;
    opts.max_it = 1500;
    opts.tol = 1e-5;
    opts.viz = 0;
    opts.method = 'nonrigid_lowrank';
    opts.fgt = 0;
    opts.eigfgt = 0;
    opts.numeig = 100;
    opts.outliers = 0.05;
    opts.beta = 2;
    opts.lambda = 3;

    Mesh = Registration(Mesh,info,opts);
    % Mesh(info.timeframes(j)).CPD always has the dimension as (N of vertices in template,3) 
    % it shows that each vertex in Y (template) correspond to which vertex
    % (expressed by coordinate) in X (time frame)
    % Mesh(info.timeframes(j)).Correspondance shows the same thing but just
    % express by indexes.

    %save([info.save_num_path,'step2_SQUEEZRegistration.mat'],'Mesh','info')
    disp('xxxxxxxxx - Registration done - xxxxxxxxx')
    clear opts
    close all

    %%%%%%%%%% Step 2b: reSQUEEZ %%%%%%%%%%

    if info.resqueez

        info.error_tol = 2/info.desired_res;        %Euclidean distance tolerance for reSQUEEZ in mm
        info.resqueez_beta = 1;                     %Beta value for CPD re-registration
        info.resqueez_lambda = 11;                  %Lambda value for CPD re-registration 
        info.area_tol = 100;                        %Minimum area of patches for re-registration in mm^2

        Mesh = reSQUEEZ(Mesh,info);

        save([info.save_path,info.patient,'_step2b_reSQUEEZ.mat'],'Mesh','info')

        disp('xxxxxxxxx - reSQUEEZ done - xxxxxxxxx')
    else
        disp('xxxxxxxxx - NO reSQUEEZ - xxxxxxxxx')
    end


   %%%%%%%%%% Step 3: Calculating RSct %%%%%%%%%%

    Mesh = RSCT(Mesh,info);
    % Mesh.RSct saves the regional strain for each face in template
    % Mesh.RSctvertices saves the RS for each vertex in template.

    %save([info.save_num_path,'step3_RSctCalculation.mat'],'Mesh','info')

    disp('xxxxxxxxx - Strain calculations done - xxxxxxxxx')

   %%%%%%%%%% Step 4: Mesh Rotation %%%%%%%%%%
    % can also run SQUEEZ functions/reSQUEEZ/Check_rotated_data to check the
    % orientation of Data.

    [Mesh, info] = Rotation_modified(Mesh,info,Data);

    %save([info.save_num_path,'step4_MeshRotation.mat'],'Mesh','info')

    disp('xxxxxxxxx - Meshes rotated - xxxxxxxxx')


   %%%%%%%%%% Step 5: Polar Sampling of RSct %%%%%%%%%%
    % Creating raw data set of "high resolution" sampling of RSct values as a function of theta and z
    % or in the other words, sample the volume by slices and get RSct for each
    % angle in each slice

    info.rawdata_slicethickness = 5/info.desired_res;           %Enter slice thickness for raw data sampling in mm. Has to be >2*info.desired_res

    info.apical_basal_threshold = [0.1 0.1];                    %Apical and basal percentage tolerance in that order

    if info.rawdata_slicethickness <= 2
        error('Slice thickness too small')
    else
        [Mesh, info] = Data_Sampling(Mesh,info);

        %save([info.save_num_path,'step5_PolarSamplingOfRSct.mat'],'Mesh','info')

        disp('xxxxxxxxx - Polar data sampled - xxxxxxxxx')
    end


    %%%%%%%%%% Step 6: AHA Plotting %%%%%%%%%%
    % Hard coded 16 AHA segments

    info.RSct_limits = [-0.5 0.1];
    info.err_limits = [-0.1 10];

    Mesh = AHA(Mesh,info);

    %save([info.save_num_path,'step6_AHA.mat'],'Mesh','info')

    disp('xxxxxxxxx - AHA plots generated - xxxxxxxxx')
    close all;

    %%%%%%%%%% Step 7: Bullseye Plotting %%%%%%%%%%

    info.polar_res = [36 10];                       %Enter desired number of points in bullseye plots in the format number [azimuthal radial]
    info.polar_NoOfCols = 5;                        %Number of columns in bullseye plot subplot
    info.RSct_limits = [-0.3 0.1];

    Mesh = Bullseye_Plots(Mesh,info);

    %save([info.save_num_path,'step7_bullseye.mat'],'Mesh','info')

    disp('xxxxxxxxx - Bullseye plots generated - xxxxxxxxx')

    savefig([info.save_image_path,info.patient,'_Bullseye.fig'])
    close all;
    figs = openfig([info.save_image_path,info.patient,'_Bullseye.fig']);
    saveas(figs,[info.save_image_path,info.patient,'_Bullseye.jpg']);
    close all;
    
    %%%%%%%%%% Step 8: 4D SQUEEZ %%%%%%%%%%

    [Mesh,info] = squeez_4D_movie_modified(Mesh,info);

    %save([info.save_num_path,'step8_4DSQUEEZ.mat'],'Mesh','info') 
    save([info.save_num_path,'SQUEEZ_data.mat'],'Mesh','info') 
    % only keep allviews movie
    movies = Find_all_files(info.save_movie_path);
    for i = 1: size(movies,1)
        a = ~('4DSqueez.mp4' == movies(i).name(length(movies(i).name)-11:length(movies(i).name)));
        if any(a) ~= 0
            delete([info.save_movie_path,movies(i).name])
        end
    end
    close all;
end

%% Make AHA plot with lower LVOT plane
for num = 6%105:size(id_list,1)
    clear info Data Mesh
    close all
    
    info.main_path = '/Volumes/Seagate MacOS/';
    info.patient_class = convertStringsToChars(class_list(num,:));
    info.patient = convertStringsToChars(id_list(num));
    disp(info.patient)
    rot_angle_file = [info.main_path,'/SQUEEZ_results/',info.patient_class,'/',info.patient,'/rot_angle_2mm.mat'];
    if isfile(rot_angle_file) == 0
        error('No pre-defined rotation angle, end the process');
    end
    load(rot_angle_file,'rot')
    
    
    info.save_path = [info.main_path,'/SQUEEZ_results/',info.patient_class,'/',info.patient,'/'];
    mkdir(info.save_path)
    info.save_num_path = [info.save_path,'/results/'];
    mkdir(info.save_num_path)
    
    if isfile([info.save_num_path,'SQUEEZ_data.mat']) == 1
        load([info.save_num_path,'SQUEEZ_data.mat'])
    else
        error('NO pre-calculated SQUEEZ');
    end
    
        
    % Paths
    info.save_path = [info.main_path,'/SQUEEZ_results/',info.patient_class,'/',info.patient,'/'];
    mkdir(info.save_path)
    info.save_num_path = [info.save_path,'/results/'];
    mkdir(info.save_num_path)
    info.save_image_path =[info.save_path,'/plots/']; 
    mkdir(info.save_image_path)
    info.save_movie_path =[info.save_path,'/movies/']; 
    mkdir(info.save_movie_path)
    
    % aha plot
    info.RSct_limits = [-0.5 0.1];
    info.err_limits = [-0.1 10];
    [Mesh,info] = AHA_modified(Mesh,info,1);
    
    % bullseye plot
    info.polar_res = [36 10];                       %Enter desired number of points in bullseye plots in the format number [azimuthal radial]
    info.polar_NoOfCols = 5;                        %Number of columns in bullseye plot subplot
    info.RSct_limits = [-0.3 0.1];
    
    close all;
    
    [Mesh,info] = Bullseye_Plots_modified(Mesh,info);
    savefig([info.save_image_path,info.patient,'_Bullseye.fig'])
    
    figs = openfig([info.save_image_path,info.patient,'_Bullseye.fig']);
    saveas(figs,[info.save_image_path,info.patient,'_Bullseye.jpg']);
    close all;
    
    save([info.save_num_path,'SQUEEZ_data2.mat'],'Mesh','info') 
end
