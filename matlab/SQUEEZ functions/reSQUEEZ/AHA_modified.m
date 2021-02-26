function [Mesh,info] = AHA_modified(Mesh,info,save_image)

fig1 = figure('pos',[10 10 2400 1800]);
fig2 = figure('pos',[10 10 2400 1800]);

seg = [4 5 6 1 2 3 10 11 12 7 8 9 15 16 13 14]; % Order of AHA segments from 0 degrees

% interestingly, they name inferior as anterior
name = {'Basal Anterior','Basal Anteroseptal','Basal Inferoseptal','Basal Inferior','Basal Inferolateral','Basal Anterolateral',...
    'Mid Anterior','Mid Anteroseptal','Mid Inferoseptal','Mid Inferior','Mid Inferolateral','Mid Anterolateral',...
    'Apical Anterior','Apical Septal','Apical Inferior','Apical Lateral'};

for j = info.timeframes
    
    count = 1; % Counter for segments
    
    data = Mesh(j).Polar_Data;
    data_err = Mesh(j).Polar_Data_err;
    
    % to lower down the basal plane because AI cut LVOT plane higher than
    % human
    info.down(j) = round((numel(data) - info.lvot_limit(j) + 1) * 0.1) + 1;
%     if info.patient_class == 'Normal'
%         info.down(j) = round((numel(data) - info.lvot_limit(j) + 1) * 0.1) + 1;
%     else
%         info.down(j) = round((numel(data) - info.lvot_limit(j) + 1) * 0.1);
%         if info.down(j) < 1
%             info.down(j) = 1;
%         end
%     end
    
    info.lvot_limit_down(j) = info.lvot_limit(j) + info.down(j);

    %Defining basal, mid, and apical chunk lengths
    chunks = round((numel(data) - info.lvot_limit_down(j) + 1)/3);
    
    
    %Defining basal, mid, and apical slices
    list = {info.lvot_limit_down(j):info.lvot_limit_down(j) + chunks-1,
        info.lvot_limit_down(j) + chunks:info.lvot_limit_down(j) + 2*chunks - 1,
        info.lvot_limit_down(j) + 2*chunks:numel(data)};
    
    % Basal-1, mid-2, apex-3
    for j1 = 1:3
        
        angles = []; rsct = []; err = [];
        
        % Extracting all angles in the respective section slices and their corresponding strains
        for j2 = list{j1}

            angles = [angles, data{j2}(2,:)];
            rsct = [rsct, data{j2}(1,:)];
            err = [err, data_err{j2}(1,:)];
            
        end
        
        if j1 == 1 || j1 ==2
            
            % rotating aha 16 segment plot by 30 for easy extraction of values, making segments 4 and 10 start at 6 o'clock instead of 7 o'clock
            angles = angles + pi/6;
            angles(angles>=2*pi) = angles(angles>=2*pi) - 2*pi;
            
            c = 1; dummy = 0;
            while dummy < 2*pi
                aha(seg(count)) = nanmean(rsct(angles >= dummy & angles < c*(pi/3)));
                aha_err(seg(count)) = nanmean(err(angles >= dummy & angles < c*(pi/3)));
                dummy = c*(pi/3);
                c = c + 1;
                count = count + 1;
            end
            
        else
            
            % rotating aha 16 segment plot by 45 for easy extraction of values, making segment 15 start at 6 o'clock instead of 7:30 o'clock
            angles = angles + pi/4;
            angles(angles>=2*pi) = angles(angles>=2*pi) - 2*pi;
            
            c = 1; dummy = 0;
            while dummy < 2*pi
                aha(seg(count)) = nanmean(rsct(angles >= dummy & angles < c*(pi/2)));
                aha_err(seg(count)) = nanmean(err(angles >= dummy & angles < c*(pi/2)));
                dummy = c*(pi/2);
                c = c + 1;
                count = count + 1;
            end
            
        end
        
    end
    
    Mesh(j).AHA = aha;
    Mesh(j).AHA_err = aha_err;
    
    clear chunks list aha aha_err
end

% plot
for j3 = 1:16
    
    for j = 1:length(info.timeframes)
        
        aha(j) = Mesh(info.timeframes(j)).AHA(j3);
        
    end

    figure(fig1)
    subplot(3,6,j3);
    plot(info.percent_rr,aha,'LineWidth',3);
    ax = gca; ax.FontSize = 10; ax.FontWeight= 'bold';
    ylim([info.RSct_limits]); xlim([0 100])
    yticks([-1:0.1:1]); xticks(0:20:100)
    ylabel('RS_{CT}','FontSize',12); xlabel('%R-R Phase','FontSize',12)
    title([num2str(j3),'. ',name{j3}],'FontSize',15)
    grid on; grid minor
    
    figure(fig2)
    subplot(3,6,j3);
    plot(info.time_ms,aha,'LineWidth',3);
    ax = gca; ax.FontSize = 10; ax.FontWeight= 'bold';
    ylim([info.RSct_limits]); xlim([0 1200])
    yticks([-1:0.1:1]); xticks(0:500:1500)
    ylabel('RS_{CT}','FontSize',12); xlabel('Time (ms)','FontSize',12)
    title([num2str(j3),'. ',name{j3}],'FontSize',15)
    grid on; grid minor
        
end
if save_image == 1
    s_path = info.save_image_path;
    saveas(fig1,[s_path,info.patient,'_AHA.fig'])
    saveas(fig1,[s_path,info.patient,'_AHA'],'jpg')
    saveas(fig2,[s_path,info.patient,'_AHA_ms.fig'])
    saveas(fig2,[s_path,info.patient,'_AHA_ms'],'jpg')
end

