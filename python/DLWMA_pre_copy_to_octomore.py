#!/usr/bin/env python

'''this script transfers video files from NAS drive to octomore'''

import glob
import os
import os.path
import numpy as np
import shutil
import supplement
import pandas as pd
import function_list_VR as ff
cg = supplement.Experiment() 

# read the patient list from excel file (which shows the excluded data for volume rendering AI)
excel_file = os.path.join(cg.fc_main_dir,'Patient_list/WMA_Label_List.xlsx')
patient_list = ff.get_patient_list_from_excel_file(excel_file,[['angle_0','x'],['angle_120','x']])




# make folder in octomore
local_folder = os.path.join(cg.local_dir,'original_movie')
ff.make_folder([local_folder])

# copy to octomore
for p in patient_list:
    patient_class = p[0]
    patient_id = p[1]
    print(patient_class,patient_id)

    folder = os.path.join(cg.fc_main_dir,'avi_movie_collection',patient_class,patient_id)
    dest_folder = os.path.join(local_folder,patient_class,patient_id)
    if os.path.isdir(dest_folder) == 0:
        ff.make_folder([os.path.dirname(dest_folder)])
        shutil.copytree(folder,dest_folder)

# # copy to octomore
# for m in movie_list:
#     if os.path.exists(os.path.join(local_folder,os.path.basename(m))):
#         print(" find %s in the destination. Skipping." % (os.path.basename(m)))
#         continue
#     else:
#         shutil.copyfile(m,os.path.join(local_folder,os.path.basename(m)))

# # check whether the transfer is completed
# l = ff.find_all_target_files(['*.avi'],local_folder)
# print(l.shape)
