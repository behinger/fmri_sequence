% Generate laminar design matrices for each ROI
function layer_createSpatialglmX(datadir,subjectlist,varargin)

for SID = 1:length(subjectlist)
    disp(['Processing ', subjectlist{SID}]);
    bidspath      = fullfile(datadir,'derivates','tvm_layers',subjectlist{SID},'ses-01');
    
    configuration = [];
    configuration.i_SubjectDirectory = bidspath;
    
%     % Get all roi-masks
    roilist_full = dir(fullfile(bidspath,'mask','*.nii'));
    roilist_full = {roilist_full.name};
    assert(~isempty(roilist_full),'no masks found')
    
    if ~exist(fullfile(bidspath,'spatialglm'),'dir')
        mkdir(fullfile(bidspath,'spatialglm'))
    end
%     Interesting Code that In the end I did not need.. sigh
%     % extract the ROI
%     roilist = regexp(strjoin(roilist_full),'_roi-(.*?)_','tokens'); % find all rois of all strings, concatenate them before for one liner
%     roilist = cellfun(@(x)x{1},roilist,'UniformOutput',0); % get rid of the cells in cells (technicallity)
%     
%     desclist = regexp(strjoin(roilist_full),'_desc-(.*?)_','tokens'); % find all rois of all strings, concatenate them before for one liner
%     desclist = cellfun(@(x)x{1},desclist,'UniformOutput',0); % get rid of the cells in cells (technicallity)
%     
    for curROI = 1:length(roilist_full)
        
        % Which ROI should we be working on?
        configuration.i_ROI{curROI}          = fullfile('mask', roilist_full{curROI});
        
        % Where should we save it?
        str = strsplit(roilist_full{curROI},'_');
        str = strjoin(str(1:end-1),'_'); % get rid of the '_mask.nii'
        configuration.o_DesignMatrix{curROI} = fullfile('spatialglm', [str '_designmat.mat']);
    end
    
    % where do the layer info come from?
    configuration.i_Layers = fullfile('layer','Layering.nii');
    
    % go!
    tvm_roiToDesignMatrix(configuration);
    
    clear configuration;
end

