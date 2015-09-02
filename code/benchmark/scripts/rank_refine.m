function [bbox]=rank_refine(p,im_id)
	image_file=sprintf('%s/%s/JPEGImages/%06d.jpg',p.dataset_dir,p.test_dir,im_id);
	I=imread(image_file);

	bbox_file=sprintf('%s/proposals/bbox_%d_%d/%06d.mat',root_dir,stage,branch,im_id);
	load(bbox_file);

    opts.beta = 0.9;
    opts.combine = true;

    [bbox, scores] = run_mtse(I, bbox, opts);
	[bbox] = edge(p,I,bbox)
end
