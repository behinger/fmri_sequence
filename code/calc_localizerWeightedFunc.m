function calc_localizerWeightedFunc(datapath,subjectlist,varargin)

cfg = finputcheck(varargin, ...
    {
    'zscore'          'boolean', [], 1; ... % zscore?
    'weight'          'boolean', [], 1; ... % weight by localizer t-value?
    'software2nd',    'string', {'spm','fsl'}, 'spm';...
    });



for SID = 1:length(subjectlist)
    disp(['Processing ', subjectlist{SID}]);
    bidspath      = fullfile(datapath,'%s','%s',subjectlist{SID},'ses-01');
    path_layer= sprintf(bidspath,'derivates','tvm_layers');
    path_preprocessing= sprintf(bidspath,'derivates','preprocessing');
    path_2nd= sprintf(bidspath,'derivates',cfg.software2nd);
    
    if cfg.software2nd == "fsl"
        zmapNii       = niftiread(fullfile(path_2nd,'task-localizer_run-1.feat','stats',sprintf('zstat%i.nii.gz',1)));
    elseif cfg.software2nd == "spm"
        zmapNii = niftiread(fullfile(path_2nd, 'GLM','run-all','spmT_0001.nii'));
    end
    
    
    
    
    
    cfg.funclist = dir(fullfile(path_preprocessing,'func','*desc-occipitalcropRealign_bold.nii'));
    cfg.funclist = {cfg.funclist.name};
    assert(length(cfg.funclist)>0)
    for func_id = 1:length(cfg.funclist)
        disp(['Analyzing Functional', cfg.funclist{func_id}]);
        
        % Load time course and tmap data
        timecourseNii = niftiread(fullfile(path_preprocessing,'func',cfg.funclist{func_id}));
        niftiheader = niftiinfo(fullfile(path_preprocessing,'func',cfg.funclist{func_id}));
        
        
        timecourse = double(timecourseNii);
        if cfg.zscore
            timecourse = bold_ztransform(timecourse);
        end
        timecourse(isnan(timecourse(:))) = 0;
        if cfg.weight
            
            timecourse_w = bsxfun(@times,timecourse,abs(double(zmapNii))); % abs to keep positive bold positive and negative negative
        end
        
        tmp_funcpath = fullfile(path_layer,'func');
        if ~exist(tmp_funcpath,'dir')
            mkdir(tmp_funcpath);
        end
        
        
        splt = strsplit(cfg.funclist{func_id},'_');
        save_nii_local(timecourse,[strjoin(splt(1:4),'_') '_desc-preproc-zscore_bold']); % sub,ses,task,run,
        if cfg.weight
            save_nii_local(timecourse_w,[strjoin(splt(1:4),'_') '_desc-preproc-zscore-tweight_bold']); % sub,ses,task,run,
            
        end
        
        
        % Save out weighted functional files
    end
end



    function save_nii_local(timecourse,filename)
        
        outFile = fullfile(path_layer,'func', filename);
        niftiheader_save = niftiheader;
        niftiheader_save.Filename = outFile;
        niftiwrite(single(timecourse),outFile,niftiheader)
    end
end