## define parameters
export CUDA_VISIBLE_DEVICES="0"

export CG_NUM_CLASSES=4 
export CG_RELABEL_LVOT=1

export CG_SPACING=1.5

export CG_SEED=0

export CG_BATCH_SIZE=1

export CG_CROP_X=160
export CG_CROP_Y=160
export CG_CROP_Z=96

export CG_CONV_DEPTH_MULTIPLIER=1
export CG_FEATURE_DEPTH=8

# enter the name of main directory
export CG_MAIN_DIR="/Data/McVeighLabSuper/wip/zhennong/"

# enter the name of directory where you save the patient data
export CG_PATIENT_DIR="${CG_MAIN_DIR}nii-images/Abnormal/"

# enter the name of folder where you save the trained deep learning model 
export CG_MODEL_DIR="/Data/McVeighLabSuper/projects/Zhennong/AI/CNN/all-classes-all-phases-data-1.5/" 





