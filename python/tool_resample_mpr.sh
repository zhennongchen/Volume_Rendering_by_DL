#!/usr/bin/env bash
########################################
# run at mcveighlab-octomore, save locally at octomore, need to transfer back to NAS
# Currently can only run in octomore terminal, cd Developer, . .py35/bin/activate to activate the Virtual environment
# screen to have a new screen, screen -r to retrieve the previous
# ctrl +A +D to quit 
#######################################

. ./main_step1_defaults.sh

set -o nounset
set -o errexit
set -o pipefail

out_size=480;
out_spac=0.625;
out_value=-2047;

dv_utils_fld="/home/cnn/Documents/Repos/dv-commandline-utils/bin/"


# patient list
PATIENT=(/media/McVeighLabSuper/wip/zhennong/MPR/Abnormal/*/)
PATIENT+=(/media/McVeighLabSuper/wip/zhennong/MPR/Normal/*/)
SAVE_DIR="/media/local_storage/Zhennong/VR_Data_Resample_MPR/"


SLICE[0]=2C
SLICE[1]=3C
SLICE[2]=4C
SLICE[3]=SAX


# Folder where you want to put the reslice
fld_prefix=mpr-nii-0.625

# Folder where the volumes to be resliced reside
input_fld=img-nii-0.625

# Folder where the mpr nii sits with direction info
mpr_fld=mpr-nii

for p in ${PATIENT[*]};
do
    patient_id=$(basename ${p})
    patient_class=$(basename $(dirname ${p}))
    echo ${p}${mpr_fld}
    if  [ ! -d ${p}${mpr_fld} ];then
        echo "no mpr image"
        continue
    fi

    save_folder=${SAVE_DIR}${patient_class}/${patient_id}/${fld_prefix}
    echo ${save_folder}
    mkdir -p ${SAVE_DIR}${patient_class}
    mkdir -p ${SAVE_DIR}${patient_class}/${patient_id}
    mkdir -p ${save_folder}

    IMGS=(/media/McVeighLabSuper/wip/zhennong/nii-images/${patient_class}/${patient_id}/${input_fld}/0.nii.gz) ###CHANGE IF MPR HAS A SERIES
    echo ${IMGS[0]}

    for i in $(seq 0 $(( ${#IMGS[*]} - 1 )));
    do

        # For each volume, lets look at each MPR slice

        for s in ${SLICE[*]};
        do

            slc_save_folder=${save_folder}/${s}
            mkdir -p ${slc_save_folder}

            REF=( ${p}${mpr_fld}/${s}/* )

            img_name=$(basename ${IMGS[${i}]}  .nii.gz);
            output_file=${slc_save_folder}/${img_name}.nii.gz
        
            #echo ${IMGS[${i}]}
            #echo ${REF[0]}
            echo $output_file

            if [ -f ${output_file} ];then
                echo "already done"
                continue
            else
                ${dv_utils_fld}dv-resample-from-reference --input-image ${IMGS[${i}]} --reference-image ${REF[0]} --output-image $output_file --output-size $out_size --output-spacing $out_spac --outside-value $out_value
            fi
        done
    done
done