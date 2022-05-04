function exitstatus = experiment_sequenceBehaviour(cfg,randomization)

exitstatus = 0; % early exit if not changed
%-------------------
%|||| BitSi ||||||||
%-------------------
if strcmp(class(cfg.bitsi_scanner),'Bitsi_Scanner')
    cfg.bitsi_buttonbox.clearResponses;
    cfg.bitsi_scanner.clearResponses;
end
cfg.numSavedResponses = 0;
subjectid = randomization.subject(1);
runid = randomization.run(1);


%-------------------
%|||| LogFile ||||||||
%-------------------

outFile = fullfile('.','MRI_data',sprintf('sub-%02i',subjectid),'ses-01','beh', sprintf('sub-%02i_ses-01_task-sequence_run-%02i.mat',subjectid,runid));
if ~exist(fileparts(outFile),'dir')
    mkdir(fileparts(outFile))
end
fLog = fopen([outFile(1:end-3),'tsv'],'w');
if fLog == -1
    error('could not open logfile')
end
%print Header
fprintf(fLog,'%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n','onset','onsetTR','message','subject','run','block','trial','contrast','condition','phase','stimulus');
%-------------------
%|||| Generate stimulus textures ||||||||
%-------------------
Screen('FillRect', cfg.win, cfg.background);

Screen('DrawText',cfg.win,'Generating textures...', 100, 100);
Screen('Flip',cfg.win);
params = cfg.sequence;
cfg = setup_stimuli(cfg,params); % adapt must be a struct of cfg, e.g. cfg.adapt must exist with necessary information


%-------------------
%|||| setup kb queue ||||||||
%-------------------
setup_kbqueue(cfg);
responses = [];
stimtimings = nan(6,length(randomization.run));
expectedtimings= nan(6,length(randomization.run));

%--------------------------------------------------------------------------
% Distractor Task Flicker randomization
% -----------------------------------------------
nblock = length(unique(randomization.block));

%--------------------------------------------------------------------------
%% Instructions
clicks = 0;
Screen('FillRect',cfg.win,cfg.background);
% if strcmp(randomization.condition{1},'AttentionOnFixation')
%     fprintf(fLog,'Fixation Dot Flicker Block \n');
% else
%     fprintf(fLog,'Stimulus Dot Flicker Block \n');
% end
fprintf('Showing Instructions: waiting for mouse click (waiting for ScanTrigger after this)')

randStim = 1;
prevRandStim = 1;
lastChange = 0;
stimID = 1;
while ~any(clicks)
    
    introtex = cfg.stimTex(1);
    
    
    instructions = '    Look at the fixation dot in the centre of the screen at all times\n\n\n\n    Press a button if the image has more stripes than usual \n\n\n\n    Run length: 5 minutes';
    Screen('DrawText',cfg.win,'Waiting for experimenter (mouse click)', 100, 100);

    introtex = cfg.stimTex_highContr(1);
   
    if (GetSecs()-lastChange)>0.5
        %change stimulus
        lastChange = GetSecs();
        stimID = stimID + 1;
        stimID = mod(stimID,5)+1;
    end
    %     end
    ix = find(strcmp(randomization.condition,'predictable'),1);
    rotationvector = randomization.stimulus(ix:(ix+5-1));
    Screen('DrawTexture',cfg.win,introtex,[],OffsetRect(CenterRect([0 0, 0.5*cfg.stimsize],cfg.rect),cfg.width/4,0),rotationvector(stimID));
        
    [~,~,~] = DrawFormattedText(cfg.win, instructions, 'left', 'center'); % requesting 3 arguments disables clipping ;)
    colorInside = 0;
    draw_fixationdot(cfg,params.dotSize,0,colorInside,cfg.width/4*3,cfg.height/2)
    
    Screen('Flip',cfg.win);
    
    % while ~any(clicks)
    [~,~,clicks] = GetMouse();
    
    % end
    %     clicks
    
end
fprintf(' ... click\n')

% --------------------------------------------------------------------------
% Wait to detect first scanner pulse before starting experiment
if cfg.mriPulse == 1
    Screen('DrawText',cfg.win,'Waiting for mri scanner to be ready...', 100, 100);
    Screen('Flip',cfg.win);
    waitForScanTrigger_KB(cfg);
end

%% --------------------------------------------------------------------------
% MAIN TRIAL LOOP

if ~strcmp(class(cfg.bitsi_buttonbox),'Bitsi_Scanner')
    
    KbQueueStart(); % start trial press queue
end
%% Begin presenting stimuli
% Start with fixation cross

draw_fixationdot(cfg,params.dotSize)
startTime = Screen('Flip',cfg.win); % Store time experiment started
cfg.startTime = startTime;
tic
expectedTime = 0; % This will record what the expected event duration should be
firstTrial = true; % Flag to show we are on first trial

