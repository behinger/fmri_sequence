# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

ni.plotting.plot_stat_map(img['activity'],)

import os
import numpy as np
import nibabel as nib
import nilearn as ni
import nilearn.plotting
import scientific_colormaps

fn = dict()
fn['activity'] = os.path.join('/home/predatt/benehi/projects/fmri_sequence/local/GLM/sub-04_run-all','spmT_0001.nii')
fn['condition'] = os.path.join('/home/predatt/benehi/projects/fmri_sequence/local/GLM/sub-04_run-all','spmT_0002.nii')
fn['contrast'] = os.path.join('/home/predatt/benehi/projects/fmri_sequence/local/GLM/sub-04_run-all','spmT_0003.nii')
fn['interact'] = os.path.join('/home/predatt/benehi/projects/fmri_sequence/local/GLM/sub-04_run-all','spmT_0004.nii')

img = {k:nib.load(f) for k,f in fn.items()}

ni.plotting.plot_stat_map(img['activity'],cmap=scientific_colormaps.load_cmap('berlin'))



bidspath = '/project/3018028.04/benehi/sequence/data/pilot/bids/derivates/preprocessing/sub-{:02d}/ses-{:02d}'.format(subject,session)
meanfun = os.path.join(bidspath,'func','sub-{:02d}_ses-{:02d}_task-sequential_desc-occipitalcropMeanBias_bold.nii'.format(subject,session))
img['meanfun'] = nib.load(meanfun)


ni.plotting.plot_stat_map(img['activity'],cmap=scientific_colormaps.load_cmap('berlin'),bg_img=img['meanfun'],threshold=2)