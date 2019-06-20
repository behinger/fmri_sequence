%% function Essen_RunExperiment
% Run through experiment. Does numRuns runs of attention experiment
% and one run of orientation localizer.

%--------------------------------------------------------------------------
tic;
cfg = struct();

cfg.debug =0; % Check debugmode

cfg.computer_environment = 'mri'; % could be "mri", "dummy", "work_station", "behav"
cfg.mri_scanner = 'prisma'; % could be "trio", "avanto","prisma", "essen"


cfg.writtenCommunication = 1;


% 3T TR should be 3.2 or 3.8 (WB)
cfg.TR = 2.336; % CAIPI sequence Essen

cfg.TR = 1.500; % 213 image volumes to be recorded
    
% cfg.TR = 3.408; % TR will determine stimulus timings

cfg = setup_parameters(cfg);

stimulatedTrialLength = (1/cfg.sequence.ISI+1)*cfg.sequence.stimdur*round(cfg.sequence.trialLength/( (1/cfg.sequence.ISI+1)*cfg.sequence.stimdur)/4)*4;
fprintf('TR: %.3fs \n block:\t\t%.1fs \n blockEf:\t%.1fs \n ITI:\t\t%.1fs\n',cfg.TR,cfg.sequence.trialLength,stimulatedTrialLength,cfg.sequence.ITI)
%%
cfg.sequence.numRuns = 8 %8
cfg.sequence.numBlocks = 12 %12 Number of trials in a run

fprintf('Setting up parameters \n')
clear screen % to reset the debugmode
if cfg.debug
    input('!!!DEBUGMODE ACTIVATED!!! - continue with enter')
    Screen('Preference', 'SkipSyncTests', 1)
    PsychDebugWindowConfiguration;
end




% Subject ID
if cfg.debug
    SID = '98';
else
    SID = input('Enter subject ID:','s');
end
assert(isnumeric(str2num(SID)))

% Gen/Load Randomization
try
    if cfg.debug
        % force randomization regen
        error
    end
    tmp = load(sprintf('randomizations/sub-%02i_ses-01_randomization.mat',str2num(SID)));
    fprintf('Loading Randomization from disk\n')
    
catch
    fprintf('Generating Randomization\n')
    setup_randomization_generate(cfg,str2num(SID),cfg.sequence.numRuns,cfg.sequence.numBlocks)
    tmp = load(sprintf('randomizations/sub-%02i_ses-01_randomization.mat',str2num(SID)));
    
end
randomization = tmp.randomization;

whichScreen = max(Screen('Screens')); %Screen ID
fprintf('Starting Screen\n')
cfg = setup_window(cfg,whichScreen);


%
% Do main Task
% cfg.sequence.ITI = 2.5
cfg.sequence.targetsColor = 0; % no distractor task at the 2fixation dot
% cfg.sequence.scannerWaitTime = 1

fprintf('Starting with main Task')

for curRun = 1:cfg.sequence.numRuns % is a sorted list of runs
    fprintf('Run %i from %i \n',curRun,cfg.sequence.numRuns)
    fprintf('Drawing subject instructions\n')
    
    DrawFormattedText(cfg.win, 'Moving on to main task ...', 'center', 'center');
    
    fprintf('Starting experiment_adaptation\n')
    exitstatus = experiment_sequence(cfg,slice_randomization(randomization,str2num(SID),curRun));
    
    if curRun <=cfg.sequence.numRuns
        text = ['Moving on to run ', num2str(curRun+1), ' of ', num2str(cfg.sequence.numRuns), '...'];
        DrawFormattedText(cfg.win, text, 'center', 'center');
        Screen('Flip',cfg.win);
        % Safe quit mechanism (hold q to quit)
        WaitSecs(2)
        [keyPr,~,key,~] = KbCheck;
        % && instead of & causes crashes here, for some reason
        key = find(key);
        if keyPr == 1 && strcmp(KbName(key(1)),'q')
            exitstatus = -1; % manual exit
            
            save_and_quit;
            return
        end
        
    end
    if cfg.writtenCommunication
        communicateWithSubject(cfg.win,'',200,200,cfg.Lmin_rgb,cfg.background);
    end
    toc
end



toc
safeQuit(cfg);