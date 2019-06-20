function cfg = setup_stimuli(cfg,params)
assert(isfield(cfg,'win'))

assert(isstruct(params))

if ~isfield(params,'phases')
    fprintf('Putting stimulus-phase to 0!\n')
    params.phases = 0;
end
% Will need a different texture for each stimulus phase
cfg.stimTex = zeros(1,length(params.phases)); % Preallocate
contrasts = params.contrast;
for i = 1:length(params.phases)
    for contrast = contrasts
        params.contrast = contrast;
        params.plaid = 0;
        params.phaseGrating = params.phases(i);
        
        stim = makeGaborStimulus(cfg,params);
        
        % catch stimulus with slightly higher spatial freq
        tmp = params.spatialFrequency;
        params.spatialFrequency = [params.spatialFrequency_catch];
        stimCatch = makeGaborStimulus(cfg,params);
        
        params.spatialFrequency = [tmp];
        switch contrast
            case contrasts(1)
                cfg.stimTex_lowContr(i) = Screen('MakeTexture', cfg.win, stim);
                
                cfg.stimTexCatch_lowContr(i) = Screen('MakeTexture', cfg.win, stimCatch);
            case contrasts(2)
                
                cfg.stimTex_highContr(i) = Screen('MakeTexture', cfg.win, stim);
                
                cfg.stimTexCatch_highContr(i) = Screen('MakeTexture', cfg.win, stimCatch);
        end
    end
    
end

cfg.stimsize = size(stim);


% Preload textures into video memory
Screen('PreloadTextures',cfg.win,cfg.stimTex_lowContr);
Screen('PreloadTextures',cfg.win,cfg.stimTex_highContr);
Screen('PreloadTextures',cfg.win,cfg.stimTexCatch_lowContr);
Screen('PreloadTextures',cfg.win,cfg.stimTexCatch_highContr);
fprintf('Textures Preloaded \n')
