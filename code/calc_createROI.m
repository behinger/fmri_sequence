function create_weightedROI(datapath,subjectlist,varargin)

cfg = finputcheck(varargin, ...
    {
    'roi'             'real',   []    [1:3];... % rois from benson17 (V1=1,V2=2,V3=3)
    'topn'            'real'     []  0; ... % select top N voxels (0 takes all active)
    'zstat_map',      'real', [],1;... % generate all 3 zstat map functional
    'alpha'             'real' [],0.01;...
    'software2nd',    'string', {'spm','fsl'}, 'spm';...
    
    });

if ischar(cfg)
    error(cfg)
end
roinames = {'V1','V2','V3','hV4','VO1','VO2','LO1','LO2','TOI1','TO2','V3b','V3a'}; % after benson17


for SID = 1:length(subjectlist)
    disp(['Processing ', subjectlist{SID}]);
    bidsfilename  = [subjectlist{SID} '_ses-01_'];
    bidspath      = fullfile(datapath,'%s','%s',subjectlist{SID},'ses-01');
    path_layer= sprintf(bidspath,'derivates','tvm_layers');
    path_preprocessing= sprintf(bidspath,'derivates','preprocessing');
    
    
    path_2nd= sprintf(bidspath,'derivates',cfg.software2nd);
    
    
    
    
    
    % Load & Threshold V1-Activity Localizer Map
    
    for zstat = cfg.zstat_map
        if cfg.software2nd == "fsl"
            zmapNii       = niftiread(fullfile(path_2nd,'task-localizer_run-1.feat','stats',sprintf('zstat%i.nii.gz',zstat)));
            niftiheader   = niftiinfo(fullfile(path_2nd,'task-localizer_run-1.feat','stats',sprintf('zstat%i.nii.gz',zstat)));
            zmapName      = textscan(fopen(fullfile(path_feat,'task-localizer_run-1.feat','design.con')),'%s');
            zmapName  = zmapName{1}{zstat*2};
        elseif cfg.software2nd == "spm"
            zmapNii     = niftiread(fullfile(path_2nd, 'GLM','run-all',sprintf('spmT_%04i.nii',zstat)));

            niftiheader = niftiinfo(fullfile(path_2nd, 'GLM','run-all',sprintf('spmT_%04i.nii',zstat)));
            % SPM has a good header
            zmapName = strsplit(niftiheader.Description,':');
            zmapName = zmapName{2};
        end
        
        
        
        
        threshold     = -norminv(cfg.alpha);
        activeVoxels  = double(zmapNii) > threshold;
        
        
        % Load Labels
        labelsNii = niftiread(fullfile(path_preprocessing,'label',[bidsfilename 'desc-varea_space-FUNCCROPPED_label.nii']));
        
        % Create Folder in case not existing
        tmp_funcpath = fullfile(path_layer,'mask');
        if ~exist(tmp_funcpath,'dir')
            mkdir(tmp_funcpath);
        end
        
        for roi = cfg.roi
            mask_roi = logical(int8(labelsNii) == roi);
            
            roi_act = activeVoxels(:) .* mask_roi(:);
            roi_act = reshape(roi_act,size(mask_roi));
            save_nii_local(roi_act,[bidsfilename sprintf('desc-localizer%sThresh',zmapName) num2str(cfg.alpha) '_roi-' roinames{roi} '_mask']); % sub,ses,task,run,
            
            if cfg.topn ~= 0
                
                % sort V1 for most active
                [~,ind]   = sort(zmapNii(:).*mask_roi(:),'ascend');
                activeVoxels_top = activeVoxels;
                % set the (n minus topn) voxels to 0 effectively keeping only the topn
                % voxels in the roi
                activeVoxels_top(ind(1:(end-cfg.topn))) = 0;
                roi_act = activeVoxels_top(:) .* mask_roi(:);
                roi_act = reshape(roi_act,size(mask_roi));
                n_activevoxel = sum(roi_act(:)~=0);
                if n_activevoxel<cfg.topn
                    warning('zstat %i, roi %i, not enough voxel found!! %i / %i',zstat,roi,n_activevoxel,cfg.topn)
                end
                
                assert(n_activevoxel<=cfg.topn)
                save_nii_local(roi_act,[bidsfilename sprintf('desc-localizer%s',zmapName) 'Topvoxels' num2str(cfg.topn) '_roi-' roinames{roi} '_mask']); % sub,ses,task,run,
                
                
            end
        end
    end
    
    % Save out weighted functional files
end


    function save_nii_local(timecourse,filename)
        
        outFile = fullfile(path_layer,'mask', filename);
        niftiheader_save = niftiheader;
        niftiheader_save.Filename = outFile;
        niftiwrite(single(timecourse),outFile,niftiheader)
    end

end