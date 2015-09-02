function [boxes, scores] = run_mrs(img)
% Generate M-RS proposals.
% M-RS: MTSE using regular sampling for box initialization.
% M-RS is the simplest version of MTSE as it doesn't require any previous
% model to initialize bounding boxes. Refer to following paper for more
% details:
% 
% @inproceedings{cvpr15mtse,
%   author    = {Xiaozhi Chen and Huimin Ma and Xiang Wang and Zhichen Zhao},
%   title     = {Improving Object Proposals with Multi-Thresholding Straddling Expansion},
%   booktitle = {IEEE CVPR},
%   year      = {2015},
% }
%
% INPUTS
%   img         - a color image
% OUTPUTS
%   boxes       - [nx4] array containing proposals [left top right bottom]
%   scores      - [nx1] array containing proposal scores 
%
% Copyright 2015 Xiaozhi Chen (chenxz12@mails.tsinghua.edu.cn).
%

% graph-based segmentation parameters
colorType = 'Lab';
sigma = 0.8;
K = 100;
minSize = K;

% multiple thresholds
thetas = 0.1:0.1:0.5;
% NMS threshold
beta = 0.8;

% parameters for regular sampling
%     .alpha            - [.4] step size of sliding window search
%     .maxAspectRatio   - [3] max aspect ratio of boxes
%     .minBoxArea       - [1000] minimum area of boxes
alpha = 0.4;
maxAspectRatio = 3;
minBoxArea = 1000;

h = size(img,1);
w = size(img,2);

% Options: change colour space
% [~, img] = Image2ColourSpace(img, colorType);

% Oversegmentation
[sp_labels, sp_boxes] = mexFelzenSegmentIndex(img, sigma, K, minSize);
sp_boxes = sp_boxes(:, [2 1 4 3]); % change to [x1 y1 x2 y2] order
sp_areas = regionprops(sp_labels, 'Area'); 
sp_areas = cat(1, sp_areas(:).Area);

% change to appropriate data type
sp_boxes = int32(sp_boxes);
sp_areas = int32(sp_areas);
thetas = single(thetas);

% MTSE       
bb_out = mrs_mex(sp_boxes, sp_areas, minBoxArea, maxAspectRatio, alpha, w, h, thetas, beta);
boxes = bb_out(:, 1:4);
scores = bb_out(:, 5);

% Remove Duplicates
if beta == 1
    [boxes, ids_rank] = removeBoxDuplicates(boxes);
    scores = scores(ids_rank);
end

