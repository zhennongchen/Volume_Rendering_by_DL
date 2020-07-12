# System

# Third Party
import numpy as np
import keras.backend as K
from skimage.measure import block_reduce
from scipy.ndimage.filters import gaussian_filter

# Internal
import segcnn.config as cg
import segcnn.utils as ut

def normalize(x):
    # utility function to normalize a tensor by its L2 norm
    return x / (K.sqrt(K.mean(K.square(x))) + 1e-5)

def visualize_maximum_prediction(model, mask, mask_indices, layer_name, num_iterations, grad_step = 0.1):
  """
  Maximize the predicted scores.  Given a mask and a model, maximize the prediction for the last convolutional layer.
  """

  mask_dict = {x : np.asarray((mask == x), dtype='float32') for x in range(cg.num_classes)}

  # get the symbolic outputs of each "key" layer (we gave them unique names).
  layer_dict = ut.model_to_dictionary(model)

  # this is the placeholder for the input images
  input_img = model.input

  # the name of the layer we want to visualize
  # build a loss function that maximizes the filter responses in the segmentation map
  layer_output = layer_dict[layer_name].output
  downsample = cg.dim // int(layer_output.get_shape()[1])

  mask_sum = K.zeros(shape=(1, layer_output.get_shape()[1], layer_output.get_shape()[2]))

  for m in mask_indices:
    mask_sum += layer_output[:, :, :, m] * block_reduce(mask_dict[m], (downsample, downsample), np.max)

  score = K.mean(mask_sum)

  # we compute the gradient of the input picture wrt this loss
  grads = K.gradients(score, input_img)[0]

  # normalization trick: we normalize the gradient
  grads = normalize(grads)

  # this function returns the loss and grads given the input picture
  iterate = K.function([input_img, K.learning_phase()], [score, grads])

  input_img_data = np.zeros((1, cg.dim, cg.dim, 1))

  # we run gradient ascent for 20 steps
  for i in range(num_iterations):
      score_value, grads_value = iterate([input_img_data, 0])
      input_img_data += grads_value * grad_step   # learning rate(step size)
      print('iter: {}, score value: {}'.format(i, score_value), end = '\r')

  print('Done.')
  return input_img_data

def visualize_information_loss(model, img, layer_name, num_iterations, grad_step = 0.1):

  # Initialize two place holders, one for real image sample, one for generated image
  input_img_example = model.input
  input_img_gen = model.input
  
  # get the symbolic outputs of each "key" layer (we gave them unique names).
  layer_dict = ut.model_to_dictionary(model)

  # extract the feature maps(real image sample) for specific layer.
  layer_output_fm = layer_dict[layer_name].output
  extract_feature_map = K.function([input_img_example, K.learning_phase()], [layer_output_fm])
  featuremap = extract_feature_map([np.expand_dims(np.expand_dims(img, axis=0), axis=-1), 0])

  # define the feature maps for the generated image
  layer_output_gen = layer_dict[layer_name].output

  # define the loss as l2 norm
  loss = K.mean((layer_output_gen - featuremap[0])**2)

  # we compute the gradient of the input picture wrt this loss
  grads = K.gradients(loss, input_img_gen)[0]

  # normalization trick: we normalize the gradient
  grads = normalize(grads)

  # this function returns the loss and grads given the input picture
  iterate = K.function([input_img_gen, K.learning_phase()], [loss, grads])

  input_img_data = np.zeros((1, cg.dim, cg.dim, 1))

  # we run gradient descent for 20 steps
  for i in range(num_iterations):
      loss_value, grads_value = iterate([input_img_data, 0])
      input_img_data -= grads_value * grad_step
      if i % 100 == 0:
          input_img_data = gaussian_filter(input_img_data, sigma=5)
      print('iter: {}, score value: {}'.format(i, loss_value), end = '\r')

  print(' ')

  return input_img_data

