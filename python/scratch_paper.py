#!/usr/bin/env python

# this script can extract time frame into jpg images

import os
import pandas as pd
import supplement
import function_list_VR as ff
cg = supplement.Experiment() 

## task: add new cases in Patient_List_exclude.xlsx to WMA_Label_List.xlsx
patient_list = pd.read_excel(os.path.join(cg.fc_main_dir,'Patient_list/Patient_list_exclude.xlsx'))
patient_list.drop('Unnamed: 0',inplace=True,axis=1)
label_list = pd.read_excel(os.path.join(cg.fc_main_dir,'Patient_list/WMA_Label_List.xlsx'))
label_list.drop('Unnamed: 0',inplace=True,axis=1)


column_list = list(label_list.columns)
count = 0
for i in range(0,patient_list.shape[0]):
    case = patient_list.iloc[i]
    if case['retouch_predicted'] != 'done':
        continue
    
    patient_id = case['Patient_ID']

    if patient_id in list(label_list['Patient_ID']):
        count += 1

print(count)
       
