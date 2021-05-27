#!/usr/bin/env python

# this script partition the dataset into 5 batches. 
# the partition can be made based on individual movie or patient.
# it will return a data.file.xlsx which shows all the data used in AI prediction
''' Two methods of partition:
    A: randomly shuffle patients, maybe (make sure the normal vs. abnormal ratio in each batch is close to the populational ratio)
    B: when we only have videos for one particular view angle, we can seperate normals and abnormals independently into N batchs 
    and combine one batch in normal and one batch in abnormal into one final batch.'''

import os
import numpy as np
import supplement
import random
import function_list_VR as ff
import pandas as pd
from sklearn.model_selection import train_test_split
cg = supplement.Experiment() 


excel_file = pd.read_excel(os.path.join(cg.fc_main_dir,'Patient_List/movie_list_w_classes_w_picked_timeframes_train.xlsx'))

method = 'A'
angle = 0
seed_in_A = 6177
seed_in_B = 3

if method == 'A': 
    # calculate the populational ratio for each view angle
    populational_ratio = []
    for angle in [0,60,120,180,240,300]:
        data_list = excel_file.loc[excel_file['angle'] == angle]
        abnormal_list = data_list.loc[data_list['class'] == 'abnormal']
        populational_ratio.append(abnormal_list.shape[0] / data_list.shape[0])
    all_angle_populational_ratio = sum(populational_ratio) / len(populational_ratio)
    print(populational_ratio,all_angle_populational_ratio)

    # get patient_list
    patient_list = [excel_file.iloc[i]['Patient_ID'] for i in range(excel_file.shape[0])]
    patient_list = np.unique(np.asarray(patient_list))
    
    # random shuffle
    count  = 0
    std = 0.06
    while 1:
        satisfy = 0
        
        #np.random.seed(seed_in_A)
        seed = np.random.randint(100000)
        print(seed)
        np.random.seed(seed)
        np.random.shuffle(patient_list)
        patient_list_split = np.array_split(patient_list,cg.num_partitions)
        Ratio = []
        ALL_ANGLE_RATIO = []
        for ii in range(0,len(patient_list_split)):
            patient_group = patient_list_split[ii]
            group_ratio = []
            for angle in [0,60,120,180,240,300]:
                abnormal_count = 0
                for p in patient_group:
                    case = excel_file.loc[(excel_file['Patient_ID'] == p) & (excel_file['angle'] == angle)]
                    
                    if case.iloc[0]['class'] == 'abnormal':
                        abnormal_count += 1
                group_ratio.append(abnormal_count / patient_group.shape[0])

            all_angle_group_ratio = sum(group_ratio) / len(group_ratio)
            Ratio.append(group_ratio)
            ALL_ANGLE_RATIO.append(all_angle_group_ratio)

        # check whether satisfy    
        check_all_angle = []
        # check all_angle first
        for ii in range(0,len(patient_list_split)):
            a = ALL_ANGLE_RATIO[ii]
            if (a <= (all_angle_populational_ratio + std)) and  (a >= (all_angle_populational_ratio - std)):
                check_all_angle.append(1)
            else:
                check_all_angle.append(0)

        # check per_angle
        check = []
        for ii in range(0,len(patient_list_split)):
            for jj in range(0,6): # 6 angles
                a = Ratio[ii][jj]
                if (a <= (populational_ratio[jj] + std)) and (a >= (populational_ratio[jj] - std)):
                    check.append(1)
                else:
                    check.append(0)

        print(check_all_angle,np.where(np.asarray(check) == 0)[0].shape[0] )
        # all satisfy:
        if (np.all(np.asarray(check_all_angle)) == True) and np.where(np.asarray(check) == 0)[0].shape[0] <= 3:
            satisfy = 1
                
        if satisfy == 1:
            print(Ratio)
            print(ALL_ANGLE_RATIO)
            print('seed is ', seed)
            break
        else:
            count += 1
            print(count)

    # save into numpy file
    np_save_folder = os.path.join(cg.fc_main_dir,'partitions/angle_all')
    ff.make_folder([os.path.basename(np_save_folder),np_save_folder])
    batch_list = []
    for i in range(cg.num_partitions):
        batch_list.append(patient_list_split[i])
        print(batch_list[i].shape)
        np.save(os.path.join(np_save_folder,'batch_'+str(i)+'.npy'), batch_list[i])

    # save into data_file.xlsx
    batch_file = []
    for i in range(0,excel_file.shape[0]):
        case = excel_file.iloc[i]
        #print(case['video_name'])
        for batch in range(cg.num_partitions):
            if np.isin(case['Patient_ID'],patient_list_split[batch]) == 1:
                B = batch
                

        batch_file.append([B, case['video_name']])

    batch_file = pd.DataFrame(batch_file,columns = ['batch','video_name'])
    df = pd.merge(batch_file,excel_file,on = 'video_name')
    df.to_excel(os.path.join(cg.fc_main_dir,'Patient_List/data_file_angle_all_train.xlsx'),index=False)


    

if method == 'B': # for movie data only containing particular view angle/angles

    np.random.seed(seed_in_B)

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

   