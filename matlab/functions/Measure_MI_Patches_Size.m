function [final_I,I_colored,MI_sizes] = Measure_MI_Patches_Size(I_MI,I_LV,rows_of_MV,dilate_size,image_show)
% make sure I_mi and I_lv are binary with object = 1

I_MI_remove = I_MI;
count = 0; top_lines = [];
for i = 1: size(I_LV,1)
    row = I_LV(i,:);
    if size(find(row == 1),2) > 3
        top_lines = [top_lines,i];
        I_MI_remove(i,:) = zeros(size(I_MI_remove(i,:)));
        count = count + 1;
        if count == rows_of_MV
            break
        end
    end
end

I_dilate = imdilate(I_MI_remove,ones(dilate_size,dilate_size));
[I_colored,MI_sizes] = Assign_Color_To_Different_Connectivities(I_dilate);


final_I = I_dilate;


lim = size(final_I,2);
if image_show == 1
    subplot(1,3,1)
    imagesc(I_MI);
    xlim([0 lim]);ylim([0,lim]);
    axis equal
    
    subplot(1,3,2)
    imagesc(I_MI_remove);
    xlim([0 lim]);ylim([0,lim]);
    axis equal
    
    subplot(1,3,3)
    imagesc(I_colored);
    xlim([0 lim]);ylim([0,lim]);
    axis equal
end