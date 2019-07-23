data_path = './local/';
runIxTop200 = [];

if SID== "sub-04"
    TR = 2.336;
else
 TR = 1.5;
end


fmri_spec = struct;
fmri_spec.dir = cellstr(fullfile(data_path,'GLM',sprintf('%s_run-all',SID)));
fmri_spec.timing.units = 'secs';
fmri_spec.timing.RT= TR;
fmri_spec.sess.cond = struct();
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
fmri_spec.cvi = 'AR(1)';

% if exist(fullfile(data_path,'GLM',sprintf('%s_run-%i',SID, run),'spmT_0001.nii'),'file')    
% rmdir('./local/GLM','s')
% warning('Old results found, will not recalculate')
%     continue
% end
matlabbatch = [];
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.parent = cellstr(data_path);
matlabbatch{1}.cfg_basicio.file_dir.dir_ops.cfg_mkdir.name = fullfile('GLM',sprintf('%s_run-all',SID));

matlabbatch{2} = struct('spm',struct('stats',struct('fmri_spec',fmri_spec)));
tmp = struct;
tmp.stats.fmri_est.spmmat = cellstr(fullfile(data_path,'GLM',sprintf('%s_run-all',SID),'SPM.mat'));
matlabbatch{3} = struct('spm',tmp);

% Contrasts
%--------------------------------------------------------------------------
matlabbatch{4}.spm.stats.con.spmmat = cellstr(fullfile(data_path,'GLM',sprintf('%s_run-all',SID),'SPM.mat'));
matlabbatch{4}.spm.stats.con.consess{1}.tcon.name = 'Stim > Rest';
matlabbatch{4}.spm.stats.con.consess{1}.tcon.weights = [repmat([1 1  1  1 0 0 0 0 0 0],1,8) zeros(1,8)];

matlabbatch{4}.spm.stats.con.consess{2}.tcon.name = 'predictable>random';
matlabbatch{4}.spm.stats.con.consess{2}.tcon.weights = [repmat([1,1,-1,-1 0 0 0 0 0 0],1,8) zeros(1,8)];

matlabbatch{4}.spm.stats.con.consess{3}.tcon.name = 'contrast0.8>contrast0.3';
matlabbatch{4}.spm.stats.con.consess{3}.tcon.weights = [repmat([-1,1,-1,1 0 0 0 0 0 0],1,8) zeros(1,8)];

matlabbatch{4}.spm.stats.con.consess{4}.tcon.name = 'Interaction';
matlabbatch{4}.spm.stats.con.consess{4}.tcon.weights = [repmat([-1,1,1,-1 0 0 0 0 0 0],1,8) zeros(1,8)];

% Call script to set up design
spm_jobman('run',matlabbatch);
% end
%%
% for run = 1:8
tmpT = nifti(fullfile(data_path,'GLM',sprintf('%s_run-%i',SID, run),'spmT_0001.nii'));

[~,I] = sort(tmpT.dat(ix));
runIxTop200{run} = ix(I(end-200:end));
% end
