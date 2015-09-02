function [opts, methods] = mtse_config(base_model)
% Configuration for MTSE
%
% INPUTS
%   base_model      - name of the baseline model (e.g., EB, MCG, BING, OBJ, 
%                     SS, RP, GOP)
% OUTPUTS
%   opts            - configuration for MTSE
%     (1) parameters required
%     .beta             - [0.9] NMS threshold controlling the number of 
%                       proposals. Typically, use 0.8 for objectness-based 
%                       models and 0.9 for similarity-based models
%     .combine          - [true] 'true': combine with baseline propoals; 
%                       'false': discard baseline proposals
%     (2) optional parameters, these are for regular sampling
%     .alpha            - [.4] step size of sliding window search
%     .maxAspectRatio   - [3] max aspect ratio of boxes
%     .minBoxArea       - [1000] minimum area of boxes
%   methods             - [1x2] struct containing the information of the
%                       baseline model and the corresponding MTSE mdoel.
%       

% save MTSE proposals to this directory
precomputed_prefix = 'proposals/mtse';

% MTSE parameters for different baseline models
switch base_model
    case {'BING', 'OBJ'}
        opts.beta = 0.8;
        opts.combine = false;
    case 'EB'
        opts.beta = 0.8;
        opts.combine = true;
    case 'RS'               
        % parameters for regular sampling
        opts.alpha = 0.4;
        opts.maxAspectRatio = 3;
        opts.minBoxArea = 1000;
        opts.beta = 0.8;
        opts.combine = false;
    otherwise         
        % default setting, used for most similarity-based models (e.g., 'MCG', 'RP', 'SS', 'GOP')
        opts.beta = 0.9;
        opts.combine = true;
end

% get configuration of baseline method
methods(1) = get_methods(base_model);

% configuration for MTSE proposals, refer to 'get_methods' to get the
% meanings of its variables
prefix = sprintf('%s/mtse_%s/', precomputed_prefix, base_model);
methods(2).name = sprintf('MTSE-%s', base_model);
methods(2).short_name = sprintf('M-%s', base_model);
methods(2).candidate_dir = [prefix 'mat'];
methods(2).best_voc07_candidates_file = [prefix 'best_candidates.mat'];
methods(2).order = 'descend';
methods(2).color = methods(1).color;
methods(2).is_baseline = false;


