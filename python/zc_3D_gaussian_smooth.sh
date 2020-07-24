#!/usr/bin/env bash
# run in docker c3d

readonly patients=(/Data/McVeighLabSuper/projects/Zhennong/AUH_patients/nii_files/* )


for p in ${patients[*]};
do
    echo ${p}
    patient_smooth_folder=$(dirname $(dirname ${p}))/nii_files_smooth/$(basename ${p})/
    #echo ${patient_smooth_folder}
    mkdir -p ${patient_smooth_folder}

    phases=(${p}/*)

    for phase in ${phases[*]};
    do
        phase_smooth_folder=${patient_smooth_folder}$(basename ${phase})/
        mkdir -p ${phase_smooth_folder}

        images=(${phase}/*.nii.gz)
        for i in ${images[*]};
        do
            echo ${i}
            outputfile=${phase_smooth_folder}$(basename ${i})
            
            c3d ${i} -smooth 0.638mm ${outputfile} #change the sigma here FWHM = 2.35sigma
            
            #c3d ${i} -smooth 0.425mm ${phase_smooth_folder}0.nii.gz
            #c3d ${i} -smooth 0.638mm ${phase_smooth_folder}0_0.6.nii.gz
            #c3d ${i} -smooth 0.851mm ${phase_smooth_folder}0_0.8.nii.gz
            

            done


        
        done

    done