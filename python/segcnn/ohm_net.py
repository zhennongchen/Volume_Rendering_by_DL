# Third Party
from keras.models import Model
from keras.optimizers import SGD, RMSprop, Adam
from keras.regularizers import l2, l1, l1_l2
from keras.initializers import Orthogonal
from keras.layers.core import Activation
from keras.layers.normalization import BatchNormalization
from keras.layers import Input, \
                         Conv1D, Conv2D, Conv3D, \
                         MaxPooling1D, MaxPooling2D, MaxPooling3D, \
                         UpSampling1D, UpSampling2D, UpSampling3D, \
                         Reshape, Flatten, Dense
from keras.layers.merge import concatenate, multiply
from keras.engine import Layer
from keras import backend as K
import numpy as np
import tensorflow as tf

import dvpy as dv
import dvpy.tf

# Internal
import segcnn.config as cg
from segcnn.spatial_transformer_network import STN

weight_decay = 1e-4
conv_depth=128

#
from tensorflow.python.framework import ops

#@ops.RegisterGradient("FloorMod")
#def _mod_grad(op, grad):
#    x, y = op.inputs
#    gz = grad
#    x_grad = gz
#    y_grad = tf.reduce_mean(-(x // y) * gz, reduction_indices=[0], keep_dims=True) 
#    return x_grad, y_grad
#
#def wrapped_phase_loss_degrees(y_true, y_pred):
##    diff = tf.abs(y_pred - y_true)
##    diff_wrap = tf.constant(0.0)
##    diff_wrap -= tf.multiply(tf.cast(tf.greater(diff, tf.constant(180.0)), 'float32'), tf.constant(360.0))
##    diff_wrap += tf.multiply(tf.cast(tf.less_equal(diff, tf.constant(180.0)), 'float32'), tf.constant(360.0))
##    if tf.greater(diff, tf.constant(180.0)): diff -= tf.constant(360.0)
##    if tf.less_equal(diff, tf.constant(-180.0)): diff += tf.constant(360.0)
#    diff = tf.floormod(y_pred - y_true + tf.constant(180.0), 
#           tf.multiply(tf.ones_like(y_true),tf.constant(360.0))) - tf.constant(180.0)
#    return K.mean(K.square(diff), axis = -1)


