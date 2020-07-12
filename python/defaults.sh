export CG_NAS="/media/McVeighLab/"

export CG_MAIN="/media/McVeighLabSuper/projects/Zhennong/Volume_Rendering/"
#export CG_MAIN="/Data/McVeighLabSuper/projects/Zhennong/Volume_Rendering/"

#export CG_RAW_DIR_ZC="/Data/McVeighLabSuper/projects/Zhennong/AI/AI_datasets/"
#export CG_BASE_DIR_ZC="/Data/McVeighLabSuper/projects/Zhennong/AI/CNN/" 
export CG_RAW_DIR_ZC="/media/McVeighLabSuper/projects/Zhennong/AI/AI_datasets/"
export CG_BASE_DIR_ZC="/media/McVeighLabSuper/projects/Zhennong/AI/CNN/" 

export CG_CODE_DIR="/Experiment/Documents/Volume_Rendering_by_DL/"

export CG_HYPERTUNE_DIR="${CG_BASE_DIR_ZC}hyperparameters_tuning/"

export CG_OCTOMORE_DIR_ZC="/Experiment/Documents/Data"
#export CG_OCTOMORE_DIR_ZC="/home/cnn/Documents/Data"

# for resample that can only be run in octomore local terminal (in virtual environment)
export CG_RESAMPLE_ZC="/home/cnn/Documents/Resample_Data"
#export CG_RESAMPLE_ZC="/Experiment/Documents/Resample_Data"

# other data in octomore 
export CG_OTHER_DIR="/home/cnn/Documents/Other_data/"

# parameters
export CUDA_VISIBLE_DEVICES="1"

export CG_NUM_CLASSES=10 #10 for Left-sided, 14 for Right-sided, 2 for LV only, 3 for LA + LV

export CG_SPACING=1.0

export CG_FEATURE_DEPTH=8
# 8 is up to 2^8 = 256, 9 is up to 512 and 10 is up to 1024

export CG_EPOCHS=50

export CG_SEED=0

export CG_LR_EPOCHS=26

export CG_NUM_PARTITIONS=5

export CG_BATCH_SIZE=1

export CG_XY_RANGE="0.1"   #0.1

export CG_ZM_RANGE="0.1"  #0.1

export CG_RT_RANGE="10"   #15
