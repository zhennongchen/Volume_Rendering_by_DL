#!/usr/bin/env python

# this script partition the dataset into 5 batches. 
# the partition can be made based on individual movie or patient.
# it will return a data.file.xlsx which shows all the data used in AI prediction
''' Two methods of partition:
    A: randomly shuffle patients and pick, make sure the normal vs. abnormal ratio in each batch is close to the populational ratio
    B: when we only have videos for one particular view angle, we can seperate normals and abnormals independently into N batchs 
    and combine one batch in normal and one batch in abnormal into one final batch.'''

import os
import numpy as np
import supplement
import function_list_VR as ff
import pandas as pd
from sklearn.model_selection import train_test_split
cg = supplement.Experiment() 

np.random.seed(0)

excel_file = pd.read_excel(os.path.join(cg.fc_main_dir,'Patient_List/movie_list_w_classes_w_picked_timeframes.xlsx'))

method = 'B'
angle = 120

if method == 'A':
    a= 1

if method == 'B':
    data_list = excel_file[excel_file['angle'] == angle]
    normal_list = data_list[data_list['class'] == 'normal']
    abnormal_list = data_list[data_list['class'] == 'abnormal']
    populational_ratio = abnormal_list.shape[0] / data_list.shape[0]
    print('populational_ratio',populational_ratio)

    N = [normal_list.iloc[i]['video_name_no_ext'] for i in range(normal_list.shape[0])]
    np.random.shuffle(N)
    normal_list_split = np.array_split(N,cg.num_partitions)
    print(normal_list_split[0][0])

    A = [abnormal_list.iloc[i]['video_name_no_ext'] for i in range(abnormal_list.shape[0])]
    np.random.shuffle(A)
    abnormal_list_split = np.array_split(A,cg.num_partitions)
    print(abnormal_list_split[0][0])

    # save into numpy file
    batch_list = []
    np_save_folder = os.path.join(cg.fc_main_dir,'partitions/angle_'+str(angle)+'_only')
    ff.make_folder([os.path.basename(np_save_folder),np_save_folder])
    for i in range(cg.num_partitions):
        batch_list.append(np.concatenate((normal_list_split[i],abnormal_list_split[i])))
        print('batch ',i, ' ', abnormal_list_split[i].shape[0]/batch_list[i].shape[0])
        np.save(os.path.join(np_save_folder,'batch_'+str(i)+'.npy'), batch_list[i])

    # save the data_file.xlsx
    batch_file = []
    for i in range(cg.num_partitions):
        L = batch_list[i]
        for l in L:
            batch_file.append([i,l])
    
    batch_file = pd.DataFrame(batch_file,columns = ['batch','video_name_no_ext'])
    df = pd.merge(batch_file,data_list,on = 'video_name_no_ext')
    df.to_excel(os.path.join(cg.fc_main_dir,'Patient_List/data_file_angle_' + str(angle) + '.xlsx'),index=False)

    

 
    

    # patient_id_list = np.unique(csv_file['patient_id'])
    # patient_list = []
    # for p in patient_id_list:
    #     d = csv_file[csv_file['patient_id'] == p].iloc[0]
    #     patient_list.append([d['patient_class'],p])


    # np.random.shuffle(patient_list)
    # a = np.array_split(patient_list,cg.num_partitions) # into 5 batches

    # ff.make_folder([os.path.join(cg.nas_main_dir,'partitions')])
    # for i in range(0,cg.num_partitions):
    #     np.save(os.path.join(cg.nas_main_dir,'partitions','batch_'+str(i)+'.npy'),a[i])


    # # change the excel file
    # batch_list = []
    # for j in range(0,csv_file.shape[0]):
    #     case = csv_file.iloc[j]
    #     for batch in range(0,cg.num_partitions):
    #         if np.isin(case['patient_id'],a[batch]) == 1:
    #             batch_list.append([batch,case['video_name']])
    # batch_df = pd.DataFrame(batch_list,columns = ['batch','video_name'])

    # # merge two dataframe
    # result = pd.merge(batch_df,csv_file,on="video_name")
    # result.to_excel(os.path.join(cg.nas_main_dir,'movie_list_w_classes.xlsx'),index=False)





    




