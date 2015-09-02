function eval_voc07(methods)
% Evaluate proposals on VOC2007. Plot recall-overlap curves,
% recall-proposal curves, AR-proposal curve, and Histogram of Best Overlap
% (HBO).
% 
% This function requires the proposals to already be saved to disk. It will
% compute a matching between ground truth and proposals (if the result is not
% yet found on disk) and then plot all curves. The plots are saved to
% figures/.
%
% This code is modified from J. Hosang's benchmark code.
%

% default to evaluate on the full test set
testset = load('data/pascal_voc07_test_annotations.mat');

plot_results(testset, methods);

end

%% plot all curves
function plot_results(testset, methods)    

save_prefix = sprintf('figures/%s', sprintf('%s_', methods.short_name));
save_prefix = save_prefix(1:end-1);
if ~exist(save_prefix, 'dir')
    mkdir(save_prefix);
end

compute_best_candidates(testset, methods);

% Recall-Overlap curves using 500, 1000, 2000 proposals
fh = figure;
eval_recall_overlap({methods.best_voc07_candidates_file}, methods, 500, fh, true, 'NorthEast', save_prefix);
fh = figure;
eval_recall_overlap({methods.best_voc07_candidates_file}, methods, 1000, fh, true, 'NorthEast', save_prefix);
fh = figure;
eval_recall_overlap({methods.best_voc07_candidates_file}, methods, 2000, fh, true, 'SouthWest', save_prefix);

% ABO and HBO
fh = figure;
eval_abo_hbo({methods.best_voc07_candidates_file}, methods, 1000, fh, true, 'NorthWest', save_prefix);

% Recall-Proposal curves and AUC-Proposal curves
results = eval_average_recall({methods.best_voc07_candidates_file}, methods, save_prefix);
save(sprintf('%s/results.mat', save_prefix), 'results', 'methods');
fprintf('#prop=1000 50%%-recall 70%%-recall 80%%-recall\n');
for i = 1 : numel(methods)
    fprintf('%s:        %.3f    %.3f        %.3f\n', methods(i).short_name, ...
        results(i).recall(1,8), results(i).recall(2,8), results(i).recall(3,8));
end

fprintf('figures save to ''%s''\n', save_prefix);
end

%% compute the closest proposals
function compute_best_candidates(testset, methods)
  num_annotations = numel(testset.pos);
  candidates_thresholds = [1,3,10,32,100,316,500,1000,2000,3162,5000,10000];
  num_candidates_thresholds = numel(candidates_thresholds);
  
  for method_idx = 1:numel(methods)
    method = methods(method_idx);
    try
      load(method.best_voc07_candidates_file, 'best_candidates');
      continue
    catch
    end
    
    % preallocate
    best_candidates = [];
    best_candidates(num_candidates_thresholds).candidates_threshold = [];
    best_candidates(num_candidates_thresholds).best_candidates = [];
    for i = 1:num_candidates_thresholds
      best_candidates(i).candidates_threshold = candidates_thresholds(i);
      best_candidates(i).best_candidates.candidates = zeros(num_annotations, 4);
      best_candidates(i).best_candidates.iou = zeros(num_annotations, 1);
      best_candidates(i).image_statistics(numel(testset.impos)).num_candidates = 0;
    end
    
    pos_range_start = 1;
    for j = 1:numel(testset.impos)
      tic_toc_print('evalutating %s: %d/%d\n', method.name, j, numel(testset.impos));
      pos_range_end = pos_range_start + size(testset.impos(j).boxes, 1) - 1;
      assert(pos_range_end <= num_annotations);
    
      tic_toc_print('sampling candidates for image %d/%d\n', j, numel(testset.impos));
      [~,img_id,~] = fileparts(testset.impos(j).im);

      for i = 1:num_candidates_thresholds
        [candidates, scores] = get_candidates(method, img_id, ...
          candidates_thresholds(i));
        if isempty(candidates)
          impos_best_ious = zeros(size(testset.impos(j).boxes, 1), 1);
          impos_best_boxes = zeros(size(testset.impos(j).boxes, 1), 4);
        else
          [impos_best_ious, impos_best_boxes] = closest_candidates(...
            testset.impos(j).boxes, candidates);
        end

        best_candidates(i).best_candidates.candidates(pos_range_start:pos_range_end,:) = impos_best_boxes;
        best_candidates(i).best_candidates.iou(pos_range_start:pos_range_end) = impos_best_ious;
        best_candidates(i).image_statistics(j).num_candidates = size(candidates, 1);
      end
      
      pos_range_start = pos_range_end + 1;
    end
    
    save(method.best_voc07_candidates_file, 'best_candidates');
  end
end
