function calc_CAIPI7tReconstruction(datadir,subjectlist)
% This function can be called to start grid jobs (then subjectlist should
% be not empty) or if subjectlist is empty, the recon script is ran on the
% datadir folder.

if iscell(subjectlist)
    % iteratively call this function on the grid
for s = 1:length(subjectlist)
    
    
      
    raw = fullfile(datadir,'..','raw',subjectlist{s},'ses-01');
    
    % find one image that was reconstructed on siemens to copy the header for
    % reconstruction
    imageDir = dir(fullfile(raw,'BENEHI_CAIPI_1VOLUME_REFERENCE*/*.IMA'));
    if isempty(imageDir)
        warning('No Reference IMA found for subject %s. Aborting \n',subjectlist{s})
        continue
    end
    from = fullfile(imageDir(end).folder,imageDir(end).name);

    % find all dat files
    subjectdir = fullfile(datadir,subjectlist{s},'ses-01');
    datfiles = dir(fullfile(subjectdir,'*.dat'));
    for dat = 1:length(datfiles)
        
        % make a directory, the recon script wants 1 dat file in 1 folder
        % with 1 IMG file.... whatever
        [~,filenameNoExt,~] = fileparts(datfiles(dat).name);
        targetfolder = fullfile(datfiles(dat).folder,filenameNoExt);
        mkdir(targetfolder)
        status = system(sprintf('mv %s %s',fullfile(datfiles(dat).folder,datfiles(dat).name),targetfolder));
        if status~=0;error;end
        
        % symlink the 1 volume header to the dat folder
        cmd = sprintf('ln -s %s %s',from,targetfolder);
        status = system(cmd);
        if status~=0;error;end
        
        
    
    end
    
    % Go through all folders and start the grid job
    %
    reconfolders = dir(fullfile(subjectdir));
    reconfolders  = reconfolders(3:end);
    for r = 1:length(reconfolders)
        targetfolder = fullfile(reconfolders(r).folder,reconfolders(r).name);
        qsubfeval(@calc_CAIPI7tReconstruction,targetfolder,'','memreq',20*1024^3,'timreq',60*60*15); %20GB ram and 15h
    end

    
    
    
end


elseif ischar(subjectlist) && isempty(subjectlist)
    %%
    tic
    ELH_3DEPI_reconstruction_function(datadir,[4 2], ...
        'coilcombine'   ,'adapt'      ,...
        'coilcompress'  ,0          ,...
        'imspace'       ,0          ,...
        'regrid'        ,1          ,...
        'unring'        ,1          ,...
        'pocs'          ,0); 
    toc
else 
    error('wrong input, neither cell array nor char')
end