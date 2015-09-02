function edge_all()
	p = get_paths();
	data_dir = sprintf('%s/%d_%f',p.data_dir,p.feature_len,p.miss_rate);
	p.data_path = data_dir

	set_file=fullfile(p.dataset_dir,p.test_set,'ImageSets',p.test_sub_set,p.test_gt);
	im_ids=load(set_file);
	image_num=length(im_ids);

	edge_bbox_dir=sprintf('%s/edge_bbox',data_dir);
	if ~exist(edge_bbox_dir,'dir')
		mkdir(edge_bbox_dir);
	end

	matlabpool(8);
	parfor ii=1:image_num
		bbox_file=sprintf('%s/%06d.mat',edge_bbox_dir,im_ids(ii));
		if exist(bbox_file,'file')
			continue
		else
			bbox=edge(p,im_ids(ii));
			parsave(bbox_file,bbox);
		end
	end
	matlabpool close
end

function parsave(bbox_file,bbox)
	save(bbox_file,'bbox');
end
