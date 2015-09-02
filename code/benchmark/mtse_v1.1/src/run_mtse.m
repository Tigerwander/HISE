function [boxes, scores] = run_mtse(img, init_boxes, opts)
% Generate MTSE proposals.
% MTSE can be integrated into any previous object proposal generators.
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
%   init_boxes  - [nx4] array containing initial bounding boxes [left top right bottom]
%   opts        - configuration for MTSE
% OUTPUTS
%   boxes       - [nx4] array containing proposals [left top right bottom]
%   scores      - [nx1] array containing proposal scores 
%
% Copyright 2015 Xiaozhi Chen (chenxz12@mails.tsinghua.edu.cn).
%

if nargin == 2
    opts.beta = 0.9;
    opts.combine = true;
end

% graph-based segmentation parameters
colorType = 'Lab';
sigma = 0.8;
K = 100;
minSize = K;

% multiple thresholds
thetas = 0.1:0.1:0.5;

% Remove Duplicates
init_boxes = removeBoxDuplicates(init_boxes);
    
% Change colour space. Using Lab color space get slightly better result
[~, img] = Image2ColourSpace(img, colorType);

% % Oversegmentation
[~, sp_boxes] = mexFelzenSegmentIndex(img, sigma, K, minSize);
sp_boxes = sp_boxes(:, [2 1 4 3]); % change to [x1 y1 x2 y2] order

% change to appropriate data type
sp_boxes = int32(sp_boxes);
init_boxes = int32(init_boxes(:,1:4));
thetas = single(thetas);

% MTSE       
bb_out = mtse_mex(sp_boxes, init_boxes, thetas, opts.beta, opts.combine);
boxes = bb_out(:, 1:4);
scores = bb_out(:, 5);

% Remove Duplicates
if opts.beta == 1
    [boxes, ids_rank] = removeBoxDuplicates(boxes);
    scores = scores(ids_rank);
end

