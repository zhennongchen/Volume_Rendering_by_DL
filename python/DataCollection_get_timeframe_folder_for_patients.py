#!/usr/bin/env python

## 
# this script records all the folders for time frames in one cardiac cycle for each case as a numpy file
# this is useful because in the raw data sometimes contains more time frames than one cycle.
##

import os
import numpy as np
import function_list_VR as ff
import pandas as pd

main_folder = '/Data/McVeighLabSuper/wip/zhennong'
patient_list = ff.find_all_target_files(['Abnormal/*','Normal/*'],main_folder)

result = []
for patient in patient_list:
    patient_id = os.path.basename(patient)
    normal = os.path.basename(os.path.dirname(patient))

    folder_name = ff.find_all_target_files(['img-dcm/*'],patient)

    result.append([patient_id,normal,folder_name])
 

df = pd.DataFrame(result)
df = df.to_numpy()
print(df.shape,df[1,:])

np.save(os.path.join(main_folder,'folder_list_one_cardiac_cycle_for_all_cases'),df)

# a = np.load(os.path.join(main_folder,'folder_list_one_cardiac_cycle_for_all_cases.npy'),allow_pickle = True)
# print(a.shape)
# print(a[90,:])
# print(a[90,2])