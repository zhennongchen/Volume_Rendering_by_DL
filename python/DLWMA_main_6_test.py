#!/usr/bin/env python

"""
Validate our RNN. Basically just runs a validation generator on
about the same number of videos as we have in our test set.
"""
from keras.callbacks import TensorBoard, ModelCheckpoint, CSVLogger
from DLWMA_util_models import ResearchModels
from DLWMA_util_data import DataSet
import argparse
import pandas as pd
import os
import supplement
import numpy as np
import function_list_VR as ff
cg = supplement.Experiment() 


def test(data_type, data_file, angle, batch_list, model,pick_model_for_per_patient_test, learning_rate,learning_decay, suffix, seq_length, saved_model=None,
             class_limit=None, image_shape=None, per_patient_analysis = True):
    
    final_result_list = []
    data = DataSet(
                data_file = data_file,
                validation_batch = None,
                seq_length=seq_length,
                class_limit=class_limit
            )
            

    if model == 'lstm_regression':
            regression = 1
            sequence_len = 2 
    else:
        regression = 0
        sequence_len = seq_length

    test_data = data.data
    print(len(test_data))

    # # get prediction by each model
    # prediction_list = []
    # for i in range(0,len(batch_list)):
    #     rm = ResearchModels(len(data.classes), model, sequence_len, learning_rate,learning_decay,saved_model[i])
    #     prediction_list_current_batch = []
    #     for sample in test_data:
    #         movie_id = sample['video_name']
    #         # get generator
    #         p_generator = data.predict_generator(sample, data_type,regression)

    #         # predict
    #         predict_output = rm.model.predict_generator(generator=p_generator,steps = 1)
    #         if regression == 0:
    #             if np.argmax(predict_output[0]) == 1: # abnormal = [1,0], normal = [0,1]
    #                 prediction_list_current_batch += [0]
    #             else:
    #                 prediction_list_current_batch += [1]
    #         else:
    #             prediction_list_current_batch += predict_output[0][0]
    #     prediction_list.append(prediction_list_current_batch)

    # # organize the prediction:
    # for t in range(0,len(test_data)):
    #     sample = test_data[t]
    #     movie_id = sample['video_name']
    #     print(movie_id)

    #     # get truth
    #     if regression == 0:  
    #         if sample['class'] == 'normal':
    #             truth = 0
    #         else:
    #             truth = 1
    #     else: 
    #         truth = float(sample['EF'])

    #     case_result = [movie_id, truth]
    #     # get predict by each model
    #     abnormal_predict_count = 0
    #     normal_predict_count = 0
    #     for i in range(0,len(batch_list)):
    #         p = prediction_list[i][t]
    #         case_result += [p]
    #         if p == 1:
    #             abnormal_predict_count += 1
    #         else:
    #             normal_predict_count += 1
                
    #     # find the majority
    #     if regression == 0:
    #         if abnormal_predict_count > normal_predict_count:
    #             case_result += [1]
    #         elif abnormal_predict_count < normal_predict_count:
    #             case_result += [0]
    #         else:
    #             print('equal count')
    #             if np.random.random()>0.5:
    #                 case_result += [1]
    #             else:
    #                 case_result += [0]
            
    #     # collect in big list
    #     case_result += [sample['label'],sample['Patient_Class'],sample['Patient_ID'],sample['angle']]
    #     final_result_list.append(case_result)
       

    # # write into excel sheet
    # column_list = ['video_name','truth'] + ['predict_model_'+str(b) for b in batch_list] + ['predict_majority','label','Patient_Class','Patient_ID','angle']
    # df = pd.DataFrame(final_result_list,columns = column_list)
    # save_folder = os.path.join(cg.fc_main_dir,'results')
    # ff.make_folder([save_folder])
    # if angle != None:
    #     df.to_excel(os.path.join(save_folder,model+'-angle_'+str(angle)+ '_' + suffix + '-testing.xlsx'),index=False)
    # else:
    #     df.to_excel(os.path.join(save_folder,model + '_' + suffix +'-testing-val_loss.xlsx'),index=False)

    # write per patient analysis

    if per_patient_analysis == True:
        save_folder = os.path.join(cg.fc_main_dir,'results')
        testing_file= pd.read_excel(os.path.join(save_folder,model+ '_' + suffix + '-testing-val_loss.xlsx'))
        # find the patient_list by np.unique
        patient_list = np.unique(testing_file['Patient_ID'])

        per_patient_result_list = []
        for p in patient_list:
            data = testing_file.loc[testing_file['Patient_ID'] == p]
            assert data.shape[0] == 6

            patient_result = [data.iloc[0]['Patient_Class'], data.iloc[0]['Patient_ID']]
            Truth = []; Predict = []
            difference_count = 0
            for angle in [0,60,120,180,240,300]:
                angle_data = data.loc[data['angle'] == angle]
                if pick_model_for_per_patient_test == 'majority':
                    [true,predict] = [angle_data.iloc[0]['truth'],angle_data.iloc[0]['predict_majority']]
                else:
                    [true,predict] = [angle_data.iloc[0]['truth'],angle_data.iloc[0]['predict_model_' + pick_model_for_per_patient_test]]

                patient_result += [true,predict]
                Truth.append(true)
                Predict.append(predict)
                if true != predict:
                    difference_count += 1
            patient_result += [difference_count]

            # different threshold of [num of movies labeled as abnormal] to define normal patient
            # threshold = 0
            for threshold in [0,1,2]:
                S = [sum(Truth), sum(Predict)]
                for ss in S:
                    if ss > threshold:
                        patient_result += [1]
                    else:
                        patient_result += [0]

            per_patient_result_list.append(patient_result)
        
        per_patient_result_df = pd.DataFrame(per_patient_result_list,columns = ['Patient_Class', 'Patient_ID','angle0_true',\
            'angle0_predict','angle60_true','angle60_predict', 'angle120_true','angle120_predict',\
            'angle180_true','angle180_predict', 'angle240_true','angle240_predict', 'angle300_true','angle300_predict','difference_count',\
            'per_patient_0_true', 'per_patient_0_predict', 'per_patient_1_true', 'per_patient_1_predict', 'per_patient_2_true', 'per_patient_2_predict' ])
        per_patient_result_df.to_excel(os.path.join(save_folder,model+ '_' + suffix +'-testing-per-patient-val_loss.xlsx'),index = False)

         
    
