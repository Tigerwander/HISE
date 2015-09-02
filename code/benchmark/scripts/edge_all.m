function edge_all(datasets,set_type,gt_set)
	if nargin < 1
		datasets='Pascal_07_test';
		set_type='Main';
		gt_set='test.txt';
	end

	set_file=fullfile(root_dir,'datasets',datasets,'ImageSets',set_type,gt_set);
	im_ids=load(set_file);
	image_num=length(im_ids);

	rank_dir=sprintf('%s/benchmark/edge_bbox_10',root_dir);
	if ~exist(rank_dir,'dir')
		mkdir(rank_dir);
	end

	matlabpool(8);
	parfor ii=1:image_num
		bbox_file=sprintf('%s/%06d.mat',rank_dir,im_ids(ii));
		if exist(bbox_file,'file')
			continue
		else
			bbox=edge(datasets,set_type,im_ids(ii));
			parsave(bbox_file,bbox);
		end
	end
	matlabpool close
end

function parsave(bbox_file,bbox)
	save(bbox_file,'bbox');
end
