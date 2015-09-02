function [boxes]=mtse(datasets,set_type,im_id,stage,branch)
	image_file=sprintf('%s/datasets/%s/JPEGImages/%06d.jpg',root_dir,datasets,im_id);
	I=imread(image_file);

	bbox_file=sprintf('%s/benchmark/bbox_%d_%d/%06d.mat',root_dir,stage,branch,im_id);
	load(bbox_file);

    opts.beta = 0.9;
    opts.combine = true;

    [boxes, scores] = run_mtse(I, bbox, opts);
end
