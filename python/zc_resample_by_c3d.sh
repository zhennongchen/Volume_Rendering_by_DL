#!/usr/bin/env bash
# run in docker c3d

# Include settings and ${CG_*} variables.
. defaults.sh

# Get a list of patients.
main_dir="/Data/McVeighLabSuper/projects/Zhennong/Zhennong_CT_Data/"
readonly patients=(/Data/McVeighLabSuper/projects/Zhennong/AI/Zhennong_AN_dataset/* ) 
img_or_seg=1 # 1 is image, 0 is seg

if ((${img_or_seg} == 1))
then
img_folder="img-nii"
else
img_folder="seg-nii"
fi

for p in ${patients[*]};
do

# Print the current patient.
  echo ${p} 
    
  if ! [ -d ${p}/${img_folder} ] ;then
    echo "no image/seg"
    continue
  fi

  # set output folder
  
  if ((${img_or_seg} == 1))
  then
  o_dir=${p}/img-nii-1.5
  else
  o_dir=${p}/seg-nii-1.5
  fi

  echo ${o_dir}
  mkdir -p ${o_dir}
  

  # check whether already done
  if [ -d ${o_dir} ] && [ "$(ls -A  ${o_dir})" ] ;then
    echo "already done"
    continue
  else
    IMGS=(${p}/${img_folder}/*.nii.gz)
    for i in $(seq 0 $(( ${#IMGS[*]} - 1 )));
    do
        #echo ${IMGS[${i}]}
        i_file=${IMGS[${i}]}
        echo ${i_file}
        o_file=${o_dir}/$(basename ${i_file})
        
        
        if ((${img_or_seg} == 1))
        then
        c3d ${i_file} -interpolation Cubic -resample-mm 1.5x1.5x1.5mm -o ${o_file}
        else
        c3d ${i_file} -interpolation NearestNeighbor -resample-mm 1.5x1.5x1.5mm -o ${o_file}
        fi
        
    done
  fi
  

done