for blockNum = 1:nblock
    if firstTrial
        % Wait for scanner
        expectedTime = expectedTime + params.scannerWaitTime;
        firstTrial = false;
        
    end
    singleStimDuration = params.stimdur;
    catchDuration = singleStimDuration;%s
    
    select = randomization.block == blockNum;
    
    random_block= struct();
    for fn = fieldnames(randomization)'
        random_block.(fn{1}) = randomization.(fn{1})(select);
    end
    ntrials = length(random_block.trial);
    expectedTime_start = expectedTime;
    
    %     distractorTiming_dot      = trialDistractor_dot{blockNum}+expectedTime;
    sequence_ix = 0; % counter so that after 6 sequence stimuli we can show 1s pause against adaptation effects.
    for trialNum = 1:ntrials
        
        %% STIMULUS
        expectedtimings(1,trialNum) = expectedTime;
                
        phase_ix = random_block.phase(trialNum); % just so every trial starts with a different phase, could be random as well        
        
        %catchTrial?
       
            catchTrial = 0;
        
        
        
        
        % show stimulus
        switch random_block.contrast(trialNum)
            case params.contrast(1)
%                 if catchTrial == 0
                    stim = cfg.stimTex_lowContr(phase_ix);
%                 else
%                     stim = cfg.stimTexCatch_lowContr(phase_ix);
%                 end
                
            case params.contrast(2)
%                 if catchTrial == 0
                    stim = cfg.stimTex_highContr(phase_ix);
%                 else
%                     stim = cfg.stimTexCatch_highContr(phase_ix);
                    
%                 end
        end
        Screen('DrawTexture',cfg.win,stim,[],[],random_block.stimulus(trialNum));
        
        responses = draw_fixationdot_checkBitsi(cfg,params,expectedTime,responses);
        
        stimOnset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi,1)-startTime;
        if catchTrial == 0
            add_log_entry('stimOnset',stimOnset)
        else
            add_log_entry('catchOnset',stimOnset)
        end
        % how long should the stimulus be on?
        expectedTime = expectedTime + singleStimDuration/2;
        
        responses = draw_fixationdot_checkBitsi(cfg,params,expectedTime,responses);
        
        stimOnset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi,1)-startTime;
        expectedTime = expectedTime + singleStimDuration/2;

        responses = draw_fixationdot_checkBitsi(cfg,params,expectedTime,responses);

        sequence_ix = sequence_ix+1;
        if sequence_ix == length(params.refOrient)
            sequence_ix = 0;
            % ISI seconds pause between sequences
            Screen('FillRect',cfg.win,cfg.background)
            responses = draw_fixationdot_checkBitsi(cfg,params,expectedTime,responses,0);
            onset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
            add_log_entry('pauseOnset',onset)
            KbQueueFlush([],3)
            expectedTimeAnswer = expectedTime + params.ISI+5; % make at most 5s pause
            respBefore = length(responses);
            responses = draw_fixationdot_checkBitsi(cfg,params,expectedTimeAnswer,responses,1);
            gave_answer = length(responses) > respBefore;
            if gave_answer
                rt = expectedTime-responses(end).TimeMinusStart;
              expectedTime = responses(end).TimeMinusStart; 
              if (strcmp(random_block.condition{trialNum},'predictable') && responses(end).Keycode     == 82) || ...
                (strcmp(random_block.condition{trialNum},'random') && responses(end).Keycode     == 89)
                  correct = 3;
              else
                  correct = 4; 
              end
            else
                correct = 2;
                expectedTime = expectedTimeAnswer;
            end

            onset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
            expectedTime = expectedTime + .1; % make .1s pause
            

            responses = draw_fixationdot_checkBitsi(cfg,params,expectedTime,responses,correct);

            onset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
        end
        
    end
    Screen('FillRect',cfg.win,cfg.background)
    draw_fixationdot(cfg,params.dotSize)
    onset = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi)-startTime;
    add_log_entry('blockend',onset)
    
    
    % overwrite expected Time to catch up with minor fluctiations in
    % expected Time
