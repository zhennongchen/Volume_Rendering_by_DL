from __future__ import absolute_import
from __future__ import division

import tensorflow as tf
from keras.engine import InputSpec, Layer
import keras.backend as K
# debug 
import pdb
import numpy as np
import segcnn.config as cg

# =============================================================================
#                     Spatial Transformer Layer
# =============================================================================
def _repeat(x, n_repeats):
    rep = tf.transpose(
        tf.expand_dims(tf.ones(shape=tf.stack([n_repeats, ])), 1), [1, 0])
    rep = tf.cast(rep, 'int32')
    x = tf.matmul(tf.reshape(x, (-1, 1)), rep)
    return tf.reshape(x, [-1])


def _interpolate(im, x, y, downsample_factor):
    # constants
    num_batch = tf.shape(im)[0]
    height = tf.shape(im)[1]
    width = tf.shape(im)[2]
    num_channels = tf.shape(im)[3]

    # need to convert to float.
    height_f = tf.cast(height, 'float32')
    width_f = tf.cast(width, 'float32')
    out_height = tf.cast(height_f // downsample_factor, 'int32')
    out_width = tf.cast(width_f // downsample_factor, 'int32')

    # clip coordinates to [-1, 1]    
    x = tf.clip_by_value(x, -1, 1)
    y = tf.clip_by_value(y, -1, 1)

    # scale coordinates from [-1, 1] to [0, width/height-1]
    x = (x + 1) * (width_f - 1) / 2
    y = (y + 1) * (height_f - 1) / 2

    # do sampling
    x0_f = tf.floor(x)
    y0_f = tf.floor(y)
    x1_f = x0_f + 1
    y1_f = y0_f + 1
    x0 = tf.cast(x0_f, 'int32')
    y0 = tf.cast(y0_f, 'int32')
    x1 = tf.cast(tf.minimum(x1_f, width_f-1), 'int32')
    y1 = tf.cast(tf.minimum(y1_f, height_f-1), 'int32')

    dim2 = width
    dim1 = width * height
    base = _repeat(tf.range(num_batch, dtype='int32') * dim1, out_height * out_width)
    base_y0 = base + y0 * dim2
    base_y1 = base + y1 * dim2
    idx_a = base_y0 + x0
    idx_b = base_y1 + x0
    idx_c = base_y0 + x1
    idx_d = base_y1 + x1

    # use indices to lookup pixels in the flat image and restore channels dim
    im_flat = tf.reshape(im, tf.stack([-1, num_channels]))
    Ia = tf.gather(im_flat, idx_a)
    Ib = tf.gather(im_flat, idx_b)
    Ic = tf.gather(im_flat, idx_c)
    Id = tf.gather(im_flat, idx_d)

    # and finally calculate interpolated values
    wa = tf.expand_dims(((x1_f - x) * (y1_f - y)), 1)  # ratio
    wb = tf.expand_dims(((x1_f - x) * (y - y0_f)), 1)
    wc = tf.expand_dims(((x - x0_f) * (y1_f - y)), 1)
    wd = tf.expand_dims(((x - x0_f) * (y - y0_f)), 1)
    output = tf.add_n([wa * Ia, wb * Ib, wc * Ic, wd * Id])
    return output


def _meshgrid(height, width):
    x_t_flat, y_t_flat = tf.meshgrid(tf.linspace(-1.0, 1.0, width), tf.linspace(-1.0, 1.0, height))
    ones = tf.ones_like(x_t_flat)
    grid = tf.concat(values=[x_t_flat, y_t_flat, ones], axis=0)
    return grid


def _transform(theta, conv_input, downsample_factor):
    # theta : transformation matrix of size batch_sz x 6
    # input : the feature maps that to be transformed.
    # in this code, I only wrote the tenforflow backend.
    num_batch = tf.shape(conv_input)[0]
    height = tf.shape(conv_input)[1]
    width = tf.shape(conv_input)[2]
    num_channels = tf.shape(conv_input)[3]

    theta = tf.reshape(theta, (-1, 2, 3))  # Reshape to batch_sz x 2 x 3
    height_f = tf.cast(height, 'float32')
    width_f = tf.cast(width, 'float32')

    out_height = tf.cast(height_f // downsample_factor, 'int32')
    out_width = tf.cast(width_f // downsample_factor, 'int32')

    # Generate the Target Grid Coordinates
    grid = _meshgrid(out_height, out_width)
    
    grid = tf.expand_dims(grid, 0)  # 1 x w x h x 3
    grid = tf.reshape(grid, [-1])  # flatten to into 1-D (wh3,)
    grid = tf.tile(grid, tf.stack([num_batch]))
    grid = tf.reshape(grid, tf.stack([num_batch, 3, -1]))

    # Transform the target grid back to the source grid, where original image lies.
    T_g = tf.matmul(theta, grid)
    x_s = tf.slice(T_g, [0, 0, 0], [-1, 1, -1])
    y_s = tf.slice(T_g, [0, 1, 0], [-1, 1, -1])
    x_s_flat = tf.reshape(x_s, [-1])
    y_s_flat = tf.reshape(y_s, [-1])

    # input : (bs, height, width, channels)
    input_transformed = _interpolate(conv_input, x_s_flat, y_s_flat, downsample_factor)

    output = tf.reshape(input_transformed,
                        (num_batch, out_height, out_width, num_channels))
    return output


class STN(Layer):
    '''
    Spatial Transformer Layer
    This file is highly based on [1]_, written by taoyizhi68.
    Though original code was based on Theano.
    Implements a spatial transformer layer as described in [2]_.
    Parameters
    ------------------------------------------------------------
    inputs : a list of [:class:`Layer` instance or a tuple]
    The layers feeding into this layer. 
    
    The list must have two entries with the first network being a 
    convolutional net and the second layer being the transformation matrices. 
    The first network should have output shape [batch_size, height, width, num_channels]. (tf mode)
    The output of the second network should be [batch_size, 6]. (Affine Transformation)

    downsample_factor : float
    A value of 1 will keep the original size of the image.
    Values larger than 1 will down sample the image. 
    Values below 1 will upsample the image.
    example image: height= 100, width = 200
    downsample_factor = 2
    output image will then be 50, 100
    ----------
    References
    ----------
    .. [1]  https://github.com/taoyizhi68/keras-Spatial-Transformer-Layer/blob/master/SpatialTransformer.py
    .. [2]  Spatial Transformer Networks
            Max Jaderberg, Karen Simonyan, Andrew Zisserman, Koray Kavukcuoglu
            Submitted on 5 Jun 2015
    '''

    def __init__(self, downsample_factor=1, transform_type=None, **kwargs):
        super(STN, self).__init__(**kwargs)
        self.downsample_factor = downsample_factor
        self.transform_type = transform_type

    def compute_output_shape(self, input_shape):
        # input dims are (bs, height, width, num_filters)
        # Scale height and width by downsample factor
        rows = input_shape[0][1]
        cols = input_shape[0][2]
        new_row = rows // self.downsample_factor
        new_col = cols // self.downsample_factor
        return (input_shape[0][0], new_row, new_col, input_shape[0][-1])

#    def call(self, x, mask=None):
#        # theta should be shape (batchsize, 6)
#        # see eq. (1) and sec 3.1 in ref [2]
#        # conv_input is the output feature maps that need to be transformed.
#        conv_input, theta = x
#        output = _transform(theta, conv_input, self.downsample_factor)
#        return output
    
    def call(self, x, mask=None):
        # theta should be shape (batchsize, 6)
        # see eq. (1) and sec 3.1 in ref [2]
        # conv_input is the output feature maps that need to be transformed.
        conv_input, theta_xy, theta_rt, theta_zm = x
        ones = tf.ones((tf.shape(theta_xy)[0],1))
        zeros = tf.zeros((tf.shape(theta_xy)[0],1))
        p_pi = tf.multiply(ones, tf.constant(np.pi))
        m_pi = tf.multiply(p_pi, tf.constant(-1.0))
        min_zm = tf.multiply(ones, tf.constant(0.3))
        
        def cp_rt(x):
            return tf.clip_by_value(x, m_pi, p_pi)
        
        def cp_zm(x):
            return tf.clip_by_value(x, min_zm, ones)
        
        if self.transform_type is None:
            tf.assert_equal(tf.shape(theta_xy)[1], 6)
            full_theta = theta_xy
            
        elif self.transform_type == 'translation':
            tf.assert_equal(tf.shape(theta_xy)[1], 2)
            full_theta = tf.concat([ones, zeros, tf.slice(theta_xy, [0,0], [-1,1]),
                                   zeros, ones, tf.slice(theta_xy, [0,1], [-1,-1])], axis=1)
    
        elif self.transform_type == 'rotation':
            tf.assert_equal(tf.shape(theta_xy)[1], 2)
            tf.assert_equal(tf.shape(theta_rt)[1], 1)
            mat_translation = tf.concat([ones, ones, tf.slice(theta_xy, [0,0], [-1,1]),
                                        ones, ones, tf.slice(theta_xy, [0,1], [-1,-1])], axis=1)
            
            mat_rot =   tf.concat([tf.cos(tf.slice(theta_rt, [0,0], [-1,1])), 
                                    tf.sin(tf.slice(theta_rt, [0,0], [-1,1])), ones,
                                   -tf.sin(tf.slice(theta_rt, [0,0], [-1,1])), 
                                    tf.cos(tf.slice(theta_rt, [0,0], [-1,1])), ones], axis=1)
    
            full_theta = tf.multiply(mat_translation, mat_rot)
    
        elif self.transform_type == 'uniform_scale':
            tf.assert_equal(tf.shape(theta_xy)[1], 2)
            tf.assert_equal(tf.shape(theta_rt)[1], 1)
            tf.assert_equal(tf.shape(theta_zm)[1], 1)
            mat_translation = tf.concat([ones, ones, tf.slice(theta_xy, [0,0], [-1,1]),
                                        ones, ones, tf.slice(theta_xy, [0,1], [-1,-1])], axis=1)
            
            mat_rot =   tf.concat([tf.cos(tf.slice(theta_rt, [0,0], [-1,1])), 
                                    tf.sin(tf.slice(theta_rt, [0,0], [-1,1])), ones,
                                   -tf.sin(tf.slice(theta_rt, [0,0], [-1,1])), 
                                    tf.cos(tf.slice(theta_rt, [0,0], [-1,1])), ones], axis=1)
            
            mat_zm = tf.concat([tf.slice(cp_zm(theta_zm), [0,0], [-1,1]), ones, ones,
                                   ones, tf.slice(cp_zm(theta_zm), [0,0], [-1,1]), ones], axis=1)
    
            full_theta = tf.multiply(tf.multiply(mat_translation, mat_rot), mat_zm)
    
#        elif self.transform_type == 'nonuniform_scale':
#            tf.assert_equal(tf.shape(theta)[1], 2)
#            full_theta = tf.concat([tf.slice(theta, [0,0], [-1,1]), zeros, zeros,
#                                   zeros, tf.slice(theta, [0,1], [-1,1]), zeros], axis=1)
        else:
            assert(False)

        output = _transform(full_theta, conv_input, self.downsample_factor)
        return output
