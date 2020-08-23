function [count] = Count_Non_White_Pixel(image_file_name,image_show)

a = imread(image_file_name);

r = zeros(size(a));
count = 0;
for i = 1:size(a,1)
    for j = 1:size(a,2)
       
        equal = [255 255 255] == [a(i,j,1) a(i,j,2) a(i,j,3)]; %white is [255 255 255];
        if ~all(equal)
            r(i,j,1) = 255;r(i,j,2) = 0; r(i,j,3) = 0;
            count = count + 1;
        else
            r(i,j,1) = 255;r(i,j,2) = 255; r(i,j,3) = 255;
        end
    end
end

if image_show == 1
    figure(1)
    imshow(a);
    figure(2)
    imshow(r);
end
