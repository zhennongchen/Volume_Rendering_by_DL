
# System
import os

# Third Party

# Internal

class FileSystem:
    def __init__(self,
                 _patient_directory,
                 _model_directory,
                ):
        self.patient_directory = _patient_directory
        self.model_directory = _model_directory

    def model_suffix(self, batch):
        """ Get the model suffix. """
        return 'batch_{}'.format(batch)
    
    
    def partitions(self, filename, path = True,New_test=False):
        """ Get list of patients in each partition."""
        if New_test == False:
            n = filename
        elif New_test == 'train':
            n = 'partitions_train_F.npy'
        else:
            n = 'partitions_test_F.npy'
        return n if not path else os.path.join(self.model_directory, n)
    
    
    def img(self, num):
        """ """
        return "{}.nii.gz".format(num)

    
