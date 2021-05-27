#!/usr/bin/env python

'''this script assigned classes to each movie, based on the a excel sheet (WMA_label_list.xlsx) in which the label of each movie (each view angle)
is recorded. Label >= 0.5 is abnormal (=1), and Label < 0.5 is normal (=0). The output is a excel sheet with columns:
video_name, class, label, patient_class, patient_id, angle, video_name_no_ext '''

import glob
import os
import os.path
import numpy as np
import supplement
import pandas as pd
import function_list_VR as ff
cg = supplement.Experiment() 


excel_file = os.path.join(cg.fc_main_dir,'Patient_List/WMA_Label_List_test.xlsx')
excel_file = pd.read_excel(excel_file)
# clean data
excel_file = excel_file.fillna('')
excel_file = excel_file.loc[(excel_file['angle_60'] != 'x') & (excel_file['angle_300'] != 'x')]
print(excel_file.shape)

# build the excel sheet
result = []
for i in range(excel_file.shape[0]):
    case = excel_file.iloc[i]
    patient_id = case['Patient_ID']
    patient_class = case['Patient_Class']

    print(patient_class, patient_id)

    # find all the movies belonged to this case
    movie_list = ff.sort_timeframe(ff.find_all_target_files(['*.avi'],os.path.join(cg.fc_main_dir,'avi_movie_collection',patient_class,patient_id,'Volume_Rendering_Movies')),1,'_')
    assert len(movie_list) == 6
    for m in movie_list:
        # get video_name and video_name_no_ext
        video_name = os.path.basename(m)
        video_name_sep = video_name.split('.') # remove .avi
        video_name_no_ext = video_name_sep[0]
        if len(video_name_sep) > 2:
            for ii in range(1,len(video_name_sep)-1):
                video_name_no_ext += '.'
                video_name_no_ext += video_name_sep[ii]
        
        # get angle
        angle = ff.find_timeframe(video_name,1,'_')
        
        # get the label and corresponding class
        column_name = 'angle_' + str(angle)
        label = case[column_name]
        if label >= 0.5:
            assigned_class = 'abnormal'
        else:
            assigned_class = 'normal'
      
        result.append([video_name, assigned_class, label, patient_class, patient_id, angle, video_name_no_ext])

result_df = pd.DataFrame(result,columns= ['video_name', 'class', 'label', 'Patient_Class', 'Patient_ID', 'angle', 'video_name_no_ext'])
result_df.to_excel(os.path.join(cg.fc_main_dir,'Patient_List/movie_list_w_classes_test.xlsx'),index = False)

