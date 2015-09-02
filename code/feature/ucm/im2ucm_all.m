% ------------------------------------------------------------------------ 
%  Copyright (C)
%  Universitat Politecnica de Catalunya BarcelonaTech (UPC) - Spain
%  University of California Berkeley (UCB) - USA
% 
%  Jordi Pont-Tuset <jordi.pont@upc.edu>
%  Pablo Arbelaez <arbelaez@berkeley.edu>
%  June 2014
% ------------------------------------------------------------------------ 
% This file is part of the MCG package presented in:
%    Arbelaez P, Pont-Tuset J, Barron J, Marques F, Malik J,
%    "Multiscale Combinatorial Grouping,"
%    Computer Vision and Pattern Recognition (CVPR) 2014.
% Please consider citing the paper if you use this code.
% ------------------------------------------------------------------------
%
% Script to compute MCG or SCG UCMs on a whole dataset
%
% ------------------------------------------------------------------------
function im2ucm_all(mode, data_set)
if nargin==0
    mode = 'fast';
end
if nargin<2
    data_set = 'full';
end

% Create out folder
if strcmp(mode,'fast')
    ucm_dir = fullfile(root_dir,'data','ucm','SCG-ucm');
elseif strcmp(mode,'accurate')
    ucm_dir = fullfile(root_dir,'data','ucm','MCG-ucm');
else
    error('Unknown mode for MCG: Possibilities are ''fast'' or ''accurate''')
end
if ~exist(ucm_dir,'dir')
    mkdir(ucm_dir);
end
    
% Which images to process
load(fullfile(root_dir,'data','id_set',[data_set '.mat']));
image_num=length(data_set);

% Sweep all images and process them in parallel
matlabpool(8);
parfor ii=1:image_num

	%ucm file
	ucm_file=sprintf('%s/img_%04d.mat',ucm_dir,5000+data_set(ii));

	if exist(ucm_file,'file')
		continue
	else
		% Read image
		image_file=sprintf('%s/data/images/img_%04d.png',root_dir,5000+data_set(ii));
		image=imread(image_file);

        % Call the actual code
        ucm = im2ucm(image, mode);
        
        % Store ucms at each scale separately
        parsave(ucm_file,ucm)
    end
end
matlabpool close

end


function parsave(res_file,ucm) %#ok<INUSD>
    save(res_file,'ucm');
end
