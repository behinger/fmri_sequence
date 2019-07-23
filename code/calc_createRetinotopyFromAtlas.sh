#!/bin/bash
set -e

_tmp=${subjectlist:='S10'}
_tmp=${datadir:='SubjectData'}

# activate venv
module load anaconda3 # donders infrastructure
#source activate $datadir/../../../venv_sequence
source activate /project/3018028.04/benehi/sequence/venv_sequence


for SID in $subjectlist
do

cd $datadir/derivates/freesurfer/$SID/ses-01/


# named benson14 but is actually benson17 ...
export SUBJECTS_DIR=$datadir/derivates/freesurfer/$SID/
python3 -m neuropythy benson14_retinotopy --verbose ses-01

mkdir -p $datadir/derivates/preprocessing/$SID/ses-01/label
mri_convert --reslice_like mri/rawavg.mgz mri/benson14_varea.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-varea_space-ANAT_label.nii' --resample_type nearest -ns 1 
mri_convert --reslice_like mri/rawavg.mgz mri/benson14_angle.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-angle_space-ANAT_label.nii' --resample_type nearest -ns 1
mri_convert --reslice_like mri/rawavg.mgz mri/benson14_eccen.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-eccen_space-ANAT_label.nii' --resample_type nearest -ns 1
mri_convert --reslice_like mri/rawavg.mgz mri/benson14_sigma.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-sigma_space-ANAT_label.nii' --resample_type nearest -ns 1



# This is the 'new' way to do it, but I couldnt get it to run...
#export SUBJECTS_DIR=$datadir/derivates/freesurfer/$SID/
# python3 -m neuropythy atlas --verbose ses-01

#mkdir -p $datadir/derivates/preprocessing/$SID/ses-01/label
#python3 -m neuropythy surface_to_image ses-01 -v -l surf/lh.benson14_varea.mgz -r surf/rh.benson14_varea.mgz --image mri/rawavg.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-varea_space-ANAT_label.nii' #
#python3 -m neuropythy surface_to_image ses-01 -v -l surf/lh.benson14_angle.mgz -r surf/rh.benson14_angle.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-angle_space-ANAT_label.nii' -i mri/rawavg.mgz
#python3 -m neuropythy surface_to_image ses-01 -v -l surf/lh.benson14_eccen.mgz -r surf/rh.benson14_eccen.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-eccen_space-ANAT_label.nii' -i mri/rawavg.mgz
#python3 -m neuropythy surface_to_image ses-01 -v -l surf/lh.benson14_sigma.mgz -r surf/rh.benson14_sigma.mgz '../../../preprocessing/'$SID'/ses-01/label/'$SID'_ses-01_desc-sigma_space-ANAT_label.nii' -i mri/rawavg.mgz


done
