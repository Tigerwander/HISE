function [ranking_bbox,I]=ranking(datasets,set_type,im_id)
	if nargin < 1
		datasets='Pascal_07_test';
		set_type='Main';
		im_id=000001;
	end
	image_file=sprintf('%s/datasets/%s/JPEGImages/%06d.jpg',root_dir,datasets,im_id);
	I=imread(image_file);
	bbox_file=sprintf('%s/benchmark/bbox/%06d.mat',root_dir,im_id);
	load(bbox_file);
	ranking_bbox=mex_ranking(bbox);
end
