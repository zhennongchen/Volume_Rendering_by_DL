%% add path
clear all
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab';
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load')
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions')
%% load nii images and segmentation
% images
nii_file_name = '/Users/zhennongchen/Documents/Zhennong_VR/Data/028/img-nii-sm/0.nii.gz';
data = load_nii(nii_file_name);
nii_image = Transform_nii_to_dcm_coordinate(double(data.img),1);
window_level = 500;
window_width = 900;
slice_number = 40;
nii_image_slice = Turn_data_into_greyscale(nii_image(:,:,slice_number),window_level,window_width);
figure()
imshow(nii_image_slice);
truesize([300 300])
% segmentation
seg_file_name = '/Users/zhennongchen/Documents/Zhennong_VR/Data/028/seg-pred/H_test1_plan4_s_0.nii.gz';
seg = load_nii(seg_file_name);
nii_seg = zeros(size(seg.img));
nii_seg(seg.img==1) = 1;
nii_seg(seg.img==2) = 2;
nii_seg = Transform_nii_to_dcm_coordinate(nii_seg,1);
nii_seg_binary = nii_seg > 0;
figure()
imagesc(nii_seg(:,:,40));
figure()
imagesc(nii_seg_binary(:,:,40));
%% select the biggest connected component:
nii_seg_CC=bwconncomp(nii_seg_binary);
while(1 ==1)
    numPixels=cellfun(@numel,nii_seg_CC.PixelIdxList);
    if size(numPixels,2) > 1
        [lowest,idx]=min(numPixels);
        nii_seg_binary(nii_seg_CC.PixelIdxList{idx})=0;
        nii_seg_CC=bwconncomp(nii_seg_binary);
    else
        break
    end
end
%% convex hull via regionprop3
convex = regionprops3(nii_seg_binary,'Centroid','BoundingBox','ConvexHull','ConvexImage','ConvexVolume');
box = convex.BoundingBox;
hull = convex.ConvexHull{1};
convex_I = convex.ConvexImage{1};
% view convex in 2D
point_list = List_All_Points_In_Image(size(convex_I));
point_list_raw = Convert_From_Bounding_Box_To_Raw_Image(point_list,box);
seg_convex_2D_view = zeros(size(nii_seg_binary));
for p = 1:size(point_list,1)
        i = point_list(p,1); j = point_list(p,2); k =point_list(p,3);
        ii = point_list_raw(p,1); jj = point_list_raw(p,2);kk= point_list_raw(p,3);
        % before = 0, after = 0 -> 0
        % before = 1, after = 1 -> 1
        % before = 0, after = 1 -> 2
        % before = 1, after = 0 -> error
        if nii_seg_binary(ii,jj,kk) == 0 && convex_I(i,j,k) == 0 
            seg_convex_2D_view(ii,jj,kk) = 0;
        elseif nii_seg_binary(ii,jj,kk)== 1 && convex_I(i,j,k) == 1
            seg_convex_2D_view(ii,jj,kk) = 1;
        elseif nii_seg_binary(ii,jj,kk)== 0 && convex_I(i,j,k) == 1
            seg_convex_2D_view(ii,jj,kk) = 2;
        elseif nii_seg_binary(ii,jj,kk)== 1 && convex_I(i,j,k) == 0
            error('the original labeled pixel is unlabeled')
        end
end
%% view 2D
slice = [40];
for i = slice
    figure(1)
    imagesc(nii_seg_binary(:,:,i))
    figure(2)
    imagesc(seg_convex_2D_view(:,:,i));
end
%% use segmentation as a mask
[seg_x,seg_y,seg_z] = ind2sub(size(nii_seg_binary),find(nii_seg_binary > 0));
new_image = zeros(size(nii_image)) - 1024;
for i = 1 : size(seg_x,1)
    new_image(seg_x(i),seg_y(i),seg_z(i)) = nii_image(seg_x(i),seg_y(i),seg_z(i));
end
%% visualize segmentation in three dimension
% open volume viewer in apps
volshow(seg_convex_2D_view,config6)
axis vis3d
for i = 1:36
   camorbit(10,0,'data',[0 1 0])
   drawnow
end