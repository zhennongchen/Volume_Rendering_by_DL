#!/usr/bin/env python

## 
# this script assert that all time frames of one patient are in its folder in nii-images.
# it's necessary because sometimes some files will be accidentally delete
##

## THIS SCRIPT can also find the nii files with ineligible name since it will stop the code from running.
import os
import numpy as np
import function_list_VR as ff
import shutil


main_folder = '/Data/McVeighLabSuper/wip/zhennong/'
patients = ff.find_all_target_files(['Abnormal/*','Normal/*'],os.path.join(main_folder,'nii-images'))
for p in patients:
    print(os.path.basename(p))
    image_list = ff.sort_timeframe(ff.find_all_target_files(['img-nii/*'],p),2)

    tf_list = []
    for img in image_list:
        tf_list.append(ff.find_timeframe(img,2))
    assert len(tf_list) > 0

    # time frame list should be consecutive
    for ii in range(1,len(tf_list)):
        if tf_list[ii] - tf_list[ii-1] != 1:
            print('Error! Missing data here')
            print(ii,ii-1,os.path.basename(p),'\n\n\n')