def main():
    data_file = os.path.join(cg.fc_main_dir,'Patient_List/movie_list_w_classes_w_picked_timeframes_test.xlsx')
    angle = None
    model = 'lstm'
    study_suffix = 'test2'
    batch_list = [0,1,2,3,4]

    # model_epoch_list = ['372', '011', '052', '249', '393'] # LSTM_test2 picked by largested val_acc
    model_epoch_list = ['004', '011', '013', '008', '010'] # LSTM_test2 picked by val_loss
    pick_model_for_per_patient_test = '3' #sometimes single model > majority, if pick majority then "majority"

    saved_model = []
    for i in range(0,len(batch_list)):
        batch = batch_list[i]
        epoch = model_epoch_list[batch]
        if angle != None:
            saved_model.append(os.path.join(cg.fc_main_dir,'models',model + '_angle'+str(angle)+'_'+study_suffix,'batch_'+str(batch), model+'-batch'+str(batch)+'-'+epoch+'.hdf5'))
        else:
            saved_model.append(os.path.join(cg.fc_main_dir,'models',model + '_' + study_suffix, 'batch_'+str(batch), model+'-batch'+str(batch)+'-'+epoch+'.hdf5'))

    seq_len = 3
    learning_rate = 1e-4
    learning_decay = 1e-5

    if model == 'conv_3d' or model == 'lrcn':
        data_type = 'images'
        image_shape = (80, 80, 3)
    else:
        data_type = 'features'
        image_shape = None

    test(data_type, data_file, angle, batch_list, model, pick_model_for_per_patient_test,learning_rate,learning_decay, study_suffix, seq_length = seq_len,saved_model=saved_model,
             image_shape=image_shape, class_limit=None, per_patient_analysis = True)

if __name__ == '__main__':

  main()