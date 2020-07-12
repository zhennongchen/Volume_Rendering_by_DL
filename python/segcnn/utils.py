# System
import os

# Third Party
from keras.callbacks import Callback
from keras.utils.np_utils import to_categorical
import numpy as np
import nibabel as nb
import pandas as pd
import pylab as plt
from PIL import Image
import scipy.ndimage.interpolation as itp
from scipy.ndimage.measurements import center_of_mass

# Internal
import dvpy as dv
import segcnn

cg = segcnn.Experiment()
fs = segcnn.FileSystem(cg.base_dir, cg.data_dir,cg.hyper_dir)

def in_adapt(x, target = cg.dim):
  x = nb.load(x).get_data()
  x = dv.crop_or_pad(x, target)
  x = np.expand_dims(x, axis = -1)
  return x

def out_adapt_raw(x, target = cg.dim, n = cg.num_classes):
  x = nb.load(x).get_data()
  x[x >= n] = 0
  x = dv.crop_or_pad(x, target)
  return x

def out_adapt(x, target = cg.dim, n = cg.num_classes):
  return dv.one_hot(out_adapt_raw(x, target), n)

def get_list_of_array_indices(dimension):
  ax = np.linspace(0, dimension - 1, dimension)
  (gx, gy) = np.meshgrid(ax, ax)
  gx = gx.flatten()
  gy = gy.flatten()
  return np.array([gx, gy]).transpose()

def normalize_image(x, mu = None, sd = None):
    if mu is None: mu = np.mean(x)
    if sd is None: sd = np.std(x)
    return (x - mu) / sd

def step_decay(epoch, step = cg.lr_epochs, initial_power = -3):
    '''
    The learning rate begins at 10^initial_power,
    and decreases by a factor of 10 every step epochs.
    '''
    num =  epoch // step
    lrate=10**(initial_power - num)
    print('Learning rate for epoch {} is {}.'.format(epoch+1, 1.0*lrate))
    return np.float(lrate)

class loss_history(Callback):
    def on_train_begin(self, logs={}):
        self.train_losses = []
        self.train_accuracies = []
        self.val_losses = []
        self.val_accuracies = []

    def on_batch_end(self, batch, logs={}):
        self.train_losses.append(logs.get('loss'))
        self.train_accuracies.append(logs.get('acc'))

    def on_epoch_end(self, epoch, logs={}):
        plt.plot(range(len(self.train_losses)),
                              self.train_losses, '-', label = 'Train_Loss')
        plt.plot(range(len(self.train_accuracies)),
                             self.train_accuracies, '-', label = 'Train_Accuracy')
        plt.xlabel('Time')
        plt.ylabel('Loss and Accuracy')
        plt.savefig(os.path.join(cg.data_dir, 'train_process.png'))
        pd.DataFrame({'Train_Loss':self.train_losses,'Train_Accuracy':self.train_accuracies}).to_csv(os.path.join(cg.data_dir, 'train_loss.csv'))
        plt.close()

        self.val_losses.append(logs.get('val_loss'))
        self.val_accuracies.append(logs.get('val_acc'))
        plt.plot(range(len(self.val_losses)), self.val_losses, '-', label = 'Validation_Loss')
        plt.plot(range(len(self.val_accuracies)), self.val_accuracies, '-', label = 'Validation_Accuracy')
        plt.xlabel('Time')
        plt.ylabel('Loss and Accuracy')
        plt.savefig(os.path.join(cg.data_dir, 'validation_process.png'))
        pd.DataFrame({'Validation_Loss':self.val_losses,'Validation_Accuracy':self.val_accuracies}).to_csv(os.path.join(cg.data_dir, 'validation_loss.csv'))

def calculate_meanIOU(y_true, y_pred, background = None):
    IoU = 0
    classes = set(np.unique(y_true))
    if background is not None: classes.remove(background)

    for i in classes:
        y_true_bin = np.asarray(y_true == i, dtype = 'float32')
        y_pred_bin = np.asarray(y_pred == i, dtype = 'float32')
        Intersection = np.sum(y_true_bin * y_pred_bin)
        Union = np.sum(y_true_bin) + np.sum(y_pred_bin) - Intersection
        IoU += Intersection / (Union + 10e-5)
    return IoU / len(classes)


def calculate_img_meanIOU(y_true, y_pred, background = None):
    nb_cases, w, h = y_true.shape
    IoU = np.zeros((nb_cases,1))
    total = w * h
    for i in range(nb_cases):
        classes = set(np.unique(y_true[i]))
        if background is not None:
            classes.remove(background)
            total_bg = np.sum(np.array(y_true[i] == background, dtype = 'int'))
            total_fg = total - total_bg
            assert(total >= total_fg)
        for j in classes:
            y_true_bin = np.asarray(y_true[i] == j, dtype = 'float32')
            y_pred_bin = np.asarray(y_pred[i] == j, dtype = 'float32')
            Intersection = np.sum(y_true_bin * y_pred_bin)
            Union = np.sum(y_true_bin) + np.sum(y_pred_bin) - Intersection
            weight = np.sum(np.array(y_true[i] == j, dtype = 'int')) / total_fg
            IoU[i] += Intersection / (Union + 10e-5) * weight
    return IoU

def calculate_pixelacc(y_true, y_pred, image_level = False):
    nb_cases, w, h = y_true.shape
    img_pixelacc = np.zeros((nb_cases, 1))
    for i in range(nb_cases):
        binary = np.asarray(y_true[i] == y_pred[i], dtype = 'float32')
        pos = np.sum(binary)
        tot = w * h
        img_pixelacc[i] = pos / tot

    if image_level is True:
        return img_pixelacc
    else:
        return np.mean(img_pixelacc)

# =============================================================================
# TODO:
# path to the data needs to be consistaent.
def read_data_flow(path):
    c = nb.load(path).get_data()
    d1 = np.absolute(c)
    d2 = np.angle(c)
    return d1, d2

def read_label_flow(path):
    c = nb.load(path).get_data()
    x = np.expand_dims(np.imag(c), axis = -1)
    y = np.expand_dims(np.real(c), axis = -1)
    label = np.concatenate([x, y], axis = -1)
    return label
# =============================================================================

def model_to_dictionary(model):
  return {layer.name : layer for layer in model.layers[1:]}
