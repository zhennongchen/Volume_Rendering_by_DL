#!/usr/bin/env bash

# Lastest version of resampling for anistropic resolution
# define the output dimension + resolution from a target file

: '
The CCT volumes are too large to be trained on the network at their current resolution;
moreover, the input resolution is anisotropic, which is not ideal for training.
This script resamples all images and segmentations to a uniform, isotropic spacing,
dictated by the spacing defined in the experiment.

NOTES:

- Inputs come from {img,seg}-nii; outputs go in {img,seg}-nii-sm.

- The script takes quite a long time to run for all images; therefore, by default
it only runs on inputs which are newer than their corresponding resampled outputs.
To override this behavior, set `RUNALL` to `true`.
'

######### Run in Docker: Docker_Resample_Laura, start the docker by start_docker_resample.sh

# Include settings and ${CG_*} variables.
#. defaults.sh
. safe-bash.sh

# Get a list of patients.
readonly INPUT_DIRS=(${CG_INPUT_DIR}ucsd_pv/CVC1805021118/ ) 
readonly TARGET_DIRS=(${CG_RAW_DIR}ucsd_pv/CVC1805021118/ )


function RESAMPLE_anisotropic() {

  I_DIR=${1}
  O_DIR=${2}
  Target=${3}
  INTERPOLATION=${4}
  
  # target image
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
    dv-resample-volume --input-image ${i} \
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
  RESAMPLE_anisotropic ${i_dir}img-nii-sm/ ${o_dir}img-nii/ ${TARGET_DIRS}img-nii/ 3
  #RESAMPLE ${i_dir}seg-nii/ ${o_dir}seg-nii-sm/ 0 ${spacing}     

done


