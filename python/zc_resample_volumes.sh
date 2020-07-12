#!/usr/bin/env bash

# Lastest version of resampling for anistropic resolution
# need to use /C++_code_for_resampling/specify_resolution_and_dimension_by_manual_input
# see instructions in that folder

# see dvResampleVolume.h for details

# Currently can only run in octomore terminal, cd Developer, . .py35/bin/activate to activate the Virtual environment
# If run in Docker: Docker_Resample_Laura, start the docker by start_docker_resample.sh

# Include settings and ${CG_*} variables.
. defaults.sh
. safe-bash.sh

# Get a list of patients.
readonly INPUT_DIRS=(${CG_INPUT_DIR}ucsd_toshiba/028/ ) 
readonly TARGET_DIRS=(${CG_RAW_DIR}ucsd_toshiba/028/ )

function RESAMPLE() {

  I_DIR=${1}
  O_DIR=${2}
  Target=${3}
  INTERPOLATION=${4}
 
  # target file
  t=${Target}0.nii.gz

  # Get a list of inputs.
  IMGS=( ${I_DIR}*.nii.gz )

  if [ "${#IMGS[*]}" -le 1 ];
  then
    return
  fi

  # Loop over the images.
  for i in ${IMGS[*]};
  do

    # Ensure that the output directory exists.
    echo ${O_DIR}
    mkdir -p ${O_DIR}

    # Create the name of the output.
    o=${O_DIR}$(basename ${i})

    # Resample if:
    # - The output doesn't exist.
    # - The input is newer than the output.
    #if [ "${i}" -nt "${o}" ]; then
    echo "resampling..."
    echo ${i}
    echo ${o}
    dv-resample-volume--input-image ${i} \
                      --output-image ${o} \
                      --target-size-image ${t} \
                      --interpolator ${INTERPOLATION}

    # #fi
  done
}

for i_dir in ${INPUT_DIRS[*]};
do

# Print the current patient.
  echo ${i_dir} 
    
  # set output folder
  #o_dir=${CG_RESAMPLE_DIR}$(basename $(dirname ${i_dir}))/$(basename ${i_dir})/
  o_dir=${CG_OTHER_DIR}$(basename $(dirname ${i_dir}))/$(basename ${i_dir})/
  echo ${o_dir}
  mkdir -p ${CG_OTHER_DIR}$(basename $(dirname ${i_dir}))/
  mkdir -p ${CG_OTHER_DIR}$(basename $(dirname ${i_dir}))/$(basename ${i_dir})/

  # # check whether already done
  # small_folder_img=${o_dir}img-nii-sm
  # small_folder_seg=${o_dir}seg-nii-sm
  # if [ -d ${small_folder_img} ] && [ "$(ls -A  ${small_folder_img})" ] &&  -d ${small_folder_seg} ] && [ "$(ls -A  ${small_folder_seg})" ];then
  #   echo "already done"
  #   continue
  # fi
  
  

  # when in Laura's docker, use 1 for volume image, 2 for segmentation
  # when in octomore local, use 3 for volume image, 0 for segmenation
  #RESAMPLE ${i_dir}img-nii-sm/ ${o_dir}img-nii/ 3 ${SPACINGX} ${SPACINGY} ${SPACINGZ}
  RESAMPLE ${i_dir}seg-pred/ ${o_dir}seg-nii/ ${TARGET_DIRS}seg-nii/ 0
done


