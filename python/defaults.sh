## define GPU
export CUDA_VISIBLE_DEVICES="1"


## define parameters for 2D/3D U-Net segmentation
export CG_SEED=0

export CG_SEG_NUM_CLASSES=4 
export CG_RELABEL_LVOT=1

export CG_SEG_BATCH_SIZE=1 # for 3D segmentation prediction

export CG_CROP_X=160 # for 3D segmentation prediction
export CG_CROP_Y=160 # for 3D segmentation prediction
export CG_CROP_Z=96 # for 3D segmentation prediction

export CG_CONV_DEPTH_MULTIPLIER=1 # for U-NET
export CG_FEATURE_DEPTH=8 # for U-NET

## define parameters for AI detection from Volume rendering data
export CG_NUM_PARTITIONS=5


## Folders
export CG_NAS_MAIN_DIR="/Data/McVeighLabSuper/wip/zhennong/"
export CG_NAS_IMAGE_DATA_DIR="/Data/McVeighLabSuper/wip/zhennong/nii-images/"
# enter the name of folder where you save the trained deep learning model 
export CG_NAS_PRESAVED_MODEL_DIR="/Data/McVeighLabSuper/projects/Zhennong/AI/CNN/all-classes-all-phases-data-1.5/" 
export CG_FC_MAIN_DIR="/Data/ContijochLab/workspaces/zhennong/Volume_Rendering_AI_detection/"
export CG_LOCAL_DIR="/Data/local_storage/Zhennong/Video_Data/Volume_Rendering_Movies_avi/"





