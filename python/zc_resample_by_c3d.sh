#!/usr/bin/env bash
# run in docker c3d

half=2
minus=1

# Include settings and ${CG_*} variables.
. defaults.sh

# Get a list of patients.
patients=(/Data/McVeighLabSuper/projects/Zhennong/AI/Zhennong_WMA_Movie_dataset/CVC19111*)
#patients=(/Data/McVeighLabSuper/wip/zhennong/nii-images/Normal/* ) 
#patients+=(/Data/McVeighLabSuper/wip/zhennong/nii-images/Normal/CVC2006300933 )
#patients=(/Data/McVeighLabSuper/wip/zhennong/predicted_seg/Normal/* ) 
#patients+=(/Data/McVeighLabSuper/wip/zhennong/predicted_seg/Abnormal/* ) 
img_or_seg=0 # 1 is image, 0 is seg

if ((${img_or_seg} == 1))
then
img_folder="img-nii"
else
img_folder="seg-manual"
fi

for p in ${patients[*]};
do

# Print the current patient.
  echo ${p} 
  
  # assert whether dcm image exists
  if ! [ -d ${p}/${img_folder} ] || ! [ "$(ls -A  ${p}/${img_folder})" ];then
    echo "no image/seg"
    continue
  fi

  # set output folder
  
  if ((${img_or_seg} == 1))
  then
  o_dir=${p}/img-nii-0.625
  else
  o_dir=${p}/seg-manual-1.5
  fi

  echo ${o_dir}
  mkdir -p ${o_dir}
  
  # calculate the length of img_list and get es time frame
  IMGS_all=(${p}/${img_folder}/0.nii.gz)
  length=${#IMGS_all[@]}
  z=$((length / half)) 
  ES=$((z - minus))


  IMGS=(${p}/${img_folder}/*.nii.gz)
  #IMGS+=(${p}/${img_folder}/${ES}.nii.gz)

  for i in $(seq 0 $(( ${#IMGS[*]} - 1 )));
  do
  #echo ${IMGS[${i}]}
    i_file=${IMGS[${i}]}
    echo ${i_file}
    o_file=${o_dir}/$(basename ${i_file})

    if [ -f ${o_file} ];then
      echo "already done this file"
      continue
    else
      if ((${img_or_seg} == 1))
      then
        c3d ${i_file} -interpolation Cubic -resample-mm 0.625x0.625x0.625mm -o ${o_file}
      else
        c3d ${i_file} -interpolation NearestNeighbor -resample-mm 1.5mmx1.5mmx1.5mm -o ${o_file}
      fi
    fi   
  done
done


