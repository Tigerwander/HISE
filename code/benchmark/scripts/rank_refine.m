function [bbox]=rank_refine(p,im_id)
	image_file=sprintf('%s/%s/JPEGImages/%06d.jpg',p.dataset_dir,p.test_set,im_id);
	I=imread(image_file);

	bbox_file=sprintf('%s/proposals/full/%06d.mat',p.data_path,im_id);
	load(bbox_file);

    opts.beta = 0.9;
    opts.combine = true;

    [bbox, scores] = run_mtse(I, bbox, opts);
	[bbox] = edge_refine(p,I,bbox);
end
