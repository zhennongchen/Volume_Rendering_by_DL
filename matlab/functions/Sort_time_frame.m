function [f_sort] = Sort_time_frame(list)

% list is a struct variable where the field "name" contains the file name

t = [];
for i = 1:size(list,1)
    t = [t ; Find_time_frame(list(i).name,'_')];
end

t_sort = sort(t);
f_sort = [];
for i = 1:size(list,1)
    index = find(t == t_sort(i));
    f_sort = [f_sort ; convertCharsToStrings(list(index).name)];
end