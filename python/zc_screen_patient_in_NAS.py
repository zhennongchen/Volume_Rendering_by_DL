#!/usr/bin/env python

## 
# this script screens all the cases in NAS drive, to find the patient cases having function.
##

## Notice:
## in assert_function_folder step, I forgot to turn the string into lowercase which may result in
# the loss of inclusion of some patients

## specify_functoin_folder step is re-written in zc_specify_function_folders in jupyter notebook

import os
import numpy as np
import zc_function_list as ff
import pandas as pd
import pydicom

# function prepare
def assert_function_folder(folder,keywordlist):
    # this function find the function folder that contain the keyword in the keyword list.
    # default rank of keywordlist is "Earliest_to_Latest" > "CCTA/CTA" > something else
    for k in keywordlist:
        if k in folder:
            return 1
    return 0

def specify_function_folder(folder_list,keywordlist):
    # this function find the function folder that contain the keyword in the keyword list.
    # default rank of keywordlist is "Earliest_to_Latest" > "CCTA/CTA" > something else
    t = 0
    while 1==1:
        assess = [keywordlist[t] in F for F in folder_list]
        if True in assess:
            return t,keywordlist[t]
        else:
            t += 1
        if t == len(keywordlist):
            word = 'Else'
            return t,word

main_path = '/Data/McVeighLabSuper/dicom_images'
save_path = '/Data/McVeighLabSuper/projects/Zhennong/'
keywordlist = ['_TO_','_to_','CCTA','CTA','ccta','cta','ccta','HALF','Function','function']
dicom_parameter_list = ['AccessionNumber','Manufacturer','ManufacturerModelName','StudyDescription','PatientSex','PatientAge','ProtocolName']

# put each year into one excel file
year_list = ['2017','2018','2019','2020']


for Y in year_list:
    year = ff.find_all_target_files([Y],main_path)
    patients = ff.find_all_target_files(['AN*','CVC*','cvc*','Cvc*'],year[0])
    
    patient_id = []
    scan_year = []
    function = []
    directories = []
    directories_sub = []

    Dicom = []
    AccessionNumber = []
    Manufacturer = []
    ModelName = []
    StudyDescription = []
    Sex = []
    Age = []
    Protocol = []   

    for patient in patients:
        print(os.path.basename(patient))
        if not os.path.isdir(patient):
            print('it is not a folder')
            continue

        patient_id.append(os.path.basename(patient))
        scan_year.append(os.path.basename(os.path.dirname(patient)))

        D = [os.path.basename(os.path.join(patient, o)) for o in os.listdir(patient) if os.path.isdir(os.path.join(patient,o))]
        # we only want the patients that has directories for cardiac function
        # the hypothesis here is that those patients will have directory name with "%"
        function_D = []
        count = 0
        for i in D:
            if assert_function_folder(i,['%','_TO_','_to_','CCTA','CTA','ccta','cta','HALF','Function','function']) == 1:
                count += 1
                function_D.append(i)

        if count >= 5: # have function folder
            function.append('Yes')
            directories.append(function_D)
            # select the function directory (in case there are more than one series of function folders)
            t,word = specify_function_folder(function_D,keywordlist)
            if t < len(keywordlist): # have function folder with name as "Earlist.." or "CCTA" or "Function"
                function_D_sub = []
                [function_D_sub.append(ii) for ii in function_D if word in ii]
            else:
                function_D_sub = []
                [function_D_sub.append(ii) for ii in function_D]
            directories_sub.append(function_D_sub)

        else: # no function folder
            function.append('No')
            directories.append(D)
            directories_sub.append('')

        # get dicom info
        if count >= 5:
            dicom_list = ff.find_all_target_files(['*.dcm'],os.path.join(patient,function_D_sub[0]))
            if len(dicom_list) > 0:
                Dicom.append('Yes')
                read = pydicom.read_file(dicom_list[0])
                data_list = ff.read_DicomDataset(read,dicom_parameter_list)
            else:
                Dicom.append('No')
                data_list = ['']*len(dicom_parameter_list)
        else:
            Dicom.append('')
            data_list = ['']*len(dicom_parameter_list)
        
        ff.massive_list_append([AccessionNumber,Manufacturer,ModelName,StudyDescription,Sex,Age,Protocol],data_list)

    print('finish')

    # save into dataframe
    data_collected = {'Patient_ID': patient_id,'Year':scan_year,'Function?':function,'Dicom?':Dicom,'Accession':AccessionNumber,'Manufacturer':Manufacturer,\
                  'Model':ModelName,'StudyDescription':StudyDescription,'Sex':Sex,'Age':Age,\
                  'Protocol':Protocol,'Directories_Full': directories,'Directories_w/Function':directories_sub}

    df = pd.DataFrame(data_collected)
    # write into excel file
    df.to_excel(os.path.join(save_path,Y+'_patient_overview.xlsx'),index=False)


