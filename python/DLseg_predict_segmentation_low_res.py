#!/usr/bin/env python

# System
import argparse
import os

# Third Party
import numpy as np
import math
from keras.callbacks import ModelCheckpoint, LearningRateScheduler
from keras import backend as K
from keras.models import Model
from keras.layers import Input, \
                         Conv1D, Conv2D, Conv3D, \
                         MaxPooling1D, MaxPooling2D, MaxPooling3D, \
                         UpSampling1D, UpSampling2D, UpSampling3D, \
                         Reshape, Flatten, Dense
from keras.initializers import Orthogonal
from keras.regularizers import l2
import nibabel as nb
import pandas as pd
import supplement
from supplement.generator import ImageDataGenerator
import supplement.utils as ut
import dvpy as dv
import dvpy.tf
import function_list_VR as ff

cg = supplement.Experiment()


# Define pre-trained model list
model_s = 'model_batch3/model-U2_batch3_s-059-*'
model_2C_t = 'model_batch3/model-U2_batch3_2C_t-036-*'
model_2C_r = 'model_batch1/model-U2_batch1_2C_r-040-*'
model_3C_t = 'model_batch3/model-U2_batch3_3C_t-034-*'
model_3C_r = 'model_batch4/model-U2_batch4_3C_r-032-*'
model_4C_t = 'model_batch4/model-U2_batch4_4C_t-031-*'
model_4C_r = 'model_batch4/model-U2_batch4_4C_r-040-*'
model_BASAL_t = 'model_batch2/model-U2_batch2_BASAL_t-032-*'
model_BASAL_r = 'model_batch1/model-U2_batch1_BASAL_r-018-*'
MODEL = [model_s,model_2C_t,model_2C_r,model_3C_t,model_3C_r,model_4C_t,model_4C_r,model_BASAL_t,model_BASAL_r]

# prediction task list
task_list = ['s','2C_t','2C_r','3C_t','3C_r','4C_t','4C_r','BASAL_t','BASAL_r'] 
task_num_list = [0] 

# define patient CT image list
patient_list = ff.find_all_target_files(['Abnormal/*','Normal/*'],os.path.join(cg.main_dir,'nii-images'))
patient_list = np.repeat(patient_list,30)
print(len(patient_list))
print('finish loading all patient images')

# define save folder:
save_folder = os.path.join(cg.main_dir,'predicted_seg')

# load time assignment sheet
two_timeframes = 1



################################
# build the model
shape = cg.dim + (1,)
model_inputs = [Input(shape)]
model_outputs=[]
ds_layer, _, unet_output = dvpy.tf.get_unet(cg.dim,cg.num_classes,cg.conv_depth,layer_name='unet',
                                    dimension =len(cg.dim),unet_depth = cg.unet_depth,)(model_inputs[0])
ds_flat = Flatten()(ds_layer)
Loc= Dense(384,kernel_initializer=Orthogonal(gain=1.0),kernel_regularizer = l2(1e-4),
                                    activation='relu',name='Loc')(ds_flat)
translation = Dense(3,kernel_initializer=Orthogonal(gain=1e-1),kernel_regularizer = l2(1e-4),
                                    name ='t')(Loc)
x_direction = Dense(3,kernel_initializer=Orthogonal(gain=1e-1),kernel_regularizer = l2(1e-4),
                                    name ='x')(Loc)
y_direction = Dense(3,kernel_initializer=Orthogonal(gain=1e-1),kernel_regularizer = l2(1e-4),
                                    name ='y')(Loc)
model_outputs += [unet_output]
model_outputs += [translation]
model_outputs += [x_direction]
model_outputs += [y_direction]
model = Model(inputs = model_inputs,outputs = model_outputs)
print('finish building the model')


# define the generator
valgen = dv.tf.ImageDataGenerator(3,input_layer_names=['input_1'],output_layer_names=['unet','t','x','y'],)

# predict per patient
no_image_data_list = [] # record the patients without CT data

for task_num in task_num_list:
  print('current task is: ', task_list[task_num])
  if task_list[task_num] == 's':
    view = '2C'
  else:
    view = task_list[task_num].split('_')[0]
    vector = task_list[task_num].split('_')[1]
  print(view)
  ##### load saved weight
  model_file_name = MODEL[task_num]
  model_files = ff.find_all_target_files([model_file_name],cg.model_dir)
  assert len(model_files) == 1
  model.load_weights(model_files[0],by_name = True)
  print('=======\n=======\n')
  print('finish loading saved weights: ',model_files[0])

  # predict
  for p in patient_list:
    patient_class = os.path.basename(os.path.dirname(p))
    patient_id = os.path.basename(p)
    print(patient_class, patient_id)

    # find the input images for specified time frames:
    if task_list[task_num] == 's':
      if two_timeframes == 0:
        img_list = ff.find_all_target_files(['img-nii-1.5/0.nii.gz'],p)
      else:
        es = int(np.floor(len(ff.find_all_target_files(['img-nii/*'],p)) / 2.0)) - 1
        img_list = ff.find_all_target_files(['img-nii-1.5/0.nii.gz','img-nii-1.5/'+str(es)+'.nii.gz'],p)
    
    else:
      img_list = ff.find_all_target_files(['img-nii-sm/0.nii.gz'],p)
    

    if len(img_list) == 0 and task_num == task_num_list[0]:
      no_image_data_list.append(patient_class+'_'+patient_id)
      print('this case does not have CT image as the input')
      continue

    for img in img_list:
      time_frame = ff.find_timeframe(img,2)
      print(time_frame)

      # build the predict_generator
      u_pred,t_pred,x_pred,y_pred= model.predict_generator(valgen.predict_flow(np.asarray([img]),
          batch_size = cg.batch_size,
          view = view,
          relabel_LVOT = cg.relabel_LVOT,
          input_adapter = ut.in_adapt,
          output_adapter = ut.out_adapt,
          shape = cg.dim,
          input_channels = 1,
          output_channels = cg.num_classes,),
          verbose = 1,
          steps = 1,)

      # save u_net segmentation
      if task_list[task_num] == 's':
        u_gt_nii = nb.load(img)
        u_pred = np.argmax(u_pred[0], axis = -1).astype(np.uint8)
        u_pred = dv.crop_or_pad(u_pred, u_gt_nii.get_data().shape)
        u_pred[u_pred == 3] = 4
        u_pred = nb.Nifti1Image(u_pred, u_gt_nii.affine)
        save_path = os.path.join(save_folder,patient_class,patient_id,'seg-pred-1.5','pred_'+task_list[task_num]+'_'+os.path.basename(img))
        #ff.make_folder([os.path.join(save_folder,patient_class),os.path.join(save_folder,patient_class,patient_id),os.path.join(save_folder,patient_class,patient_id,'seg-pred-1.5')])
        #nb.save(u_pred, save_path)
    
    # # save vectors
    #   if task_list[task_num] != 's':
    #     x_n = ff.normalize(x_pred)
    #     y_n = ff.normalize(y_pred)
    #     matrix = np.concatenate((t_pred.reshape(1,3),x_n.reshape(1,3),y_n.reshape(1,3)))
    #     save_path = os.path.join(p,'vector-pred','pred_'+task_list[task_num])
    #     os.makedirs(os.path.dirname(save_path), exist_ok = True)
    #     np.save(save_path,matrix)

print(no_image_data_list)