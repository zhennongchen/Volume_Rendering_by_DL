#!/usr/bin/env bash

# run in terminal of your own laptop (this script is written specifically for Jura)

##############
## Settings ##
##############

set -o nounset
set -o errexit
set -o pipefail

# define the folder where dcm2niix function is saved
dcm2niix_fld="/Users/zhennongchen/Documents/GitHub/AI_plane_reslicing_product_version/dcm2niix_11-Apr-2019/"


# define patient lists
PATIENTS=(/Users/zhennongchen/Desktop/MPR/Abnormal/* )
PATIENTS+=(/Users/zhennongchen/Desktop/MPR/Normal/* )


# slice list
SLICE[0]=2C
SLICE[1]=3C
SLICE[2]=4C
SLICE[3]=SAX

# define image folder
img_fld="mpr-dcm"

for p in ${PATIENTS[*]};
do
    patient_id=$(basename ${p})
    patient_class=$(basename $(dirname ${p}))
    patient_folder=/Users/zhennongchen/Desktop/MPR/${patient_class}/${patient_id}/

    if  [ ! -d ${patient_folder} ];then
        echo "no image"
        continue
    fi

    echo ${patient_folder}
    output=/Users/zhennongchen/Desktop/MPR/${patient_class}/${patient_id}/mpr-nii
    mkdir -p ${output}


    for s in ${SLICE[*]};
    do
        slice_folder=(${patient_folder}${img_fld}/${s}_*)
        echo ${slice_folder[0]}
        slice_output_folder=${output}/${s}
        mkdir -p ${slice_output_folder}

        IMGS=( ${slice_folder[0]}/* )
        for i in $(seq 0 $(( ${#IMGS[*]} - 1 )));
        do  
            output_file=${slice_output_folder}/${i}.nii.gz
            echo ${output_file}
            if [ -f ${output_file} ];then
                echo "already done this file"
                continue
            else
                ${dcm2niix_fld}dcm2niix -i n -b n -m n -s y -o "${slice_output_folder}/" -f "${i}" -9 -z y "${IMGS[${i}]}"
            fi


        
        # if [ "$(ls -A ${slice_folder})" ]; then
        #     IMGS=( ${p}${img_fld}/${s}/*)
        #     for i in $(seq 0 $(( ${#IMGS[*]} - 1 )));
        #     do
            
        #         echo ${IMGS[${i}]}
        #         ${dcm2niix_fld}dcm2niix -i n -b n -m n -s y -o "${slice_output}/" -f "${i}" -9 -z y "${IMGS[${i}]}"
        done
	
    done

done
