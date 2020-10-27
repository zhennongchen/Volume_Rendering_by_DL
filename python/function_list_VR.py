#!/usr/bin/env python

# this script saved most of functions widely used in other scripts
import numpy as np
import math
import glob as gb
import glob
import os
from scipy.interpolate import RegularGridInterpolator
import nibabel as nib
from nibabel.affines import apply_affine
import math
import string
import matplotlib.pyplot as plt
import cv2


# function: make folders
def make_folder(folder_list):
    for i in folder_list:
        os.makedirs(i,exist_ok = True)

# function: find all files under the name * in the main folder, put them into a file list
def find_all_target_files(target_file_name,main_folder):
    F = np.array([])
    for i in target_file_name:
        f = np.array(sorted(gb.glob(os.path.join(main_folder, os.path.normpath(i)))))
        F = np.concatenate((F,f))
    return F

# function: multiple slice view
def show_slices(slices,colormap = "gray",origin_point = "lower"):
    """ Function to display row of image slices """
    fig, axes = plt.subplots(1, len(slices))
    for i, slice in enumerate(slices):
        axes[i].imshow(slice.T, cmap=colormap, origin=origin_point)

# function: normalize one vector
def normalize(x):
    x_scale = np.linalg.norm(x)
    return np.asarray([i/x_scale for i in x])

# function: get length of one vector and angle between two vectors
def dotproduct(v1, v2):
    return sum((a*b) for a, b in zip(v1, v2))

def length(v):
    return math.sqrt(dotproduct(v, v))

def angle(v1, v2):
    rad=math.acos(dotproduct(v1, v2) / (length(v1) * length(v2)))
    result = rad / math.pi * 180
    return result

# function: get a vector which is with a certain angle from one known vector
def vector_with_angle(v,angle):
    return np.dot(np.array([[math.cos(angle),-math.sin(angle)],[math.sin(angle),math.cos(angle)]]),np.array([[v[0]],[v[1]]])).reshape(2,)

# function: calculate orientation error:
def orientation_error(x_truth,y_truth,x_pred,y_pred):
    n_truth = normalize(np.cross(x_truth,y_truth))
    n_pred = normalize(np.cross(x_pred,y_pred))

    error =  angle(n_truth,n_pred)
    if error > 180:
        error = error - 180
    return error

# function: project one vector onto a plane with known normal vectors
def project_onto_plane(u,n):
    '''n is the normal vector of the plane'''
    n = normalize(n)
    return (u - dotproduct(u,n) * n)

# function: get pixel dimensions
def get_voxel_size(nii_file_name):
    ii = nib.load(nii_file_name)
    h = ii.header
    return h.get_zooms()

# function: turn normalized vector into pixel unit
def turn_to_pixel(vec,size=[160,160,96]):
    t=vec.reshape(3,).tolist()
    result = [t[i]*size[i]/2 for i in range(0,3)]
    return np.array(result)

# function: define the interpolation
def define_interpolation(data,Fill_value=0,Method='linear'):
    shape = data.shape
    [x,y,z] = [np.linspace(0,shape[0]-1,shape[0]),np.linspace(0,shape[1]-1,shape[1]),np.linspace(0,shape[-1]-1,shape[-1])]
    interpolation = RegularGridInterpolator((x,y,z),data,method=Method,bounds_error=False,fill_value=Fill_value)
    return interpolation

# function: reslice a mpr
def reslice_mpr(mpr_data,plane_center,x,y,x_s,y_s,interpolation):
    # plane_center is the center of a plane in the coordinate of the whole volume
    mpr_shape = mpr_data.shape
    new_mpr=[]
    centerpoint = np.array([(mpr_shape[0]-1)/2,(mpr_shape[1]-1)/2,0])
    for i in range(0,mpr_shape[0]):
        for j in range(0,mpr_shape[1]):
            delta = np.array([i,j,0])-centerpoint
            v = plane_center + (x*x_s)*delta[0]+(y*y_s)*delta[1]
            new_mpr.append(v)
    new_mpr=interpolation(new_mpr).reshape(mpr_shape)
    return new_mpr


    
# function: check affine from all time frames (affine may have errors in some tf, that's why we need to find the mode )
def check_affine(one_time_frame_file_name):
    """this function uses the affine with each element as the mode in all time frames"""
    joinpath = os.path.join(os.path.dirname(one_time_frame_file_name),'*.nii.gz')
    f = np.array(sorted(glob.glob(joinpath)))
    a = np.zeros((4,4,len(f)))
    count = 0
    for i in f:
        i = nib.load(i)
        a[:,:,count] = i.affine
        count += 1
    mm =nib.load(f[0])
    result = np.zeros((4,4))
    for ii in range(0,mm.affine.shape[0]):
        for jj in range(0,mm.affine.shape[1]):
            l = []
            for c in range(0,len(f)):
                l.append(a[ii,jj,c])
            result[ii,jj] = max(set(l),key=l.count)
    return result

