# System
import os

class Experiment():

  def __init__(self):

    self.main_dir = os.environ['CG_MAIN_DIR']
  
    self.patient_dir = os.environ['CG_PATIENT_DIR']

    self.model_dir = os.environ['CG_MODEL_DIR']
  
    # Dimension of padded input, for training.
    self.dim = (int(os.environ['CG_CROP_X']), int(os.environ['CG_CROP_Y']), int(os.environ['CG_CROP_Z']))
  
    # Seed for randomization.
    self.seed = int(os.environ['CG_SEED'])
  
    # Number of Classes (Including Background)
    self.num_classes = int(os.environ['CG_NUM_CLASSES'])
    # Whether relabel of LVOT is necessary
    if int(os.environ['CG_RELABEL_LVOT']) == 1:
      self.relabel_LVOT = True
    else:
      self.relabel_LVOT = False
      
  
    # UNet Depth
    self.unet_depth = 5
  
    # Depth of convolutional feature maps
    self.conv_depth_multiplier = int(os.environ['CG_CONV_DEPTH_MULTIPLIER'])
    self.ii = int(os.environ['CG_FEATURE_DEPTH'])
    self.conv_depth = [2**(self.ii-4),2**(self.ii-3),2**(self.ii-2),2**(self.ii-1),2**(self.ii),2**(self.ii),2**(self.ii-1),2**(self.ii-2),
                      2**(self.ii-3),2**(self.ii-4),2**(self.ii-4)]
    #self.conv_depth = [16, 32, 64, 128, 256, 256, 128, 64, 32, 16, 16]
    self.conv_depth = [self.conv_depth_multiplier*x for x in self.conv_depth]
  
    assert(len(self.conv_depth) == (2*self.unet_depth+1))
  
    # How many images should be processed in each batch?
    self.batch_size = int(os.environ['CG_BATCH_SIZE'])
  

    # SPACING:
    self.spacing = float(os.environ['CG_SPACING'])
