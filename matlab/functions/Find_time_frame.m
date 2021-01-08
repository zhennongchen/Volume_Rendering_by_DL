function [t] = Find_time_frame(file_name,signal)

dot_pos = strfind(file_name,'.');
signal_pos = strfind(file_name,signal);
t = file_name(signal_pos(end)+1 : dot_pos(1)-1);
t = str2num(t);



