#!/usr/bin/env bash

# Lastest version of resampling for anistropic resolution
# manually define output spacing and dimension

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


function RESAMPLE_anisotropic() {

  I_DIR=${1}
  O_DIR=${2}
  INTERPOLATION=${3}
  sx=${4}
  sy=${5}
  sz=${6}
  dx=${7}
  dy=${8}
  dz=${9}

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
                      --spacingx ${sx} \
                      --spacingy ${sy} \
                      --spacingz ${sz} \
                      --dimx ${dx} \
                      --dimy ${dy} \
                      --dimz ${dz} \
                      --interpolator ${INTERPOLATION}

    # #fi

  done

}

#readonly SPACINGS=(1.0 1.5 2.0)
#readonly SPACINGS=(0.5 1.0 1.5 2.5 3.0)
#readonly SPACINGS=(1.0 1.5 2.5 3.0)
readonly SPACINGX=0.390625
readonly SPACINGY=0.390625
readonly SPACINGZ=0.6250
readonly OUTSIZEX=512
readonly OUTSIZEY=512
readonly OUTSIZEZ=256


#for spacing in ${SPACINGS[*]};
#do
  #echo "Spacing: ${spacing}"

  # Loop over patients.
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
  RESAMPLE_anisotropic ${i_dir}img-nii-sm/ ${o_dir}img-nii/ 3 ${SPACINGX} ${SPACINGY} ${SPACINGZ} ${OUTSIZEX} ${OUTSIZEY} ${OUTSIZEZ}
  #RESAMPLE ${i_dir}seg-nii/ ${o_dir}seg-nii-sm/ 0 ${spacing}     

done

#done
