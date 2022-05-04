function varargout  = setup_randomization_generate(cfg,subject,numRuns,numBlocks)

% Run
% Block / Trial
% ~60 * 0.25s Stimuli

if nargin == 0
    error
end




assert(ceil(numBlocks/4) == floor(numBlocks/4)) % check that numTrials is divisble by 6


rng(subject) % reset the random seed to make the randomization repeatable
randomization = struct('trial',[],'block',[],'condition',[],'stimulus',[],'run',[],'subject',[],'phase',[],'contrast',[]);



% Path
addpath(fullfile('..','functions'));

% ceil(x/4)*4 to get same number of contrast*condition per block
% n_stim = ceil(cfg.sequence.trialLength/( (1/cfg.sequence.ISI+1)*cfg.sequence.stimdur)/4)*4;
n_stim = floor(cfg.sequence.trialLength/(1 + length(cfg.sequence.refOrient)*cfg.sequence.stimdur))*length(cfg.sequence.refOrient);


%% find a random sequence
allPerms = perms(1:length(cfg.sequence.refOrient));

neighbouring_ident = abs(diff([allPerms(:,2),allPerms],[],2))==1;
for k = 1:size(allPerms,1) % go through each perm
    % only keep bad-indeces for sequences where 3 consecutive stimuli are
    % in a row (we dont want those).
    neighbouring_ident(k,:) =  neighbouring_ident(k,:) .* bwareaopen(neighbouring_ident(k,:),2);
end
bad_ix = any(neighbouring_ident,2);

%remove  things like 1 4 2 5 3 => where every second stimulus is increasing
bad_comb = [];
for k = 1:3
    base = mod(0:k:(k*5-1),5)+1;
    bad_comb = [bad_comb; mod(repmat(base,5,1)+repmat([1:5]',1,5),5)+1];
end

bad_ix = bad_ix | ismember(allPerms,bad_comb,'rows');

allPerms(bad_ix,:) = [];

% One fixed sequence throughout the experiment
rand_select_ix = randi(size(allPerms,1),1);
rand_ix = allPerms(rand_select_ix,:);
sequence = cfg.sequence.refOrient(rand_ix);

%% Generate all possible random sequences
% For now assume that the selected nonrandom sequence was 1,2,3,4,5 (and
% move to the reals equence at the end)

allPerms = perms(1:length(cfg.sequence.refOrient));
% Remove the ones where 3 can predict 4, or 5 6 etc.
bad_ix = any(diff([repmat(100,size(allPerms,1),1),allPerms],[],2)==1,2);
allPerms(bad_ix,:) = [];

% now we "jumble" them to the "absolute order" 
allPerms = rand_ix(allPerms);

% and remove the same triplets
% as we remove dbefore, e.g. 1 2 3 6 4 5 is not ok, because 1 2 3 could
% potentially be perceived as rotation

% sequences because they cant exist in the random sequence either
neighbouring_ident = abs(diff([allPerms(:,2),allPerms],[],2))==1;
for k = 1:size(allPerms,1) % go through each perm
    % only keep bad-indeces for sequences where 3 consecutive stimuli are
    % in a row (we dont want those).
    neighbouring_ident(k,:) =  neighbouring_ident(k,:) .* bwareaopen(neighbouring_ident(k,:),2);
end
bad_comb = [];
for k = 1:3
    base = mod(0:k:(k*5-1),5)+1;
    bad_comb = [bad_comb; mod(repmat(base,5,1)+repmat([1:5]',1,5),5)+1];
end

bad_ix = ismember(allPerms,bad_comb,'rows') | any(neighbouring_ident,2);

allPerms(bad_ix,:) = [];
%%
% condition runWise
conditionRunwise = 0;
warning('Bene Changed to ~ConditionRunwise')
condition_dict = {'predictable','random'};
assert(ceil(numRuns/2) == floor(numRuns/2))
condition = repmat([0 1],1,numRuns/2);
rand_shuffle = randperm(numRuns);
condition_runwise = condition_dict(condition(rand_shuffle)+1);

warning('Sequence reduced to 2 stimuli')
allPerms = (mod(allPerms,2)+1)*2;
sequence = cfg.sequence.refOrient((mod(rand_ix,2)+1)*2);
for runNum = 1:numRuns
    
    rand_shuffle = randperm(numBlocks);

    % determine whether we use same or different stimuli trialtype
    if ~conditionRunwise
        % each block/run can be either conditoin
        condition = repmat([0 1],1,numBlocks/length(condition_dict));
        condition = repmat(condition_dict(condition(rand_shuffle)+1),1,numBlocks);
    else
        % blocked runwise
        condition = repmat(condition_runwise(runNum),1,numBlocks);
    end
    contrast  = repmat([1 1 2 2],1,numBlocks/4);
    

    
    contrast = cfg.sequence.contrast(contrast(rand_shuffle));
    
    

    for blockNum= 1:numBlocks
        
        stimulus = repmat(sequence,n_stim/length(cfg.sequence.refOrient),1);
        % circshift them so that e.g. from
        % ABCD ABCD ABCD
        % we receive
        % ABCD DABC BCDA etc. so same sequence, but different starting
        % points
        for k = 1:size(stimulus,1)
            stimulus(k,:) = circshift(stimulus(k,:),randi(length(cfg.sequence.refOrient),1));
        end
        stimulus = stimulus';
        stimulus = stimulus(:)';
        
        if strcmp(condition{blockNum},'random')
            stimulus_ix = randi(size(allPerms,1),n_stim/length(cfg.sequence.refOrient),1);
            
            stimulus = allPerms(stimulus_ix,:).';
            stimulus = cfg.sequence.refOrient(stimulus(:));
        end
        phase = mod(randperm(n_stim),length(cfg.sequence.phases))+1;
        
        
        randomization.stimulus = [randomization.stimulus stimulus];
        randomization.phase     = [randomization.phase phase];
        
        
        randomization.trial =  [randomization.trial 1:n_stim];
        randomization.run   =  [randomization.run repmat(runNum,1,n_stim)];
        randomization.block =  [randomization.block repmat(blockNum,1,n_stim)];
        randomization.subject= [randomization.subject repmat(subject,1,n_stim)];
        
        randomization.condition = [randomization.condition repmat(condition(blockNum),1,n_stim)];
        randomization.contrast  = [randomization.contrast repmat(contrast(blockNum),1,n_stim)];
    end
    
end

assert(unique(structfun(@length,randomization)) == n_stim * numRuns*numBlocks)

if ~exist('randomizations','dir')
    mkdir('randomizations')
end
save(fullfile('randomizations',sprintf('sub-%02i_ses-01_randomization.mat',subject)), 'randomization');
if nargout == 1
    varargout{1} = randomization;
end
end