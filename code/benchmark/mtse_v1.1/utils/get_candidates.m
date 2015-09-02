function [candidates, scores] = get_candidates(method_config, img_id, num_candidates, ...
  allow_filtering, subdirlen, candidate_dir)

  if nargin < 4
    allow_filtering = true;
  end
  if nargin < 5
    subdirlen = 4;
  end
  if nargin < 6
    candidate_dir = method_config.candidate_dir;
  end

  [candidates, scores, rerun_num_candidates] = read_candidates_mat(candidate_dir, img_id, subdirlen);
  if iscell(candidates) && iscell(scores)
%     error('this shouldn''t be used');
    % we have candidates from multiple runs, with different num_candidates
    % parameters
%     assert(numel(rerun_num_candidates) == numel(candidates));
%     assert(numel(scores) == numel(candidates));
%     assert(all(rerun_num_candidates(1:(end-1)) <= rerun_num_candidates(2:end)));
%     idx = find(rerun_num_candidates <= num_candidates, 1, 'last');
    [~,idx] = min(abs(rerun_num_candidates - num_candidates));
    candidates = candidates{idx};
    scores = scores{idx};
  end
  
  if allow_filtering
    if strcmp(method_config.order, 'none')
      % nothing to do
    elseif strcmp(method_config.order, 'biggest')
      w = candidates(:,3) - candidates(:,1) + 1;
      h = candidates(:,4) - candidates(:,2) + 1;
      areas = w .* h;
      [~,order] = sort(areas, 'descend');
      candidates = candidates(order,:);
      scores = scores(order,:);
    elseif strcmp(method_config.order, 'smallest')
      w = candidates(:,3) - candidates(:,1) + 1;
      h = candidates(:,4) - candidates(:,2) + 1;
      areas = w .* h;
      [~,order] = sort(areas, 'ascend');
      candidates = candidates(order,:);
      scores = scores(order,:);
    elseif strcmp(method_config.order, 'random')
      s = RandStream('mt19937ar','Seed',0);
      perm = randperm(s, size(candidates,1));
      candidates = candidates(perm,:);
      if numel(scores) > 0
        scores = scores(perm);
      end
    else
      [scores, argsort] = sort(scores, method_config.order);
      candidates = candidates(argsort,:);
    end
    
    num_candidates = min(num_candidates, size(candidates, 1));
    candidates = candidates(1:num_candidates,:);
    if numel(scores) > 0
      scores = scores(1:num_candidates,:);
    end
  else
    error('this shouldn''t be used');
  end
end
