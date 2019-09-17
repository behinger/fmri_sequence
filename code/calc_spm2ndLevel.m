function calc_spm2ndLevel(datadir,subjectlist,varargin)

cfg = finputcheck(varargin, ...
    {
    'task'             'string',   {'sequential','sustained'}    [];... % rois from benson17 (V1=1,V2=2,V3=3)
    'recalculate', 'boolean',[],1;... % always recalculate only if not specified otherwise
    });

if ischar(cfg)
    error(cfg)
end

assert(iscell(subjectlist))

for SID = subjectlist
    
    
    SID = SID{1};
    
    events = collect_events(datadir,SID);
    niftis = [dir(fullfile(datadir,'derivates','preprocessing',SID,'ses-01','func',sprintf('*task-%s*run-*Realign_bold.nii',cfg.task)))];
    
    if cfg.task=="sequential" && SID== "sub-04"
        TR = 2.336;
    elseif cfg.task == "sequential"
        TR = 1.5;
    else
        error('please implement TR or read it from bids somehow?')
    end
    %% Single Run SPM
    for run_ix = 0:8 
        if run_ix == 0
            
        spmdatadir = fullfile(datadir,'derivates','spm',SID,'ses-01','GLM','run-all');
        else
        spmdatadir = fullfile(datadir,'derivates','spm',SID,'ses-01','GLM',sprintf('run-%i',run_ix));      
        end
           
        fmri_spec = struct;
        fmri_spec.dir = cellstr(spmdatadir);
        fmri_spec.timing.units = 'secs';
        fmri_spec.timing.RT= TR;
        
        if run_ix == 0
            % 0 is all runs
            for run = 1:8
                ci = 0;
                for condition = unique(events.condition)'
                    for contrast = unique(events.contrast)'
                        ci = ci+1;
                        fmri_spec.sess(run).cond(ci).name = sprintf('%s-%.1f',condition{1},contrast);
                        
                        fmri_spec.sess(run).cond(ci).onset =  events{events.run== run & events.message=="stimOnset"&events.trial==1&strcmp(events.condition,condition{1})&events.contrast==contrast,'onset'}';
                        fmri_spec.sess(run).cond(ci).duration = repmat(16,size(fmri_spec.sess(run).cond(ci).onset));
                        fmri_spec.sess(run).multi_reg = {fullfile(niftis(run).folder,'../','motion',sprintf('%s_ses-01_task-sequential_run-%i_from-run_to-mean_motion.txt',SID,run))};
                        fmri_spec.sess(run).scans = {fullfile(niftis(run).folder,niftis(run).name)};
                    end
                end
            end
        else
            
            fmri_spec.sess.cond.name = 'Stimulus';
            fmri_spec.sess.cond.onset =  events{events.run== run_ix & events.message=="stimOnset"&events.trial==1,'onset'}';
            fmri_spec.sess.cond.duration = repmat(16,size(fmri_spec.sess.cond.onset));
            fmri_spec.sess.scans = {fullfile(niftis(run_ix).folder,niftis(run_ix).name)};
            fmri_spec.cvi = 'AR(1)';
        end
        if exist(fullfile(spmdatadir,'spmT_0001.nii'),'file')
            if ~cfg.recalculate
                warning('Old results found, will not recalculate')
                continue
            else
                warning('Old results found, folder deleted & starting recalculation')
                rmdir(spmdatadir,'s')
            end
        end
        matlabbatch = [];
        if ~exist(spmdatadir,'dir')
            mkdir(spmdatadir);
        end
        matlabbatch{1} = struct('spm',struct('stats',struct('fmri_spec',fmri_spec)));
        tmp = struct;
        tmp.stats.fmri_est.spmmat = cellstr(fullfile(spmdatadir,'SPM.mat'));
        matlabbatch{2} = struct('spm',tmp);
        
        % Contrasts
        %--------------------------------------------------------------------------
        matlabbatch{3}.spm.stats.con.spmmat = cellstr(fullfile(spmdatadir,'SPM.mat'));
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'Stim > Rest';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1 0];
        % Call script to set up design
        spm_jobman('run',matlabbatch);
    end
end