cfg.datadir = fullfile('/project/3018028.04/benehi/sequence/','data','pilot','bids');

for SID = {'sub-01','sub-02','sub-04'}
    SID = SID{1};
niftis = [dir(fullfile(cfg.datadir,'derivates','preprocessing',SID,'ses-01','func','*task-seq*run-*Realign_bold.nii'))];
mask_varea = dir(fullfile(cfg.datadir,'derivates','preprocessing',SID,'ses-01','label','*desc-varea_space-FUNCCROPPED_label.nii'));
mask_eccen = dir(fullfile(cfg.datadir,'derivates','preprocessing',SID,'ses-01','label','*desc-eccen_space-FUNCCROPPED_label.nii'));

nifti_varea= nifti(fullfile(mask_varea.folder,mask_varea.name));
nifti_eccen= nifti(fullfile(mask_eccen.folder,mask_eccen.name));

ix_v1= nifti_varea.dat(:) == 1; % V1
ix_ec15 = nifti_eccen.dat(:) <10; % V1

ix = find(ix_v1==1 & ix_ec15==1);

assert(length(ix)>200)
%% Load Event Files
events = collect_events(cfg.datadir,SID);
%% SPM DEsignmatrix for later voxel selection


calc_spm2ndLevel(cfg.datadir,{SID},'task','sequential','recalculate',0) % in this context we are fine with having the data once, no need to recalculate


runIxTop200 = [];
spmdatadir = fullfile(cfg.datadir,'derivates','SPM',SID,'ses-01','GLM',sprintf('run-%i',run));
for run = 1:8
    tmpT = nifti(fullfile(spmdatadir,'..',sprintf('run-%i',run),'spmT_0001.nii'));
    
    [~,I] = sort(tmpT.dat(ix));
    runIxTop200{run} = ix(I(end-200:end));
end


%% ZScore, Highpassfilter & mean ROI
act = [];
tic
for run = 1:8
    fprintf('run %i \t toc: %.2fs\n',run,toc)
    
    nifti_bold = nifti(fullfile(niftis(run).folder,niftis(run).name));
    timecourse = double(nifti_bold.dat);
    fprintf('Z-Score \n')
    timecourse = bold_ztransform(timecourse);
    timecourse = permute(timecourse,[4,1,2,3]);
    size_tc= size(timecourse);
    fprintf('High Pass Filter \n')
    timecourse(:) = tvm_highPassFilter(timecourse(:,:),TR,1/128);
    for tr = 1:size(nifti_bold.dat,4)
        
        tmp = timecourse(tr,:,:,:);
        if exist('runIxTop200','var')
            act(run,tr) = trimmean(tmp(runIxTop200{run}),20);
            %           act(run,tr) = mean(tmp(runIxTop200{run}));
        else
            act(run,tr) = trimmean(tmp(ix),0.20);
            %           act(run,tr) = mean(tmp(ix));
        end
    end
end
%%  CUT ERP


onsetIX = events.trial == 1;
events_onset = events(onsetIX,:);
allDat = calc_erb(act,events_onset,TR,[-3 40])

%%
%%



if ~exist('collectDat','var')
    collectDat = allDat;
end
collectDat = collectDat(collectDat.subject ~= str2num(SID(end-1:end)),:); % delete already existing data
collectDat = [collectDat ;allDat];
end
%% Contrast
for SID = unique(collectDat.subject)'
    allDat =collectDat(collectDat.subject == SID,:);
        avg_allDat =     grpstats(allDat(allDat.time>=6 & allDat.time<=21,{'block','condition','contrast','run','onset','erb_bsl','erb'}),{'block','run','condition','contrast','onset'},@median);
%%
    figure
    g = gramm('x',allDat.time,'y',allDat.erb_bsl,'color',allDat.contrast);
    g.stat_summary('type','bootci','geom','errorbar','setylim',1,'dodge',0.5);
    g.stat_summary('type','ci','geom','point','setylim',1,'dodge',0);
    g.stat_summary('type','ci','geom','line','setylim',1,'dodge',0);
    g.draw();
    g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('sub-%02i_ses-01_desc-contrast_plot.pdf',SID));
    
    %% Prediction
    figure
    g = gramm('x',allDat.time,'y',allDat.erb_bsl,'color',allDat.condition);
    g.stat_summary('type','bootci','geom','errorbar','setylim',1,'dodge',0.5);
    g.stat_summary('type','ci','geom','point','setylim',1,'dodge',0.5);
    g.stat_summary('type','ci','geom','line','setylim',1,'dodge',0);
    g.facet_wrap(allDat.contrast);
    % g.axe_property('Ylim',[-0.38 1.6])
    g.draw();
    g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('sub-%02i_ses-01_desc-predictionContrast_plot.pdf',SID));
    %%
    figure
    g = gramm('x',avg_allDat.contrast,'y',avg_allDat.median_erb_bsl,'color',avg_allDat.condition);
    g.stat_summary('type','bootci','geom','errorbar','dodge',0.2);
    g.stat_summary('geom','point','dodge',0.2);
    g.geom_point('alpha',0.2,'dodge',0.05);
    g.axe_property('Xlim',[0.2 0.9]);
    g.draw();
    g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('sub-%02i_ses-01_desc-aggregated_plot.pdf',SID));
    
    %%
    figure
    g = gramm('x',(avg_allDat.run-1)*12+avg_allDat.block,'y',avg_allDat.median_erb_bsl,'color',avg_allDat.condition,'marker',avg_allDat.contrast,'linestyle',avg_allDat.contrast);
    g.geom_point()
    g.stat_glm()
    g.draw();
    
    g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('sub-%02i_ses-01_desc-effectOverTime_plot.pdf',SID));
    
end
%% Group based

% Contrast
figure
g = gramm('x',collectDat.time,'y',collectDat.erb_bsl,'color',collectDat.contrast,'marker',collectDat.subject);
g.stat_summary('type','ci','geom','point','setylim',1,'dodge',0);
g.draw();
g.update('group',[],'marker',[])
g.stat_smooth()
g.axe_property('xlim',[-5,30],'ylim',[-0.5 1.5])
g.draw()
g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('ga_ses-01_desc-contrastEffect_plot.pdf'));

%%
figure
g = gramm('x',collectDat.time,'y',collectDat.erb_bsl,'color',collectDat.condition,'marker',collectDat.subject);
g.stat_summary('type','ci','geom','point','setylim',1,'dodge',0);
g.draw();
g.update('group',[],'marker',[])
g.stat_smooth()
g.axe_property('xlim',[-5,30],'ylim',[-0.5 1.5])
g.draw()

g.export('export_path','./plots/','file_type','pdf','file_name',sprintf('ga_ses-01_desc-predictionEffect_plot.pdf'));
