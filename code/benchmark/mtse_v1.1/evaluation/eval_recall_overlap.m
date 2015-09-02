function eval_recall_overlap(iou_files, methods, num_candidates, fh, ...
  names_in_plot, legend_location, save_prefix)  
% plot recall-overlap curves.
% This code is modified from J. Hosang's benchmark code.
  
  assert(numel(iou_files) == numel({methods.short_name}));
  n = numel(iou_files);
  labels = cell(n,1);
  
  figure(fh); hold on; grid on;
  for i = 1:n
    data = load(iou_files{i});
    thresh_idx = find( ...
      [data.best_candidates.candidates_threshold] <= num_candidates, 1, 'last');
    experiment = data.best_candidates(thresh_idx);
    % AUC for range [0.5, 1.0]
    [overlaps, recall, ar] = compute_average_recall(experiment.best_candidates.iou);
    
    display_ar = ar * 100;
    % round to first decimal
    display_ar = round(display_ar * 10) / 10;    
    display_num_candidates = mean([experiment.image_statistics.num_candidates]);
    number_str = sprintf('%g (%d)', display_ar, round(display_num_candidates));
    if names_in_plot
      labels{i} = sprintf('%s %s', methods(i).short_name, number_str);
    else
      labels{i} = number_str;
    end
    color = methods(i).color;

    line_style = '-';
    if methods(i).is_baseline
        line_style = '--';
    end
    plot(overlaps, recall, 'Color', color, 'LineWidth', 2, 'LineStyle', line_style);      
  end  
    
  xlabel('IoU overlap threshold');
  ylabel('recall');
  xlim([0.5, 1]);
  ylim([0, 1]);
  legend(labels, 'Location', legend_location);
  legendshrink(0.5);
  legend boxoff;  
  % save to file
    hei = 10;
    wid = 10;
    set(gcf, 'Units','centimeters', 'Position',[0 0 wid hei]);
    set(gcf, 'PaperPositionMode','auto');
    printpdf(sprintf('%s/recall_%d.pdf', save_prefix, num_candidates));
end