%     expectedTimeOld = expectedTime;
%     expectedTime = expectedTime_start+params.trialLength + params.ITI;
%     fprintf('timing difference:%.4f\n',	 - expectedTimeOld)
    %     fprintf(fLog,'expectedTime ITI(TR):%.5f \t toc: %.5f\n',expectedTime/cfg.TR,(GetSecs-startTime)/cfg.TR);
    
    
    % just in case save the files after each block...
    try
        save(outFile, 'randomization','cfg', 'responses','stimtimings','expectedtimings','trialDistractor_stimulus','trialDistractor_dot');
    catch
        disp('Could not save outFile - may not exist');
    end
    
    
    
    % Safe quit mechanism (hold q to quit)
    [keyPr,~,key,~] = KbCheck;
    % && instead of & causes crashes here, for some reason
    key = find(key);
    if keyPr == 1 && strcmp(KbName(key(1)),'q')
        exitstatus = -1; % manual exit
        
        save_and_quit;
        return
    end
    %     fprintf(fLog,'button readout over : toc: %.5f\n',(GetSecs-startTime)/cfg.TR);
    
    
end  % END OF TRIAL LOOP

endTime = Screen('Flip', cfg.win, startTime + expectedTime - cfg.halfifi);

KbQueueStop();	% Stop delivering events to the queue

disp(['Time elapsed was ',num2str(endTime - startTime),' seconds']);
disp(['(Should be ',num2str(expectedTime),' seconds)']);

% -----------------------------------------------------------------
% call function to save results, close window and clean up
exitstatus = 1; % regular exit

save_and_quit;

    function save_and_quit
        
        % First dump everything to workspace just in case something goes
        % wrong
        assignin('base', 'responses', responses);
        
        % Save out results
        try
            save(outFile, 'randomization','cfg', 'responses','stimtimings','expectedtimings','trialDistractor_stimulus','trialDistractor_dot');
        catch
            disp('Could not save outFile - may not exist');
        end
        % Clean up
        try
            jheapcl; % clean the java heap space
        catch
            disp('Could not clean java heap space');
        end
        
        disp('Quit SubFunction safely');
        
    end

    function add_log_entry(varargin)
        if nargin <1
            message = '';
        else
            message = varargin{1};
        end
        if nargin < 2
            time = GetSecs-startTime;
        else
            time = varargin{2};
        end
        time_tr = time/cfg.TR;
        
        fprintf(fLog,'%.3f\t%.3f\t%s\t%03i\t%i\t%i\t%i\t%.1f\t%s\t%.3f\t%i\n',time,time_tr,message,...
            random_block.subject(trialNum),...
            random_block.run(trialNum),...
            random_block.block(trialNum),...
            random_block.trial(trialNum),...
            random_block.contrast(trialNum),...
            random_block.condition{trialNum},...
            params.phases(random_block.phase(trialNum)),...
            random_block.stimulus(trialNum));
    end

    function responses = draw_fixationdot_checkBitsi(cfg,param,expectedTime,responses,returnOnButtonpress)
        % draw fixation dot
        if nargin  == 4
            returnOnButtonpress = 0;
            
        end
        switch returnOnButtonpress
            case 0
                dotColor = 0;
            case 1
                dotColor = 0.5*255;
            case 2
                dotColor = [0.3 0.3 1]*255;
            case 3
                % correct
                dotColor = [0.3 1 0.3]*255;
            case 4
                %wrong
                dotColor = [1 .3 0.3]*255;
        end
        draw_fixationdot(cfg,param.dotSize,0,dotColor);
       
        %%
        %         cfg.startTime = GetSecs;expectedTime = cfg.startTime + 15
        
        while (expectedTime-(GetSecs-cfg.startTime))>2*cfg.halfifi
            % Read out all the button presses
            
            % only if we don't have a keyboard or bitsi input break
            if ~strcmp(class(cfg.bitsi_buttonbox),'Bitsi_Scanner')
                if ~KbEventAvail()
                    continue
                end
                evt = KbEventGet();
                
                
%             evt.Pressed = 0;
            else
%                 fprintf('Polling Keyboard:%.4fs\n',GetSecs-cfg.startTime)

                evt = struct();

                [response,timestamp] = cfg.bitsi_buttonbox.getResponse(.003,true);
                if response == 0
                    evt.response = 'A';
                    
                else
                    evt.response = char(response);
                    
                end
                evt.Time = timestamp;
                
                if lower(evt.response) == evt.response
                    % lower letters for rising
                    evt.Pressed = 1;
                else
                    % upper letters for falling edge
                    evt.Pressed = 0;
                end
            end
            if evt.Pressed==1 % don't record key releases
                evt.trialnumber = trialNum;
                evt.TimeMinusStart = evt.Time - cfg.startTime;
                evt.trialDistractor_stimulus = 0;
                %         evt.trialDistractor_dot = trialDistractor_dot{blockNum};
                evt.subject = randomization.subject(1);
                evt.run = randomization.run(1);
                evt.block = blockNum;
                responses = [responses evt];
                add_log_entry(['buttonpress_' KbName(evt.Keycode)],evt.TimeMinusStart);
                if returnOnButtonpress==1
                    break
                end
            end
        end
    end


end