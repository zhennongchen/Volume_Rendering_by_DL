%% add path
clear all
code_path = '/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab';
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/nii_image_load')
addpath('/Users/zhennongchen/Documents/GitHub/Volume_Rendering_by_DL/matlab/functions')
%% 2D trial
imageSizeX = 20;
imageSizeY = 20;
[columnsInImage rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);
% Next create our image
center = [12,10];
centerX = center(1);
centerY = center(2);
radius = 5.5;

r = (rowsInImage - centerY).^2 ...
    + (columnsInImage - centerX).^2 <= radius.^2;

for i = 1:imageSizeX
    for j = 1:imageSizeY
        if i > 12 && j <14
            r(i,j) = 0;
        end
    end
end

r(12,10) = 0; r(11,10)=0; r(10,10)=0; r(12,9)=0; r(11,9) = 0;

% Now, display it.
figure()
imagesc(r) ;
xlabel('y')
ylabel('x')
%% convex hull by regionprops 2D
convex = regionprops(r,'Centroid','BoundingBox','ConvexHull','ConvexImage','ConvexArea');
box = convex.BoundingBox;
hull = convex.ConvexHull;
convex_i = convex.ConvexImage;
area = convex.ConvexArea;
centroid = convex.Centroid;
% plot
figure();
imagesc(convex_i);
%%
new_r = zeros(size(r));
point_list = List_All_Points_In_Image(size(convex_i));
point_list_raw = Convert_From_Bounding_Box_To_Raw_Image(point_list,box);
for p = 1:size(point_list,1)

        i = point_list(p,1); j = point_list(p,2);
        ii = point_list_raw(p,1); jj = point_list_raw(p,2);
        % before = 0, after = 0 -> 0
        % before = 1, after = 1 -> 1
        % before = 0, after = 1 -> 2
        % before = 1, after = 0 -> 3
        if r(ii,jj) == 0 && convex_i(i,j) == 0 
            new_r(ii,jj) = 0;
        elseif r(ii,jj)== 1 && convex_i(i,j) == 1
            new_r(ii,jj) = 1;
        elseif r(ii,jj)== 0 && convex_i(i,j) == 1
            new_r(ii,jj) = 2;
        elseif r(ii,jj)== 1 && convex_i(i,j) == 0
            new_r(ii,jj) = 3;
        end
end
figure()
imagesc(new_r)
%%
r3(:,:,1) = r; r3(:,:,2) = r; r3(:,:,3) = r;
convex = regionprops3(r3,'Centroid','BoundingBox','ConvexHull','ConvexImage','ConvexVolume');
box3 = convex.BoundingBox;
hull3 = convex.ConvexHull{1};
convex_i3 = convex.ConvexImage{1};
% plot
new_r = zeros(size(r3));
point_list = List_All_Points_In_Image(size(convex_i3));
point_list_raw = Convert_From_Bounding_Box_To_Raw_Image(point_list,box3);
for p = 1:size(point_list,1)
        i = point_list(p,1); j = point_list(p,2); k =point_list(p,3);
        ii = point_list_raw(p,1); jj = point_list_raw(p,2);kk= point_list_raw(p,3);
        % before = 0, after = 0 -> 0
        % before = 1, after = 1 -> 1
        % before = 0, after = 1 -> 2
        % before = 1, after = 0 -> 3
        if r3(ii,jj,kk) == 0 && convex_i3(i,j,k) == 0 
            new_r(ii,jj,kk) = 0;
        elseif r3(ii,jj,kk)== 1 && convex_i3(i,j,k) == 1
            new_r(ii,jj,kk) = 1;
        elseif r3(ii,jj,kk)== 0 && convex_i3(i,j,k) == 1
            new_r(ii,jj,kk) = 2;
        elseif r3(ii,jj,kk)== 1 && convex_i3(i,j,k) == 0
            new_r(ii,jj,kk) = 3;
        end
end
figure()
imagesc(new_r(:,:,2))
%%
figure()
phantom = new_r;
p = permute(phantom,[1 2 4 3]); 
p = p > 0;
size(p)
montage(p)
truesize([300,300])
% montage(phantom,[min(phantom(:)) max(phantom(:))])
            