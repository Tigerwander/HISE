function [boxes_out, ids] = removeBoxDuplicates(boxes)
% Removes duplicate boxes. Leaves the boxes in the same order
% Keeps the first box of each kind.
%
% boxes:            N x 4 array containing boxes
% 
% boxes_out:        M x 4 array of boxes witout duplicates. M <= N
% ids:              Indices of retained boxes from boxesIn


[~, ids] = unique(boxes, 'rows', 'first');
ids = sort(ids);
boxes_out = boxes(ids,:);
