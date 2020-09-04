function [seg_MI,seg] = Localize_MI(seg_rot,Mesh,threshold,edes,slice_show)

% this script assign a different pixel value to the binary segmentation of
% LV

 
rs_list = Mesh(edes(2)).RSct_vertex';
v_list = Mesh(edes(1)).vertices;
low_strain_idx = find(rs_list > threshold);
low_strain_p = v_list(low_strain_idx,:,:);

% pixel value assignment
seg = double(seg_rot == 1);
seg_MI = seg;
for i = 1: size(low_strain_p,1)
    p = low_strain_p(i,:);
    seg_MI(p(2),p(1),p(3)) = 9; % background = 0, LV = 1, infarct = 9
end

if slice_show ~= 0
    figure()
    imagesc(seg(:,:,slice_show));
    figure()
    imagesc(seg_MI(:,:,slice_show));
end
