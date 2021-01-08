function [BW] = Find_largest_connected_component_3d(BW)

CC = bwconncomp(BW);
numPixels = cellfun(@numel,CC.PixelIdxList);

if size(CC.PixelIdxList,2) ~= 0
    [biggest,idx] = max(numPixels);
    for i = 1:size(CC.PixelIdxList,2)
        if i ~= idx
            BW(CC.PixelIdxList{i}) = 0;
        end
    end
end