class Categorical_Crossentropy_Layer(Layer):
    def __init__(self, **kwargs):
        super(Categorical_Crossentropy_Layer, self).__init__(**kwargs)

    def Customized_Crossentropy(self, inputs):
        y_true, y_pred = inputs
        y_true = tf.cast(tf.greater_equal(y_true, tf.constant(0.5)), 'float32')
        ##  train or not
        num_batch = tf.cast(tf.shape(y_true)[0], 'int32')
        mask = np.zeros((cg.dim // cg.downsampling_factor,)*2 + (cg.num_classes,))
        mask[32:-32, 32:-32, :] = 1.0
        mask_tensor = K.variable(mask)
        mask_tensor = tf.expand_dims(mask_tensor, 0)  # 1 x w x h 
        mask_tensor = tf.tile(mask_tensor, tf.stack([num_batch, 1, 1, 1]))
        w = tf.cast(tf.greater_equal(tf.reduce_sum(tf.multiply(y_true, mask_tensor)), tf.constant(0.5*64*64)), 'float32')
        ##
        return tf.multiply(K.categorical_crossentropy(y_pred, y_true), w)
        
    def compute_output_shape(self, input_shape):
        # Batch Size, Width, Height, Channels
        return input_shape[0][0], input_shape[0][1], input_shape[0][2]
    
    def call(self, x, mask = None):
        return self.Customized_Crossentropy(x)


class Categorical_Crossentropy_Acc_Layer(Layer):
    def __init__(self, **kwargs):
        super(Categorical_Crossentropy_Acc_Layer, self).__init__(**kwargs)

    def Customized_Crossentropy_Acc(self, inputs):
        y_true, y_pred = inputs
        return K.cast(K.equal(K.argmax(y_true, axis=-1),
                              K.argmax(y_pred, axis=-1)),
                              K.floatx())
        
    def compute_output_shape(self, input_shape):
        # 1,
        return  input_shape[0][0], input_shape[0][1], input_shape[0][2]
                 
    def call(self, x, mask = None):
        return self.Customized_Crossentropy_Acc(x)
    

class Mean_Square_Error_Layer(Layer):
    def __init__(self, **kwargs):
        super(Mean_Square_Error_Layer, self).__init__(**kwargs)

    def MSE(self, inputs):
        y_true, y_pred = inputs
        o = tf.square(y_true - y_pred)
        return tf.reduce_sum(o, axis= -1)
        
    def compute_output_shape(self, input_shape):
        # Batch Size, Width, Height, Channels
        return input_shape[0][0], input_shape[0][1], input_shape[0][2]
    
    def call(self, x, mask = None):
        return self.MSE(x)


class Input_Normalization_Layer(Layer):
    def __init__(self, **kwargs):
        super(Input_Normalization_Layer, self).__init__(**kwargs)

    def compute_output_shape(self, input_shape):
        # 1,
        return  input_shape
                 
    def call(self, x, mask = None):
        mu = K.mean(x, [1,2], keepdims = True)
        std = K.std(x, [1,2], keepdims = True)
        return (x-mu)/std

def dummy_loss(y_true, y_pred):
    return tf.multiply(y_true, y_pred)


def mat_dummy_loss(y_true, y_pred):
    loss_weights = tf.constant(0.0)
    y_pred = tf.multiply(y_pred, loss_weights)
    return tf.multiply(y_true, y_pred)


def masked_mean_square_error(y_true, y_pred):
    num_batch = tf.cast(tf.shape(y_true)[0], 'int32')
    mask = np.zeros((cg.dim, cg.dim, 1))
    mask[64:-64, 64:-64, 0] = 1.0
    mask_tensor = K.variable(mask)
    mask_tensor = tf.expand_dims(mask_tensor, 0)  # 1 x w x h x 3
    mask_tensor = tf.tile(mask_tensor, tf.stack([num_batch, 1, 1, 1]))
    return K.mean(K.square(tf.multiply(y_pred - y_true, mask_tensor)), axis=-1)


def masked_mean_square_error_zoom(y_true, y_pred):
    num_batch = tf.cast(tf.shape(y_true)[0], 'int32')
    mask = np.zeros((cg.dim // cg.downsampling_factor, 
                     cg.dim // cg.downsampling_factor, 1))
    mask[16:-16, 16:-16, 0] = 1.0
    mask_tensor = K.variable(mask)
    mask_tensor = tf.expand_dims(mask_tensor, 0)  # 1 x w x h x 3
    mask_tensor = tf.tile(mask_tensor, tf.stack([num_batch, 1, 1, 1]))
    return K.mean(K.square(tf.multiply(y_pred - y_true, mask_tensor)), axis=-1)


def my_init(shape, dtype=None):
    bias = np.ones(1,)
    return  K.variable(value = bias)   


def get_ohm_net(dim, conv_depth, hourglass_depth, num_output_classes = cg.num_classes, input_channels = 1, train = True):

    ##
    ## Inputs
    ##
    gt_matrix = []
    gt_matrix += [Input((2,), name = 'mat_translation')]
    gt_matrix += [Input((1,), name = 'mat_rotation')]
    gt_matrix += [Input((1,), name = 'mat_scaling')]

    model_inputs = []
    model_inputs += [Input((dim, dim, input_channels), name = 'image')]
    model_inputs += [Input((dim, dim, input_channels), name = 'image_cp')]
    model_inputs += gt_matrix

    train_outputs = []
    predict_outputs = []

    # image translation loss    
    input_true_translated = STN(downsample_factor=1.0, transform_type= 'translation', 
                                name='true_inp_xy')([model_inputs[1], gt_matrix[0], gt_matrix[0], gt_matrix[0]])

    # image rotation loss
    input_true_rotated = STN(downsample_factor=1.0, transform_type='rotation',
                             name = 'true_inp_rt')([model_inputs[1], gt_matrix[0], gt_matrix[1], gt_matrix[1]])

    # image sclaing loss    
    input_true_scaled = STN(downsample_factor=cg.downsampling_factor, transform_type='uniform_scale',
                            name = 'true_inp_zm')([model_inputs[1], gt_matrix[0], gt_matrix[1], gt_matrix[2]])

    ##
    ## First UNet
    ##

    unet1_pool5, _, unet1_seg_pred = get_unet(dim, num_output_classes, conv_depth[0], 1)(model_inputs[0])
    
    train_outputs += [unet1_seg_pred]
    predict_outputs += [unet1_seg_pred]
    ##
    ## STN
    ##
    
    pool5_flat = Flatten()(unet1_pool5)
    
    # Loc Networks.
    pool5_dense1 = Dense(384, 
                          kernel_initializer=Orthogonal(gain=1.0),
                          kernel_regularizer = l2(weight_decay),
                          activation = 'relu',name = 'loc')(pool5_flat)
                          
    # translation matrix loss
    stn_translation = Dense(3, 
                      kernel_initializer=Orthogonal(gain= 1e-1),
                      kernel_regularizer = l2(weight_decay),
                      name = 'mat_xy')(pool5_dense1)
    
    # rotation matrix loss
    stn_rotation = Dense(1, 
                         kernel_initializer=Orthogonal(gain= 1e-1),
                         kernel_regularizer = l2(weight_decay),
                         name = 'mat_rt')(pool5_dense1)
    rotation_loss = dvpy.tf.wrapped_phase_difference_loss
    
    # scaling matrix loss
    stn_scaling = Dense(1, 
                        kernel_initializer=Orthogonal(gain= 1e-1),
                        bias_initializer=my_init,
                        kernel_regularizer = l2(weight_decay),
                        name = 'mat_zm')(pool5_dense1)

    train_outputs += [stn_translation]
    train_outputs += [stn_rotation]
    train_outputs += [stn_scaling]
    
    predict_outputs += [stn_translation]
    predict_outputs += [stn_rotation]
    predict_outputs += [stn_scaling]
    
    # image translation loss    
    input_pred_translated = STN(downsample_factor=1.0, transform_type= 'translation', 
                           name='pred_inp_xy')([model_inputs[1], stn_translation, stn_translation, stn_translation])
    
    # image rotation loss
    input_pred_rotated = STN(downsample_factor=1.0, transform_type='rotation',
                        name = 'pred_inp_rt')([model_inputs[1], stn_translation, stn_rotation, stn_rotation])
    
    # image sclaing loss    
    input_pred_scaled = STN(downsample_factor=cg.downsampling_factor, transform_type='uniform_scale',
                       name = 'pred_inp_zm')([model_inputs[1], stn_translation, stn_rotation, stn_scaling])

    predict_outputs += [input_pred_scaled]
    current_input = input_pred_scaled
    
    if hourglass_depth > 0:
        
        model_inputs  += [Input((dim, dim, num_output_classes), name = 'output_mask')]
        
        # image sclaing loss    
        mask_scaled = STN(downsample_factor=cg.downsampling_factor, transform_type='uniform_scale',
                      name='pred_mask_zm')([model_inputs[-1], stn_translation, stn_rotation, stn_scaling])
        
        predict_outputs += [mask_scaled]
        ##
        ## Define Ground Truth for All Subsequent UNets
        ##
        for i in range(2, hourglass_depth+2):
            
            _, current_input, seg_pred = get_unet(dim // cg.downsampling_factor, num_output_classes, conv_depth[i - 1], i)(current_input)
            predict_outputs += [seg_pred]
            train_outputs += [Categorical_Crossentropy_Layer(name = 'seg%d_zm'%(i))([mask_scaled, seg_pred])]
            train_outputs += [Categorical_Crossentropy_Acc_Layer(name = 'seg%d_zm_acc'%(i))([mask_scaled, seg_pred])]
    
    ##
    ## Compile Model
    ##
    
    if train == True:
        train_outputs += [Mean_Square_Error_Layer(name = 'translation_mse')([input_true_translated, input_pred_translated])]
        train_outputs += [Mean_Square_Error_Layer(name = 'rotation_mse')([input_true_rotated, input_pred_rotated])]
        train_outputs += [Mean_Square_Error_Layer(name = 'scaling_mse')([input_true_scaled, input_pred_scaled])]
        
        model = Model(inputs = model_inputs,
                      outputs = train_outputs)
        opt = Adam(lr = 1e-3)
        
        dummy_losses = {'seg%d_zm'%(i) : dummy_loss for i in range(2, hourglass_depth + 2)}
        dummy_acc = {'seg%d_zm_acc'%(i) : dummy_loss for i in range(2, hourglass_depth + 2)}
        dummy_zooms = {'seg%d_zm'%(i) : 1.0 for i in range(2, hourglass_depth + 2)}
        
        losses = {'img_sg1': 'categorical_crossentropy',
                  'mat_xy': 'mse',
                  'mat_zm': 'mse',
                  'mat_rt': rotation_loss,
                  'translation_mse': dummy_loss,
                  'rotation_mse': dummy_loss,
                  'scaling_mse': dummy_loss,
                  }
        losses.update(dummy_losses)  #???
        losses.update(dummy_acc)
        losses_weights = {'img_sg1' : 100.0, 
                          'mat_xy' : 100.0, 
                          'mat_rt' : 50.0,
                          'mat_zm' : 100.0,
                          'translation_mse' : 0.1,
                          'rotation_mse' : 0.1,
                          'scaling_mse' : 0.1,
                         }
        losses_weights.update(dummy_zooms)
        
        model.compile(optimizer= opt, 
                  loss= losses, 
                  metrics= {'img_sg1': 'acc'},
                  loss_weights = losses_weights)
        
    else:
        
        predict_outputs += gt_matrix
        predict_outputs += [input_true_scaled]
        
        model = Model(inputs = model_inputs,
                      outputs = predict_outputs)
    
    return model

