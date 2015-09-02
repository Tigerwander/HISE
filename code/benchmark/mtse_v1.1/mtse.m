function [boxes]=mtse(datasets,set_type,im_id,stage,branch)
	if nargin < 1
		datasets='Pascal_07_test';
		set_type='Main';
		im_id=79;
	end
	image_file=sprintf('%s/datasets/%s/JPEGImages/%06d.jpg',root_dir,datasets,im_id);
	I=imread(image_file);

	bbox_file=sprintf('%s/benchmark/bbox_%d_%d/%06d.mat',root_dir,stage,branch,im_id);
	load(bbox_file);

    opts.beta = 0.9;
    opts.combine = true;

    [boxes, scores] = run_mtse(I, bbox, opts);
end
