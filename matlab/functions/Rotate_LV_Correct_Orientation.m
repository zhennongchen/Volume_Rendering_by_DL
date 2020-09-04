function [Irot,segrot,rot] = Rotate_LV_Correct_Orientation(image,seg,rotinfo_known,previous_rot)

% this script is not suitable for high resolution image due to memory issue
%rotinfo_known = 1 if rotation angle already obtained from ED time frame

if rotinfo_known == 0
    % Determining mean z-slice of LV to determine optimal angle for rotation
    [~,~,fr] = ind2sub(size(seg),find(seg==1));
    temp = round(mean([min(fr) max(fr)]));
    % Calculating angles - z
    figure('pos',[10 10 1000 1000])
    imagesc(image(:,:,temp)); hold on
    axis equal; colormap gray; caxis([-100 700])
    title('Rotate about Z axis: Click at base FIRST, THEN at apex','FontSize',30)
    [yp,zp] = ginput(2);
    rot.first_z = atan(diff(yp)/diff(zp)); % first rotation, according to z axis
    close
    % apply transformation
    [~,M_z] = Rotation_Matrix_From_Three_Axis(0,0,-rot.first_z,0);
    tform_z = affine3d(M_z);
    Irot = imwarp(image,tform_z);
    segrot = imwarp(seg,tform_z,'nearest');

    % Determining mean y-slice of LV to determine optimal angle for rotation
    [~,fr,~] = ind2sub(size(segrot),find(segrot==1));
    temp = round(mean([min(fr) max(fr)]));

     % Calculating angles - x
    figure('pos',[10 10 1000 1000])
    imagesc(squeeze(Irot(:,temp,:)));
    axis equal; colormap gray; caxis([-100 700])
    title('Rotate about X axis: Click at base FIRST, THEN at apex','FontSize',30)
    [yp,zp] = ginput(2);
    rot.second_x = pi/2 - atan(diff(yp)/diff(zp));
    close;

    [~,M_x] = Rotation_Matrix_From_Three_Axis(-rot.second_x,0,0,0);
    tform_x = affine3d(M_x);
    Irot = imwarp(Irot,tform_x);
    segrot = imwarp(segrot,tform_x,'nearest');

    % Determining mean z-slice of LV to determine optimal angle for rotation
    [~,~,fr] = ind2sub(size(segrot),find(segrot==1));
    temp = round(mean([min(fr) max(fr)]));

    % Calculating angles - y (rotation of LV about its long axis)
    figure('pos',[10 10 1000 1000])
    imagesc(squeeze(Irot(:,:,temp)));
    axis equal; colormap gray; caxis([-100 700])
    title('Rotate about LV axis: Click inferior wall FIRST, THEN anterior wall','FontSize',30)
    [yp,zp] = ginput(2);
    disp(yp)
    disp(zp)
    rot.third_z = atan(diff(yp)/diff(zp));
     close;

    [~,M_y] = Rotation_Matrix_From_Three_Axis(0,0,rot.third_z,0);
    tform_y = affine3d(M_y');
    Irot = imwarp(Irot,tform_y);
    segrot = imwarp(segrot,tform_y,'nearest');

else
    [~,M_z] = Rotation_Matrix_From_Three_Axis(0,0,-previous_rot.first_z,0);
    tform_z = affine3d(M_z);
    Irot = imwarp(image,tform_z);
    segrot = imwarp(seg,tform_z,'nearest');
 
    
    [~,M_x] = Rotation_Matrix_From_Three_Axis(-previous_rot.second_x,0,0,0);
    tform_x = affine3d(M_x);
    Irot = imwarp(Irot,tform_x);
    segrot = imwarp(segrot,tform_x,'nearest');
   
    
    [~,M_y] = Rotation_Matrix_From_Three_Axis(0,0,previous_rot.third_z,0);
    tform_y = affine3d(M_y');
    Irot = imwarp(Irot,tform_y);
    segrot = imwarp(segrot,tform_y,'nearest');
 
    
   rot = previous_rot;
end
    
    
   

