# System

# Third Party
import tensorflow as tf
from keras.engine import Layer, InputSpec

# Internal

def dense_interp(x, r):
    # x should be of shape : batch_size, w, h, r^2
        bsize, a, b, c = x._keras_shape
        X = tf.reshape(x, (bsize, a, b, r, r))
        X = tf.transpose(X, (0, 1, 2, 4, 3))  # bsize, a, b, 1, 1
        X = tf.split(1, a, X)  # a, [bsize, b, r, r]
        X = tf.concat(2, [tf.squeeze(x) for x in X])  # bsize, b, a*r, r
        X = tf.reshape(X, (bsize, b, a*r, r))
        X = tf.split(1, b, X)  # b, [bsize, a*r, r]
        X = tf.concat(2, [tf.squeeze(x) for x in X])  # bsize, a*r, b*r

        return tf.reshape(X, (bsize, a*r, b*r, -1))

class Weidi_denseUP(Layer):
    '''
    This layer is inpired by the paper[1],
    aiming to provide upsamping in a more accurate way.

    Input to this layer is of size: w x h x r^2*c
    Output from this layer is of size : W x H x C
    where W = w * r, H = h * r, C = c

    Intuitively, we want to compensate the information loss with more feature
    channels, depth -> spatial resolution.
    We can reshape the feature channels,
    for example, take 1 x 1 x k^2, we can reshape it to k x k x 1.

    ratio : the ratio you want to upsample for both dimensions (w,h).
    nb_channel : The channels you really want after upsampling.
    nb_channel = input_shape[-1] / (prod(ratio))
    dim_ordering = 'tf' (I haven't done theano version)

    Reference:
    [1] Real-Time Single Image and Video Super-Resolution Using an Efficient
    Sub-Pixel Convolutional Neural Network.
    '''
    def __init__(self, nb_channel, ratio =(2, 2), dim_ordering='tf', **kwargs):
        self.ratio = tuple(ratio)
        self.nb_channel = nb_channel
        assert dim_ordering in {'tf', 'th'}, 'dim_ordering must be in {tf, th}'
        self.dim_ordering = dim_ordering
        self.input_spec = [InputSpec(ndim=4)]
        super(Weidi_denseUP, self).__init__(**kwargs)

    def get_output_shape_for(self, input_shape):
        if self.dim_ordering == 'tf':
            width = self.ratio[0] * input_shape[1] if input_shape[1] is not None else None
            height = self.ratio[1] * input_shape[2] if input_shape[2] is not None else None
            channel = input_shape[3] / (self.ratio[0] * self.ratio[1])
            return (input_shape[0],
                    width,
                    height,
                    channel)
        else:
            raise Exception('Invalid dim_ordering: ' + self.dim_ordering)

    def call(self, x, mask=None):
        r = self.ratio[0]
        if self.nb_channel > 1:
            Xc = tf.split(3, self.nb_channel, x)
            X = tf.concat(3, [dense_interp(x, r) for x in Xc])
        else:
            X = dense_interp(x, r)
        return X

    def get_config(self):
        config = {'ratio': self.ratio}
        base_config = super(Weidi_denseUP, self).get_config()
        return dict(list(base_config.items()) + list(config.items()))
