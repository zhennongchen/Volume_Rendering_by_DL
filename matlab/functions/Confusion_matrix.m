function [sensitivity,specificity,precision,true_positive,true_negative,false_positive,false_negative,result] = Confusion_matrix(val_list,cutoff,larger)

% val_list is a list in which each row is [value,class]
% larger = 1 when value > cutoff, detect as true
% larger = 0 when value < cutoff, detect as true


result = [];
for ii = 1:size(val_list,1)
    if val_list(ii,1) >= cutoff
        if larger == 1
            result = [result; val_list(ii,2),1];
        else
            result = [result; val_list(ii,2),0];
        end
     else
        if larger == 1
            result = [result; val_list(ii,2),0];
        else
            result = [result; val_list(ii,2),1];
        end
    end
end

% in result's each row, the first one is ground truth and the second one is
% classification based on cutoff

true_positive = 0; true_negative = 0;
false_positive = 0; false_negative = 0;
for iii = 1:size(result,1)
    r = result(iii,:);
    if r(1) == 1 && r(2) == 1
        true_positive = true_positive + 1;
    elseif r(1) ==0 && r(2) == 0
        true_negative = true_negative + 1;
    elseif r(1) == 0 && r(2) == 1
        false_positive = false_positive + 1;
    else
        false_negative = false_negative + 1;
    end
end
        
sensitivity = true_positive / (true_positive + false_negative);
specificity = true_negative / (true_negative + false_positive);
if true_positive + false_positive == 0
    precision = 0;
else
    precision = true_positive / (true_positive + false_positive);
end