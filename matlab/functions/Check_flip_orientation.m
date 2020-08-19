function [class] = Check_flip_orientation(data)

% class = 1 is non-toshiba patients, = 2 is toshiba patients
% it can be found by data.hdr.hist.flip_orient
% toshiba has orientation = [3 3 3]
% non_toshiba = [3 0 0];

orient = data.hdr.hist.flip_orient;
compare = orient == [3 3 3];
if all(compare) == 1
    class = 1;
else
    class = 0;
end

