function cfg = setup_parameters(cfg)


assert(isstruct(cfg))

% Add functions to path
addpath('.')
addpath('./functions');
addpath('./functions/jheapcl');
% Add java memory cleaner
try
    javaaddpath(which('MatlabGarbageCollector.jar'))
end


% Set up key experiment parameters

% These keys are used if the bitsi_buttonbox is used over USB
cfg.keys = [KbName('y') KbName('r') KbName('b') KbName('g') KbName('1') KbName('2'),KbName('3'),KbName('4'),KbName('5')]; %copied from essen_localiser_v4

cfg.sequence = struct();
cfg.sequence.stimSize = 12; % Diameter in degrees
cfg.sequence.refOrient = [0 45 90 135];
cfg.sequence.spatialFrequency = 1; % cpd
cfg.sequence.phases = linspace(0,2*pi,13);
cfg.sequence.phases(end) = []; %delete last one as 0 = 2*pi
cfg.sequence.spatialFrequency_catch = 2;%1.25;
cfg.sequence.ISI = 1;

cfg.sequence.contrast = [0.3 0.8];%[0.5 1]; % max contrast
cfg.sequence.start_linear_decay_in_degree = 0.5;

cfg.sequence.stimdur = 0.25;


cfg.sequence.trialLength = round(16/cfg.TR)*cfg.TR; %
cfg.sequence.scannerWaitTime = cfg.TR * 3;

cfg.sequence.ITI = round(10/cfg.TR)*cfg.TR;%cfg.sequence.trialLength;

cfg.sequence.dotSize = 1.5*[0.25 0.06]; % Size of fixation dot in pixels


cfg.sequence.targetsPerTrial = 1.5; % on average we will have 1.5 sequence per Trial
cfg.sequence.targetsTimeDelta = 2;%s sequence have to be at least distance of 2s
cfg.sequence.targetsColor = 0.4; % percent
cfg.sequence.targetsDuration = 0.1;% sequence for 100ms



cfg = setup_environment(cfg);

cfg.bitsi_scanner   = nan;
cfg.bitsi_buttonbox = nan;
if cfg.mriPulse == 1
    try
        delete(instrfind)
        cfg.bitsi_scanner   = Bitsi_Scanner('/dev/ttyS0');

        cfg.bitsi_buttonbox = Bitsi_Scanner('/dev/ttyS5');
        fprintf('Bitsi Scanner initialized\n')
        cfg.bitsi_scanner.clearResponses()
        cfg.bitsi_buttonbox.clearResponses()
    catch
     
        fprintf('Could not initialize bitsi\n')
    end
end
