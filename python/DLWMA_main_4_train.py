#!/usr/bin/env python

"""
Train our RNN on extracted features or images.
"""
from keras.callbacks import TensorBoard, ModelCheckpoint, EarlyStopping, CSVLogger
from DLWMA_util_models import ResearchModels
from DLWMA_util_data import DataSet
import argparse
import time
import pandas as pd
import os
import numpy as np
import tensorflow as tf
from sklearn.utils.class_weight import compute_class_weight, compute_sample_weight
import supplement
import function_list_VR as ff
cg = supplement.Experiment() 

tf.set_random_seed(cg.seed)

def find_number_of_training_testing_data(data_file, batch,seq_length,class_limit = None, image_shape = None):
    data = DataSet(
            data_file = data_file,
            validation_batch = batch,
            seq_length=seq_length,
            class_limit=class_limit,
            image_shape=image_shape)

    train_data,test_data = data.split_train_test()
    print('training num: ',len(train_data),'testing num: ',len(test_data))

    return train_data,test_data

    

def train(data_type, data_file, angle, batch, seq_length, model, learning_rate,learning_decay,study_suffix , saved_model=None,
          class_limit=None, image_shape=None,
          load_to_memory=False, batch_size=32, nb_epoch=100):

    if model == 'lstm_regression':
        regression = 1
        monitor_par = 'val_loss'
        sequence_len = 2
    else:
        regression = 0
        monitor_par = 'val_acc'
        sequence_len = seq_length

    # Helper: Save the model.
    save_folder = os.path.join(cg.fc_main_dir,'models')
    if angle == None:
        model_save_folder = os.path.join(save_folder,model+'_'+study_suffix)
    else:
        model_save_folder = os.path.join(save_folder, model + '_angle' + angle + '_' + study_suffix)
    model_save_folder2 = os.path.join(model_save_folder,'batch_' + str(batch))
    log_save_folder = os.path.join(save_folder,'logs')
    ff.make_folder([save_folder,model_save_folder,model_save_folder2, log_save_folder])

    checkpointer = ModelCheckpoint(
        filepath=os.path.join(model_save_folder2, model+ '-batch'+str(batch)+'-{epoch:03d}.hdf5'),
        monitor=monitor_par,
        verbose=1,
        save_best_only=False)

    # # Helper: TensorBoard
    # tb = TensorBoard(log_dir=os.path.join('data', 'logs', model))

    # # Helper: Stop when we stop learning.
    # early_stopper = EarlyStopping(patience=5)

    # Helper: Save results.
    #timestamp = time.time()
    if angle != None:
        csv_logger = CSVLogger(os.path.join(log_save_folder,  model + '-angle'+ angle + '_'+study_suffix  + '-batch' + str(batch) + '-training-log' + '.csv'))
    else:
        csv_logger = CSVLogger(os.path.join(log_save_folder,  model + '_' + study_suffix + '-batch' + str(batch) + '-training-log' + '.csv'))


    # Get the data and process it.
    if image_shape is None:
        data = DataSet(
            data_file = data_file,
            validation_batch = batch,
            seq_length=seq_length,
            class_limit=class_limit
        )
    else:
        data = DataSet(
            data_file = data_file,
            validation_batch = batch,
            seq_length=seq_length,
            class_limit=class_limit,
            image_shape=image_shape
        )
       
    # Get generators.
    generator = data.frame_generator(batch_size, 'train', data_type,regression,True)
    val_generator = data.frame_generator(batch_size, 'test', data_type,regression, True)

    # Get the model.
    rm = ResearchModels(len(data.classes), model, sequence_len, learning_rate,learning_decay,saved_model)

    # Use fit generator.
    # Get samples per epoch.
    train_data,test_data = data.split_train_test()
    print('training num: ',len(train_data),'testing num: ',len(test_data))

    steps_per_epoch_train = len(train_data) // batch_size
    print('step in the training is: %d'%steps_per_epoch_train)
    steps_per_epoch_test = len(test_data) // batch_size
    print('step in the test is: %d'%steps_per_epoch_test)

    # Get class weights for class imbalance
    D = pd.read_excel(data_file)
    class_weights = compute_class_weight('balanced',np.unique(D['class']), D['class'])
    print(np.unique(D['class']))
    print(class_weights)  

    hist = rm.model.fit_generator(
        generator=generator,
        class_weight=class_weights,
        steps_per_epoch=steps_per_epoch_train, # in each epoch all the training data are evaluated
        epochs=nb_epoch,
        verbose=1,
        callbacks=[checkpointer, csv_logger], 
        validation_data=val_generator,
        validation_steps=steps_per_epoch_test,
        workers=1) # if you see that GPU is idling and waiting for batches, try to increase the amout of workers
    return hist

def main(batch):
    """These are the main training settings. Set each before running
    this file."""

    data_file = os.path.join(cg.fc_main_dir,'Patient_List/data_file_angle_all_train.xlsx')
    angle = None
    # model can be one of lstm, lstm_regression,lrcn, mlp, conv_3d, c3d
    model = 'lstm'
    study_suffix = 'test2'

    saved_model = None  # None or weights file
    class_limit = None  # int, can be 1-101 or None
    seq_length = 3
    load_to_memory = False  # pre-load the sequences into memory
    nb_epoch = 400
    learning_rate = 1e-4
    learning_decay = 1e-5
    batch_size = 5
    
    train_data,test_data = find_number_of_training_testing_data(data_file, batch,seq_length)
    print('training num: ',len(train_data),'testing num: ',len(test_data))
    

    # Chose images or features and image shape based on network.
    if model in ['conv_3d', 'c3d', 'lrcn']:
        data_type = 'images'
        image_shape = (80, 80, 3)
    elif model in ['lstm', 'lstm_regression','mlp']:
        data_type = 'features'
        image_shape = None
    else:
        raise ValueError("Invalid model. See train.py for options.")
    
    print('start_to_train')
    hist = train(data_type, data_file, angle, batch, seq_length, model, learning_rate,learning_decay,study_suffix, saved_model=saved_model,
          class_limit=class_limit, image_shape=image_shape,
          load_to_memory=load_to_memory, batch_size=batch_size, nb_epoch=nb_epoch)
    

if __name__ == '__main__':

  parser = argparse.ArgumentParser()
  parser.add_argument('--batch', type=int)
  args = parser.parse_args()

  if args.batch is not None:
    assert(0 <= args.batch < cg.num_partitions)

  main(args.batch)
