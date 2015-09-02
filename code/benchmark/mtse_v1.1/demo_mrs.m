% Demo for M-RS (MTSE using regular sampling for box initialization).
% M-RS is the simplest version of MTSE as it doesn't require any previous
% model to initialize bounding boxes.
% 
% Read README.txt before running this demo.

close all;

% example A
tic;
im = imread('peppers.png');
[boxes, scores] = run_mrs(im);
toc;

gt = [122,248,213,312;193,82,263,134;410,237,510,317;204,160,317,254;9,185,94,274;389,93,508,209;253,103,359,159;81,140,171,202];
illustrate(im, gt, boxes);

% example B
tic;
im = imread('data/000004.jpg');
[boxes, scores] = run_mrs(im);
toc;

gt = [13,311,84,362;362,330,500,389;235,328,334,375;175,327,252,364;139,320,189,359;108,325,150,353;84,323,121,350];
illustrate(im, gt, boxes);





