function [mean_num]=mean_bbox(datasets,set_type,gt_set)
	if nargin < 1
		datasets='Pascal_07_test';
		set_type='Main';
		gt_set='test.txt';
	end

	set_file=fullfile(root_dir,'datasets',datasets,'ImageSets',set_type,gt_set);
	im_ids=load(set_file);
	image_num=length(im_ids);

	bbox_dir=sprintf('%s/benchmark/bbox_4_15',root_dir);
	bbox_dir

	bbox_total=0;
	for ii=1:image_num
		bbox_file=sprintf('%s/%06d.mat',bbox_dir,im_ids(ii));
		load(bbox_file);
		bbox_total = bbox_total + size(bbox,1);
	end

	mean_num=bbox_total/image_num;
end

	
