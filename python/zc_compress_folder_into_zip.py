#!/usr/bin/env python

## 
# this script screens all the cases in NAS drive, to find the patient cases having function.
##

import os
import numpy as np
import zc_function_list as ff
import shutil

main_dir = '/Data/McVeighLabSuper/projects/Zhennong/Zhennong_CT_Data'
save_dir = os.path.join(main_dir,'img-nii-folder')
print(save_dir)
ff.make_folder([save_dir])
patient_list = ff.find_all_target_files(['CVC*'],main_dir)


for p in patient_list:
    patient = os.path.basename(p)
    print(patient)
    if os.path.isfile(os.path.join(save_dir,patient+'_nii.zip')):
        print('already zip')
        continue

    nii_folder = os.path.join(p,'img-nii')
    shutil.make_archive(os.path.join(save_dir,patient+'_nii'),'zip',nii_folder)
    



#shutil.make_archive(output_filename, 'zip', dir_name)