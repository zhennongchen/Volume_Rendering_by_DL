#!/usr/bin/env bash
########################################
# run at mcveighlab-octomore, save locally at octomore, need to transfer back to NAS
#######################################

. defaults.sh
. 00-all-both-1-5-spacing.sh

set -o nounset
set -o errexit
set -o pipefail


# out_size=160;
# out_spac=1.5;
out_value=-2047;

dv_utils_fld="/home/cnn/Documents/Repos/dv-commandline-utils/bin/"


readonly PATIENTS=(${CG_INPUT_DIR}ucsd_toshiba/028/ ) 
readonly TARGET_DIRS=(${CG_RAW_DIR}ucsd_toshiba/028/ )

# Folder where the volumes to be resampled reside
input_fld=seg-nii-sm

# Folder where the reference (original image) is saved
ref_fld=seg-nii

# folder where the output is saved
output_fld=seg-nii

for i_dir in ${PATIENTS[*]};
do

# Print the current patient.
  echo ${i_dir} 
    
  # set output folder
  patient_class=$(basename $(dirname ${i_dir}))
  patient_id=$(basename ${i_dir})
  echo ${patient_class}
  echo ${patient_id}

  o_dir=${CG_OTHER_DIR}${patient_class}/${patient_id}/${output_fld}/
  echo ${o_dir}
  mkdir -p ${CG_OTHER_DIR}$(basename $(dirname ${i_dir}))/
  mkdir -p ${CG_OTHER_DIR}$(basename $(dirname ${i_dir}))/$(basename ${i_dir})/
  mkdir -p ${CG_OTHER_DIR}$(basename $(dirname ${i_dir}))/$(basename ${i_dir})/${output_fld}/

  IMGS=(${i_dir}${input_fld}/*.nii.gz) ###CHANGE IF MPR HAS A SERIES
  for i in $(seq 0 $(( ${#IMGS[*]} - 1 )));
  do
    echo ${IMGS[${i}]}

    REF=${CG_RAW_DIR}${patient_class}/${patient_id}/${ref_fld}/0.nii.gz
    echo ${REF}

    img_name=$(basename ${IMGS[${i}]}  .nii.gz);
    o=${o_dir}${img_name}.nii.gz
    echo ${o}

    ${dv_utils_fld}dv-resample-from-reference --input-image ${IMGS[${i}]} --reference-image ${REF} --output-image ${o} --outside-value $out_value

  done





done