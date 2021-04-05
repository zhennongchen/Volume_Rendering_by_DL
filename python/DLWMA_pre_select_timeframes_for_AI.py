#!/usr/bin/env python

'''this script defines timeframes that will be input into the model (hypothesis: model won't take all the time frames but only a few).
the chosen timeframes will be written into  movie_list_w_classes.xlsx'''
'''current plan is to find ED, mid_ES, ES'''

import os
import numpy as np
import supplement
import pandas as pd
import nibabel as nb
import function_list_VR as ff
cg = supplement.Experiment() 

excel_file = pd.read_excel(os.path.join(cg.fc_main_dir,'Patient_List/movie_list_w_classes.xlsx'))

# get patient_list:
patient_id_list = np.unique(excel_file['Patient_ID'])
patient_list = []
for p in patient_id_list:
    d = excel_file[excel_file['Patient_ID'] == p].iloc[0]
    patient_list.append([d['Patient_Class'],p])

# get their segmentations and find the ES
timeframe_pick = []
for p in patient_list:
    patient_class = p[0]
    patient_id = p[1]

    # find segmentations
    segmentations = ff.sort_timeframe(ff.find_all_target_files(['pred_*.nii.gz'],os.path.join(cg.nas_main_dir,'predicted_seg',patient_class,patient_id,'seg-pred-0.625-4classes-connected-retouch')),2,'_')
    lv_volume_list = []
    for s in segmentations:
        data = nb.load(s).get_fdata()
        count,_ = ff.count_pixel(data,1)
        lv_volume_list.append(count)
    min_val = min(lv_volume_list)
    lv_volume_list = np.asarray(lv_volume_list)
    index = np.where(lv_volume_list == min_val)[0]
    if index.shape[0] > 1:
        ValueError('two mins')
    
    ED = 0
    ES = ff.find_timeframe(segmentations[index[0]],2,'_')
    if (ES-ED) % 2 == 0:
        mid_ES = (ES-ED) // 2 
    else:
        mid_ES = (ES-ED) // 2 + 1
    
    print(patient_class,patient_id,ED,mid_ES, ES)

    video_list = excel_file[excel_file['Patient_ID'] == patient_id]
    for ii in range(0,video_list.shape[0]):
        timeframe_pick.append([video_list.iloc[ii]['video_name'],ED,ES,mid_ES])


timeframe_pick_df = pd.DataFrame(timeframe_pick, columns = ['video_name','ED','ES','mid_ES'])
df = pd.merge(excel_file, timeframe_pick_df, on = "video_name")
df.to_excel(os.path.join(cg.fc_main_dir,'Patient_List/movie_list_w_classes_w_picked_timeframes.xlsx'),index = False)
    


    



    



        