# function: convert coordinates to different coordinate system by affine matrix                             
def convert_coordinates(target_affine, initial_affine, r):
    affine_multiply = np.linalg.inv(target_affine).dot(initial_affine)
    return apply_affine(affine_multiply,r)


# function: count pixel in the image/segmentatio that belongs to one label
def count_pixel(seg,target_val):
    index_list = np.where(seg == target_val)
    count = index_list[0].shape[0]
    pixels = []
    for i in range(0,count):
        p = []
        for j in range(0,len(index_list)):
            p.append(index_list[j][i])
        pixels.append(p)
    return count,pixels

# function: DICE calculation
def DICE(seg1,seg2,target_val):
    p1_n,p1 = count_pixel(seg1,target_val)
    p2_n,p2 = count_pixel(seg2,target_val)
    p1_set = set([tuple(x) for x in p1])
    p2_set = set([tuple(x) for x in p2])
    I_set = np.array([x for x in p1_set & p2_set])
    I = I_set.shape[0] 
    DSC = (2 * I)/ (p1_n+p2_n)
    return DSC


# function: find time frame of a file
def find_timeframe(file,num_of_dots):
    k = list(file)
    if num_of_dots == 1: #.png
        num1 = [i for i, e in enumerate(k) if e == '.'][-1]
    else:
        num1 = [i for i, e in enumerate(k) if e == '.'][-2]
    num2 = [i for i,e in enumerate(k) if e== '/'][-1]
    kk=k[num2+1:num1]
    if len(kk)>1:
        return int(kk[0])*10+int(kk[1])
    else: 
        return int(kk[0])

# function: sort files based on their time frames
def sort_timeframe(files,num_of_dots):
    time=[]
    time_s=[]
    for i in files:
        a = find_timeframe(i,num_of_dots)
        time.append(a)
        time_s.append(a)
    time_s.sort()
    new_files=[]
    for i in range(0,len(time_s)):
        j = time.index(time_s[i])
        new_files.append(files[j])
    new_files = np.asarray(new_files)
    return new_files

# function: set window level and width
def set_window(image,level,width):
    if len(image.shape) == 3:
        image = image.reshape(image.shape[0],image.shape[1])
    new = np.copy(image)
    high = level + width
    low = level - width
    # normalize
    unit = (1-0) / (width*2)
    for i in range(0,image.shape[0]):
        for j in range(0,image.shape[1]):
            if image[i,j] > high:
                image[i,j] = high
            if image[i,j] < low:
                image[i,j] = low
            norm = (image[i,j] - (low)) * unit
            new[i,j] = norm
    return new

# function: upsample image
def upsample_images(image,up_size = 1):
    # in case it's 2D image
    if len(image.shape) == 2:
        image = image.reshape(image.shape[0],image.shape[1],1)
    # interpolation by RegularGridInterpolator only works for images with >1 slices, so we need to copy the current slice
    I = np.zeros((image.shape[0],image.shape[1],2))
    I[:,:,0] = image[:,:,0];I[:,:,1] = image[:,:,0]
    # define interpolation
    interpolation = define_interpolation(I,Fill_value=I.min(),Method='linear')
    
    new_image = []
    new_size = [image.shape[0]*up_size,image.shape[1]*up_size]
    
    for i in range(0,new_size[0]):
        for j in range(0,new_size[1]):
            point = np.array([1/up_size*i,1/up_size*j,0])
            new_image.append(point)
            
    new_image = interpolation(new_image).reshape(new_size[0],new_size[1],1)
    return new_image

# function: adapt the re-slicing vector from low resolution for native resolution:
def adapt_reslice_vector_for_native_resolution(vector,volume_file_low,volume_file_native):
    A_low = check_affine(volume_file_low)
    A_native = check_affine(volume_file_native)
    dim_low = get_voxel_size(volume_file_low)
    dim_native = get_voxel_size(volume_file_native) 
    # adapt direction vectors:
    vector['x'] = normalize(convert_coordinates(A_native,A_low,vector['x']) - convert_coordinates(A_native,A_low,[0,0,0]))
    vector['y'] = normalize(convert_coordinates(A_native,A_low,vector['y']) - convert_coordinates(A_native,A_low,[0,0,0]))
    # adapt translation vector
    t_low = vector['t']
    vector['t'] = np.asarray([t_low[i] * dim_low[i] / dim_native[i] for i in range(0,t_low.shape[0])])
    return vector

# function: make movies of several .png files
def make_movies(save_path,pngs,fps):
    mpr_array=[]
    i = cv2.imread(pngs[0])
    h,w,l = i.shape
    
    for j in pngs:
        img = cv2.imread(j)
        mpr_array.append(img)

    # save movies
    out = cv2.VideoWriter(save_path,cv2.VideoWriter_fourcc(*'mp4v'),fps,(w,h))
    for j in range(len(mpr_array)):
        out.write(mpr_array[j])
    out.release()


# function: read DicomDataset to obtain parameter values (not image)
def read_DicomDataset(dataset,elements):
    result = []
    for i in elements:
        if i in dataset:
            result.append(dataset[i].value)
        else:
            result.append('')
    return result


    


    