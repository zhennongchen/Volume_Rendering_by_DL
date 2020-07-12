
# System
import os

# Third Party

# Internal

ALLOWED_IMAGE_LISTS={'ALL_SEGS', 'ALL_IMGS', 'ED_ES','ED_ES2','ALL_SEGS2','ED_ES_F','ED_ES_U','ED_ES_1.0','ED_ES_1.5','ED_ES_2.0'} 

class FileSystem:
    def __init__(self,
                 _base_directory,
                 _data_directory,
                 _hyper_directory,
                ):
        self.base_directory = _base_directory
        self.data_directory = _data_directory
        self.hyper_directory = _hyper_directory


    
    
    def model_suffix(self, batch):
        """ Get the model suffix. """
        return 'batch_{}'.format(batch)
    
    def model(self, batch,path = True):
        """ Get the name of/path to the model. """
        n = 'model_{}.hdf5'.format(self.model_suffix(batch))
        return n if not path else os.path.join(self.data_directory, n)
    
    def partitions(self, path = True,New_test=False):
        """ Get list of patients in each partition.
        New_test = true for the new partition process where we seperate the data into training and test """
        if New_test == False:
            n = 'partitions.npy'
        elif New_test == 'train':
            n = 'partitions_train_F.npy'
        else:
            n = 'partitions_test_F.npy'
        return n if not path else os.path.join(self.data_directory, n)

    
    def img_list(self, batch, list_type, path = True):
        """ """
        assert(list_type in ALLOWED_IMAGE_LISTS)
        n = 'img_list_{}.npy'.format(batch)
        
        return n if not path else os.path.join(self.data_directory, list_type, n)
        
    def seg_list(self, batch, list_type, path = True):
        """ """
        assert(list_type in ALLOWED_IMAGE_LISTS)
        n = 'seg_list_{}.npy'.format(batch)
        return n if not path else os.path.join(self.data_directory, list_type, n)
    
    def matrix_list(self, batch, list_type, path = True):
        """ """
        assert(list_type in ALLOWED_IMAGE_LISTS)
        n = 'matrix_list_{}.npy'.format(batch)
        return n if not path else os.path.join(self.data_directory, list_type, n)

        
    def img(self, num):
        """ """
        return "{}.nii.gz".format(num)

    def img_list_hyper(self, batch, list_type, path = True):
        """ """
        assert(list_type in ALLOWED_IMAGE_LISTS)
        n = 'img_list_{}.npy'.format(batch)
        
        return n if not path else os.path.join(self.hyper_directory, list_type, n)
        
    def seg_list_hyper(self, batch, list_type, path = True):
        """ """
        assert(list_type in ALLOWED_IMAGE_LISTS)
        n = 'seg_list_{}.npy'.format(batch)
        return n if not path else os.path.join(self.hyper_directory, list_type, n)
