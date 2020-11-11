#!/usr/bin/env python

## 
# this script can do file copy and removal
##

import os
import numpy as np
import function_list_VR as ff
import shutil
import pandas as pd

#### copy files
main_folder = '/Data/McVeighLabSuper/wip/zhennong/'

patient_list = ff.find_all_target_files(['Abnormal/*/img-nii-0.625'],os.path.join(main_folder,'nii-images'))
save_folder = os.path.join(main_folder,'upsample-nii-images')

for p in patient_list:
    patient_id = os.path.basename(os.path.dirname(p))
    patient_class = os.path.basename(os.path.dirname(os.path.dirname(p)))
    print(patient_id,patient_class)
    ff.make_folder([os.path.join(save_folder,patient_class,patient_id),os.path.join(save_folder,patient_class,patient_id,'img-nii-0.625')])

    img_list = ff.find_all_target_files(['*.nii.gz'],p)
    for i in img_list:
        print(os.path.basename(i))
        if os.path.isfile(os.path.join(save_folder,patient_class,patient_id,'img-nii-0.625',os.path.basename(i))) != 1:
            shutil.copy(i,os.path.join(save_folder,patient_class,patient_id,'img-nii-0.625',os.path.basename(i)))
        else:
            print('already done')

#################################################


# data = pd.read_csv(os.path.join(main_folder,'suspicious_candidates.csv'))
# patient_list = []
# for i in range(0,data.shape[0]):
#     patient_list.append(data['Patient_ID'].iloc[i])


# for p in patient_list:
#     print(p)
#     if os.path.isdir(os.path.join(main_folder,'Suspicious',p)) != 1:
#         shutil.copytree(os.path.join(main_folder,'Abnormal',p),os.path.join(main_folder,'Suspicious',p))
    
################################################   

#### delete
# c = 0
# for p in patient_list:
#     print(p)
#     if os.path.isdir(os.path.join(main_folder,'Abnormal',p)) == 1:
#         shutil.rmtree(os.path.join(main_folder,'Abnormal',p))

##### count
# a = ff.find_all_target_files(['Abnormal/*'],os.path.join(main_folder,'nii-images'))
# b = ff.find_all_target_files(['Normal/*'],os.path.join(main_folder,'nii-images'))
# c = ff.find_all_target_files(['Suspicious/*'],os.path.join(main_folder,'nii-images'))

# print(len(a),len(b),len(c))