function methods = get_methods(method)
% Get properties of a particular proposal model referred by the input 
% string 'method'. 
%
% This function is modified from J. Hosang's benchmark code.

% If you want to add your own method, add it at the bottom.

colormap = [ ...
228, 229, 97 ; ...
163, 163, 163 ; ...
218, 71, 56 ; ...
219, 135, 45 ; ...
145, 92, 146 ; ...
83, 136, 173 ; ...
135, 130, 174 ; ...
225, 119, 174 ; ...
142, 195, 129 ; ...
138, 180, 66 ; ...
223, 200, 51 ; ...
92, 172, 158 ; ...
177,89,40;
0, 255, 255;
188, 128, 189;
255, 255, 0;
0, 0, 255;
] ./ 256;

  precomputed_prefix = 'proposals/baseline/';
  
  methods = [];
  
  i = numel(methods) + 1;
  methods(i).name = 'Objectness';
  methods(i).short_name = 'OBJ';
  prefix = [precomputed_prefix 'objectness/'];
  methods(i).candidate_dir = [prefix 'mat_nms_10k'];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).order = 'descend';
  methods(i).color = colormap(i,:);
  methods(i).is_baseline = true;
  
  i = numel(methods) + 1;
  methods(i).name = 'Sel.Search';
  methods(i).short_name = 'SS';
  prefix = [precomputed_prefix 'selective_search/'];
  methods(i).candidate_dir = [prefix 'mat'];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).order = 'ascend';
  methods(i).color = colormap(i,:);
  methods(i).is_baseline = true;

  i = numel(methods) + 1;
  methods(i).name = 'Rand.Prim';
  methods(i).short_name = 'RP';
  prefix = [precomputed_prefix 'randomized_prims/'];
  methods(i).candidate_dir = [prefix 'mat'];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).order = 'none';
  methods(i).color = colormap(i,:);
  methods(i).is_baseline = true;
    
  i = numel(methods) + 1;
  methods(i).name = 'BING';
  methods(i).short_name = 'BING';
  prefix = [precomputed_prefix 'BING/'];
  methods(i).candidate_dir = [prefix 'mat'];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).order = 'descend';
  methods(i).color = colormap(i,:);
  methods(i).is_baseline = true;
  
  i = numel(methods) + 1;
  methods(i).name = 'EdgeBoxes';
  methods(i).short_name = 'EB';
  prefix = [precomputed_prefix 'edge_boxes_70/'];
  methods(i).candidate_dir = [prefix 'mat'];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).order = 'descend';
  methods(i).color = colormap(i,:);
  methods(i).is_baseline = true;  
  
  i = numel(methods) + 1;
  methods(i).name = 'EdgeBoxes50';
  methods(i).short_name = 'EB50';
  prefix = [precomputed_prefix 'edge_boxes_50/'];
  methods(i).candidate_dir = [prefix 'mat'];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).order = 'descend';
  methods(i).color = colormap(i,:);
  methods(i).is_baseline = true; 
  
  i = numel(methods) + 1;
  methods(i).name = 'CPMC';
  methods(i).short_name = 'CPMC';
  prefix = [precomputed_prefix 'CPMC/'];
  methods(i).candidate_dir = [prefix 'mat'];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).order = 'none';
  methods(i).color = colormap(i,:);
  methods(i).is_baseline = true; 
  
  i = numel(methods) + 1;
  methods(i).name = 'MCG';
  methods(i).short_name = 'MCG';
  prefix = [precomputed_prefix 'MCG/'];
  methods(i).candidate_dir = [prefix 'mat'];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).order = 'none';
  methods(i).color = colormap(i,:);
  methods(i).is_baseline = true; 
  
  i = numel(methods) + 1;
  methods(i).name = 'GOP';
  methods(i).short_name = 'GOP';
  prefix = [precomputed_prefix 'GOP_baseline/'];
  methods(i).candidate_dir = [prefix 'mat'];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).order = 'none';
  methods(i).color = colormap(i,:);
  methods(i).is_baseline = true; 
  
  i = numel(methods) + 1;
  methods(i).name = 'Regular Sampling';
  methods(i).short_name = 'RS';
  prefix = [precomputed_prefix 'RS/'];
  methods(i).candidate_dir = [prefix 'mat'];
  methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
  methods(i).order = 'none';
  methods(i).color = colormap(i,:);
  methods(i).is_baseline = true; 
  
  % add your own method here:
  if false
      i = numel(methods) + 1;
      methods(i).name = 'The full name of your method';
      methods(i).short_name = 'a very short version of the name';
      prefix = [precomputed_prefix 'ours-wip/'];
      methods(i).candidate_dir = [prefix 'mat'];
      methods(i).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
      % This specifies how to order candidates so that the first n, are the best n
      % candidates. For example we run a method for 10000 candidates and then take
      % the first 10, instead of rerunning for 10 candidates. Valid orderings are:
      %   none: candidates are already sorted, do nothing
      %   ascend/descend: sort by score descending or ascending
      %   random: random order
      %   biggest/smallest: sort by size of the bounding boxes
      methods(i).order = 'descend';    
      % color for drawing
      methods(i).color = colormap(i,:);
      % This should be false for MTSE integrated methods
      methods(i).is_baseline = true;
  end
  
   % do the sorting dance
  sort_keys = [num2cell([methods.is_baseline])', {methods.name}'];
  for i = 1:numel(methods)
    sort_keys{i,1} = sprintf('%d', sort_keys{i,1});
  end
  [~,idx] = sortrows(sort_keys);
  methods = methods(idx);
  
  % get a desired model
  if nargin > 0
      hit = false;
      for i = 1 : numel(methods)
          if strcmp(methods(i).name, method) == 1 || strcmp(methods(i).short_name, method) == 1
              methods = methods(i);
              hit = true;
              break;
          end
      end
      if ~hit
          error(sprintf('Please configure model %s in ''get_methods.m'' first.\n', method));
      end
  end
  
end
