function illustrate(img, gt, boxes)
% illustrate ground truth bounding boxes and their closest bounding boxes
% proposals
%
% INPUTS
%   img     - a color image
%   gt      - [nx4] array containing ground truth bounding boxes [left top right bottom]
%   boxes   - [nx4] array containing ground truth bounding boxes [left top right bottom]
%

% compute the closest proposals
[bo, bbs] = closest_candidates(gt, boxes);
        
% plot image    
figure;
imshow(img);
hold on;    
for j = 1 : size(gt, 1)
    bb = gt(j,:);
    plot(bb([1 3 3 1 1]), bb([2 2 4 4 2]), 'b', 'linewidth', 3);
    
    bb = bbs(j, :);
    plot(bb([1 3 3 1 1]), bb([2 2 4 4 2]), 'g', 'linewidth', 3);   
end

legend({'Ground truth', 'Best overlap'}, 'location', 'NorthWest');

end

