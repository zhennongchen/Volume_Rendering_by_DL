#!/usr/bin/env python

# this script can assign the time frame of each patient that pre-trained AI will predict on
# the main point here is that to collect a dataset with pre-trained AI predicted segmentation on some
# time frame, we should not only have time frame 0 but should half ED half ES

import os
import numpy as np
import function_list_VR as ff
import shutil
import pandas as pd

np.random.seed(0)
main_folder = '/Data/McVeighLabSuper/wip/zhennong/'

# find all patients in the training dataset
patient_list = ff.find_all_target_files(['Abnormal/*','Normal/*'],os.path.join(main_folder,'nii-images'))
total_num = len(patient_list)
print(total_num) # 375

# make ED = 0 and ES = 1 randoml shuffle list
a = [0] * int((total_num / 2)) # 187
a.extend([1] * int(total_num - int(total_num / 2)))
a = np.asarray(a)
np.random.shuffle(a)
print(a,a.shape)

# assign to each patient
result = []
for i in range(0,len(patient_list)):
    p = patient_list[i]
    patient_id = os.path.basename(p)
    patient_class = os.path.basename(os.path.dirname(p))
    if a[i] == 0:
        ed_es = 'ED'
        image_list = ff.find_all_target_files(['img-nii/*'],p)
        timeframe = 0
    else:
        ed_es = 'ES'
        image_list = ff.find_all_target_files(['img-nii/*'],p)
        timeframe = int(np.floor(len(image_list) / 2.0)) - 1
    result.append([patient_class,patient_id,ed_es,timeframe,len(image_list)])

df = pd.DataFrame(result,columns = ['Patient_Class','Patient_ID','ED/ES','Timeframe_picked','Total_timeframes'])
df.to_csv(os.path.join(main_folder,'time_frame_assignment_for_pretrained_AI_prediction.csv'),index = True)


