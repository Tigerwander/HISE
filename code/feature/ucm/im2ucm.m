function ucm2 = im2ucm(image,mode)
if nargin<2
    mode = 'fast';
end

% Load pre-trained Structured Forest model
load(fullfile(root_dir, 'data', 'model', 'sf_modelFinal.mat'));

if strcmp(mode,'fast')
    % Which scales to work on (MCG is [2, 1, 0.5], SCG is just [1])
    scales = 1;

    % Get the hierarchies at each scale and the global hierarchy
    ucm2 = img2ucms(image, model, scales);

elseif strcmp(mode,'accurate')
    % Which scales to work on (MCG is [2, 1, 0.5], SCG is just [1])
    scales = [2, 1, 0.5];

    % Get the hierarchies at each scale and the global hierarchy
    ucm2 = img2ucms(image, model, scales);
else
    error('Unknown mode for MCG: Possibilities are ''fast'' or ''accurate''')
end
