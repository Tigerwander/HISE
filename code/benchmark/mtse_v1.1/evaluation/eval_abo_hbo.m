function [ABO, HBO] = eval_abo_hbo(iou_files, methods, num_candidates, fh, ...
  names_in_plot, legend_location, save_prefix)  
%  Evaluate Average Best Overlap (ABO) and Histogram of Best Overlap (HBO).
%  HBO is plotted for the first two methods.
  
    assert(numel(iou_files) == numel({methods.short_name}));
    n = numel(iou_files);
    labels = cell(n,1);

    figure(fh); hold on; 
    centers = 0.05:0.1:0.95;
    ABO = zeros(n, 1);
    HBO = zeros(length(centers), n);
    colors = zeros(n, 3);
    for i = 1:n
        data = load(iou_files{i});
        thresh_idx = find( ...
          [data.best_candidates.candidates_threshold] <= num_candidates, 1, 'last');
        experiment = data.best_candidates(thresh_idx);

        % Average Best Overlap (ABO)
        abo = mean(experiment.best_candidates.iou);
        ABO(i) = abo;
        
        % Histogram of Best Overlap (HBO)
        bins = hist(experiment.best_candidates.iou, centers);
        bins = bins ./ sum(bins);
        HBO(:, i) = bins;

        number_str = sprintf('%.2f', abo);
        if names_in_plot
          labels{i} = sprintf('%s %s', methods(i).short_name, number_str);
        else
          labels{i} = number_str;
        end
        colors(i,:) = methods(i).color; 
    end  
   
    bar(centers, HBO(:,1), 0.8, 'facecolor', colors(1,:), 'EdgeColor', 'none');
    if n > 1
        color2 = min(colors(2,:)*1.6, 1);
        if max(color2 - colors(2,:)) < 0.1
            color2 = max(colors(2,:)*0.8, 0);
        end
        bar(centers, HBO(:,2), 0.4, 'facecolor', color2);
    end
    if n > 2
        warning('For HBO, only the first two methods are plotted.\n');
    end

    set(gca, 'YGrid','on');     
    xlabel('best overlap', 'fontsize', 12);
    ylabel('percentage', 'fontsize', 12);
    xlim([0, 1]);
    set(gca, 'xtick', [0:0.1:1.0]);
    ylim([0, 0.4]);
    legend(labels, 'Location', legend_location, 'FontSize', 15);
    legend boxoff;
    % save to file
    hei = 10;
    wid = 10;
    set(gcf, 'Units','centimeters', 'Position',[0 0 wid hei]);
    set(gcf, 'PaperPositionMode','auto');
    printpdf(sprintf('%s/ABO_HBO_%d.pdf', save_prefix, num_candidates));
end

