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


n_stim = ceil(cfg.sequence.trialLength/cfg.sequence.stimdur/4)*4;

for runNum = 1:numRuns

    
% determine whether we use same or different stimuli trialtype
condition_dict = {'predictable','random'};
condition = repmat([0 1],1,numBlocks/length(condition_dict));
contrast  = repmat([1 1 2 2],1,numBlocks/length(condition_dict)/2);

rand_shuffle = randperm(numBlocks);
condition = repmat(condition_dict(condition(rand_shuffle)+1),1,numBlocks);

contrast = cfg.sequence.contrast(repmat(contrast(rand_shuffle),1,numBlocks));


rand_ix = [1 2 3 4];
while  all(rand_ix == [1,2,3,4])...
    || all(rand_ix == [2,3,4,1])...
    || all(rand_ix == [3,4,1,2])...
    || all(rand_ix == [4,1,2,3]) ...
    || all(rand_ix == [4,3,2,1])...
    || all(rand_ix == [3,2,1,4])...
    || all(rand_ix == [2,1,4,3])...
    || all(rand_ix == [1,4,3,2])
    rand_ix = randperm(length(cfg.sequence.refOrient));
end
sequence = cfg.sequence.refOrient(rand_ix)

  for blockNum= 1:numBlocks
    
    stimulus = repmat(sequence,1,n_stim/4);
    if strcmp(condition{blockNum},'random')
        
        stimulus = reshape(stimulus, numel(stimulus), 1);
        
        stimulus = stimulus(randperm(numel(stimulus)));
        
        
        success = 0;
        i = 2;
        while ~success
            iterations = 0;
            while i < numel(stimulus)
                if stimulus(i) ~= stimulus(i - 1)
                    i = i + 1;
                else
                    tmp = stimulus(i:end);
                    stimulus(i:end) = tmp(randperm(numel(tmp)));
                end
                iterations = iterations+1;
                if (iterations > 10000)
                    break
                end
            end
            success = 1;
        end
        stimulus = stimulus';
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