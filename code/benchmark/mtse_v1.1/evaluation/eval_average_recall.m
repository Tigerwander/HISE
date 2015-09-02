function results = eval_average_recall(iou_files, methods, save_prefix)
% Plot recall-proposal curves and AR-proposal curves.
% This code is modified from J. Hosang's benchmark code.

  assert(numel(iou_files) == numel({methods.short_name}));
  n = numel(iou_files);
  labels = cell(n,1);
  
  h = figure;
  for i = 1:n
    data = load(iou_files{i});
    num_experiments = numel(data.best_candidates);
    x = zeros(num_experiments, 1);
    y = zeros(num_experiments, 1);
    for exp_idx = 1:num_experiments
      experiment = data.best_candidates(exp_idx);
      [~, ~, ar] = compute_average_recall(experiment.best_candidates.iou);
      x(exp_idx) = mean([experiment.image_statistics.num_candidates]);
      y(exp_idx) = ar;
    end
    labels{i} = methods(i).short_name;
    color = methods(i).color;
    line_style = '-';
    if methods(i).is_baseline
        line_style = '--';
    end
    
    semilogx(x, y, 'Color', color, 'LineWidth', 2, 'LineStyle', line_style);
    hold on; grid on;    

    results(i).ar = y;
    results(i).wins = x;
  end  
  
  xlim([10, 10000]);
  ylim([0 1]);
  xlabel('# proposals'); ylabel('average recall');
  legend(labels, 'Location', 'NorthWest');
  legendshrink(0.5);
  legend boxoff;
  % save to file
  hei = 10;
  wid = 10;
  set(gcf, 'Units','centimeters', 'Position',[0 0 wid hei]);
  set(gcf, 'PaperPositionMode','auto');
  printpdf(sprintf('%s/ar.pdf', save_prefix));

  %% fixed threshold
  legend_locations = {'SouthEast', 'NorthWest', 'NorthWest'};
  thresholds = [0.5 0.7 0.8];
  for threshold_i = 1:numel(thresholds)
    threshold = thresholds(threshold_i);
    labels = cell(n,1);
    figure;
    for i = 1:n
      data = load(iou_files{i});
      num_experiments = numel(data.best_candidates);
      x = zeros(num_experiments, 1);
      y = zeros(num_experiments, 1);
      for exp_idx = 1:num_experiments
        experiment = data.best_candidates(exp_idx);
        recall = sum(experiment.best_candidates.iou >= threshold) / numel(experiment.best_candidates.iou);
        x(exp_idx) = mean([experiment.image_statistics.num_candidates]);
        y(exp_idx) = recall;
      end
        labels{i} = methods(i).short_name;
        color = methods(i).color;
        line_style = '-';
        if methods(i).is_baseline
            line_style = '--';
        end  
        semilogx(x, y, 'Color', color, 'LineWidth', 2, 'LineStyle', line_style);
        hold on; grid on;
        
        results(i).recall(threshold_i, :) = y;
    end
    
    xlim([10, 10000]);
    ylim([0 1]);
    xlabel('# proposals'); ylabel(sprintf('recall at IoU threshold %.1f', threshold));
    legend(labels, 'Location', legend_locations{threshold_i});
    legendshrink(0.5);
    legend boxoff;
    % save to file
    hei = 10;
    wid = 10;
    set(gcf, 'Units','centimeters', 'Position',[0 0 wid hei]);
    set(gcf, 'PaperPositionMode','auto');
    printpdf(sprintf('%s/recall_proposal_%.0f.pdf', save_prefix, threshold*10));
  end
end
