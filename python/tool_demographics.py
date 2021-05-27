#!/usr/bin/env python

'''this script calculated the demographical info from excel spreadsheet'''

import glob
import os
import os.path
import numpy as np
import supplement
import pandas as pd
import function_list_VR as ff
cg = supplement.Experiment() 

patient_list = pd.read_excel(os.path.join(cg.fc_main_dir,'Patient_list/Patient_list_exclude.xlsx'))
patient_list = patient_list.fillna('')
train_list = pd.read_excel(os.path.join(cg.fc_main_dir,'Patient_list/WMA_Label_List_train.xlsx'))
test_list = pd.read_excel(os.path.join(cg.fc_main_dir,'Patient_list/WMA_Label_List_test.xlsx'))

## calculate the age
# in train
age = []
for i in range(0,train_list.shape[0]):
    patient_id = train_list.iloc[i]['Patient_ID']
    row = patient_list.loc[patient_list['Patient_ID'] == patient_id]
    a = row.iloc[0]['Age']
    if len(a) == 4:
        age.append(int(a[1])*10 + int(a[2]))
age = np.asarray(age)
print(age.mean(), age.std())
# in test
age = []
for i in range(0,test_list.shape[0]):
    patient_id = test_list.iloc[i]['Patient_ID']
    row = patient_list.loc[patient_list['Patient_ID'] == patient_id]
    a = row.iloc[0]['Age']
    if len(a) == 4:
        age.append(int(a[1])*10 + int(a[2]))
age = np.asarray(age)
print(age.mean(), age.std())

# male percentage
# in train
male = 0
for i in range(0,train_list.shape[0]):
    patient_id = train_list.iloc[i]['Patient_ID']
    row = patient_list.loc[patient_list['Patient_ID'] == patient_id]
    if row.iloc[0]['Sex'] == 'M':
        male += 1
print(male/ train_list.shape[0])
# in test
male = 0
for i in range(0,test_list.shape[0]):
    patient_id = test_list.iloc[i]['Patient_ID']
    row = patient_list.loc[patient_list['Patient_ID'] == patient_id]
    if row.iloc[0]['Sex'] == 'M':
        male += 1
print(male/ test_list.shape[0])

# calculate the file size
file_size_list = []
for i in range(0,patient_list.shape[0]):
    patient_id = patient_list.iloc[i]['Patient_ID']
    patient_class = patient_list.iloc[i]['Patient_Class']
    video_path = ff.find_all_target_files(['*0.avi'], os.path.join(cg.fc_main_dir,'avi_movie_collection',patient_class, patient_id, 'Volume_Rendering_Movies/'))
    if len(video_path) != 0:
        filesize = os.path.getsize(video_path[0])
        file_size_list.append(filesize / 1024)
file_size_list = np.asarray(file_size_list)
print(file_size_list.mean(), file_size_list.std())