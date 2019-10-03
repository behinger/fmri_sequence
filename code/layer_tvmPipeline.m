% Do layers pipeline on Freesurfer boundaries
function layer_tvmPipeline(datadir,subjectlist,varargin)
cfg = finputcheck(varargin, ...
    { 'task'         'string'   []    'sequential'; ... % Set this to 1 to make orientation preference masks for whole ROI
    
    
    });

% Subjects to process



for SID = 1:length(subjectlist)
    disp(['Processing ', subjectlist{SID}]);
    
    bidsfilename  = [subjectlist{SID} '_ses-01_'];
    bidspath      = fullfile(datadir,'%s','%s',subjectlist{SID},'ses-01');
    bidspath = sprintf(bidspath,'derivates','tvm_layers');
    rel_preprocces = fullfile('../../../','preprocessing',subjectlist{SID},'ses-01');
    rel_freesurfer = fullfile('../../../','freesurfer',subjectlist{SID},'ses-01');
    if ~exist(bidspath,'dir')
        mkdir(bidspath)
    end
    if ~exist(fullfile(bidspath,'layer'),'dir')
        mkdir(fullfile(bidspath,'layer'))
    end
    if ~exist(fullfile(bidspath,'surf'),'dir')
        mkdir(fullfile(bidspath,'surf'))
    end
    
    configuration = [];
    configuration.i_SubjectDirectory = bidspath;
    configuration.i_Boundaries       = fullfile(rel_preprocces,'coreg',[bidsfilename 'from-ANAT_to-FUNCCROPPED_desc-recursive_mode-surface.mat']);
    
    configuration.i_ReferenceVolume  = fullfile(rel_preprocces,'func', [bidsfilename sprintf('task-%s_desc-occipitalcropMeanBias_bold.nii',cfg.task)]);
%     configuration.i_ObjWhite         = fullfile(rel_freesurfer,'surf','?h.white.reg.obj');
%     configuration.i_ObjPial          = fullfile(rel_freesurfer,'surf','?h.pial.reg.obj');
    
    configuration.i_b0    = 'layer/brain.pial.sdf.nii';
    configuration.i_b1    = 'layer/brain.white.sdf.nii';
    configuration.i_White = 'layer/brain.white.sdf.nii';
    configuration.i_Pial  = 'layer/brain.pial.sdf.nii';
    
    configuration.i_Levels = 0:1/3:1;

    
    configuration.o_SdfWhite  = 'layer/?h.white.sdf.nii';
    configuration.o_SdfPial   = 'layer/?h.pial.sdf.nii';
    configuration.o_White     = 'layer/brain.white.sdf.nii';
    configuration.o_Pial      = 'layer/brain.pial.sdf.nii';
    
    % Check that nothing gets overwritten
    configuration.o_ObjWhite  = fullfile('surf','?h.white.reg.obj');
    configuration.o_ObjPial   = fullfile('surf','?h.pial.reg.obj');
    configuration.o_LaplacePotential = 'layer/LaplacePotential.nii';
    
    
    configuration.o_Gradient  = 'layer/Gradient.nii';
    configuration.o_Curvature = 'layer/Curvature.nii';
       
    configuration.o_Layering  = 'layer/Layering.nii';
    configuration.o_LevelSet  = 'layer/LevelSet.nii';
    
    tvm_layerPipeline(configuration);
    clear configuration
end
    
 
