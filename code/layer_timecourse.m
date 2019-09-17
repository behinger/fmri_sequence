function Step3_timecourse_bene(datadir,subjectlist)



for SID = 1:length(subjectlist)
    disp(['Processing ', subjectlist(SID)]);
    
    
    disp(['Processing ', subjectlist{SID}]);
    bidsfilename  = [subjectlist{SID} '_ses-01_'];
    bidspath      = fullfile(datadir,'%s','%s',subjectlist{SID},'ses-01');
    path_layer= sprintf(bidspath,'derivates','tvm_layers');
    path_preprocessing= sprintf(bidspath,'derivates','preprocessing');
    path_feat= sprintf(bidspath,'derivates','FSL');
    
    
    if ~exist(fullfile(path_layer,'timecourse','dir'))
        mkdir(fullfile(path_layer,'timecourse','dir'))
    end
    configuration = [];
    configuration.i_SubjectDirectory = path_layer;
    
    funclist = dir(fullfile(path_layer,'func','*_desc-preproc-zscore*bold.nii'));
    funclist = {funclist.name};
    
    % Get all roi-masks
    designlist = dir(fullfile(path_layer,'spatialglm','*designmat.mat'));
    designlist = {designlist.name};
    assert(~isempty(designlist),'no masks found')
    
    
    % ONLY use this line for interpolation analysis
    %configuration.i_RegressionApproach = 'Interpolation';
    
    for func_id = 1:length(funclist)
        
        disp(['Currently on ', funclist{func_id}]);
        configuration.i_FunctionalFiles = fullfile('func',funclist{func_id});
        
        for curDesign = 1:length(designlist)
            configuration.i_DesignMatrix{curDesign} = fullfile('spatialglm',  designlist{curDesign});
            
            % filename
            str_design = strsplit(designlist{curDesign},'_');
            str_design{3} = str_design{3}(5:end); %'desc'
            str_func = strsplit(funclist{func_id},'_');
            str_desc = strjoin([str_func(5) str_design(3)],''); % combine description string
            str = strjoin([str_func(1:4) str_desc str_design(4)],'_'); % get rid of the '_designmat.nii'
            
            configuration.o_TimeCourse{curDesign}   = fullfile('timecourse',[str '_timecourse.mat']);
        end
        
        tvm_designMatrixToTimeCourse(configuration);
    end
end