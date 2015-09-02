% Run this script once before using MTSE

% set 'voc_dir' to the directory of voc images
voc_dir = '~/Documents/dataset/PASCAL/VOC2007/VOCdevkit/VOC2007/JPEGImages';
addpath(voc_dir);

% add subfolders
addpath('src');
addpath('utils');
addpath('evaluation');
addpath(genpath('dependencies'));

% compile mex function
mex ./src/private/mtse_mex.cpp -outdir ./src/private
mex ./src/private/mrs_mex.cpp -outdir ./src/private
mex ./dependencies/FelzenSegment/mexFelzenSegmentIndex.cpp -outdir ./dependencies/FelzenSegment