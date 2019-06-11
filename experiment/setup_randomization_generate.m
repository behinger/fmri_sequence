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
n_stim = ceil(cfg.sequence.trialLength/( (1/cfg.sequence.ISI+1)*cfg.sequence.stimdur)/4)*4;


% all allowed permutations with 4 stimuli
allPerms = perms(1:4);
    remove =        all(allPerms == [1,2,3,4],2)...
        | all(allPerms == [2,3,4,1],2)...
        | all(allPerms == [3,4,1,2],2)...
        | all(allPerms == [4,1,2,3],2) ...
        | all(allPerms == [4,3,2,1],2)...
        | all(allPerms == [3,2,1,4],2)...
        | all(allPerms == [2,1,4,3],2)...
        | all(allPerms == [1,4,3,2],2);
allPerms(remove,:) = [];

for runNum = 1:numRuns
    
    
    % determine whether we use same or different stimuli trialtype
    condition_dict = {'predictable','random'};
    condition = repmat([0 1],1,numBlocks/length(condition_dict));
    contrast  = repmat([1 1 2 2],1,numBlocks/length(condition_dict)/2);
    
    rand_shuffle = randperm(numBlocks);
    condition = repmat(condition_dict(condition(rand_shuffle)+1),1,numBlocks);
    
    contrast = cfg.sequence.contrast(repmat(contrast(rand_shuffle),1,numBlocks));
    
    
    % sequence for one 5 min run
    rand_ix = allPerms(randi(size(allPerms,1),1),:);
    
    sequence = cfg.sequence.refOrient(rand_ix);
    
    for blockNum= 1:numBlocks
        
        stimulus = repmat(sequence,1,n_stim/4);
        if strcmp(condition{blockNum},'random')
            stimulus_ix = randi(size(allPerms,1),n_stim/4,1);
            
            stimulus = allPerms(stimulus_ix,:).';
            stimulus = cfg.sequence.refOrient(stimulus(:));
            %
            %         stimulus = reshape(stimulus, numel(stimulus), 1);
            %
            %         stimulus = stimulus(randperm(numel(stimulus)));
            %
            %
            %         success = 0;
            %         i = 2;
            %         while ~success
            %             iterations = 0;
            %             while i < numel(stimulus)
            %                 if stimulus(i) ~= stimulus(i - 1)
            %                     i = i + 1;
            %                 else
            %                     tmp = stimulus(i:end);
            %                     stimulus(i:end) = tmp(randperm(numel(tmp)));
            %                 end
            %                 iterations = iterations+1;
            %                 if (iterations > 10000)
            %                     break
            %                 end
            %             end
            %             success = 1;
            %         end
            %         stimulus = stimulus';
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
save(fullfile('randomizations',['subject' num2str(subject), '_variables.mat']), 'randomization');
if nargout == 1
    varargout{1} = randomization;
end
end