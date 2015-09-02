% Demo for MTSE
% Read README.txt before running this demo.

%% Select a baseline model for box initialization
% base_model      - name of a baseline model (e.g., EB, MCG, BING, OBJ,
%                 SS, RP, GOP).
base_model = '';

%% Generate MTSE proposals for VOC2007 test set
[opts, methods] = mtse_config(base_model);
baseline = methods(1);
dirname = methods(2).candidate_dir;

% default to running on the full test set
testset = load('data/pascal_voc07_test_annotations.mat');
images = {testset.impos.im};
clear testset;

tot_time = 0;
for i = 1 : length(images)
    tic_toc_print('image: %d / %d\n', i, length(images));    
    
    id = images{i};    
    subdir = id(1:4);
    path = fullfile(dirname, subdir);
    if ~exist(path, 'dir')
        mkdir(path);
    end
    matfile = fullfile(dirname, subdir, sprintf('%s.mat', id));
    if exist(matfile, 'file')
        continue;
    end
    
    % get initial bounding boxes
    init_boxes = get_candidates(baseline, id, 10000);
    
    t1 = tic();
    im = imread([images{i}, '.jpg']);
    if size(im, 3) == 1
      im = repmat(im, [1 1 3]);
    end           
    
    [boxes, scores] = run_mtse(im, init_boxes, opts);
    tot_time = tot_time + toc(t1);
    
    save_candidates_mat(dirname, id, boxes, scores);
end
fprintf('average time: %f\n', tot_time/length(images));

%% evaluation
eval_voc07(methods);



