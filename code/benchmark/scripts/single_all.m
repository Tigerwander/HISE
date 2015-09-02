function single_all()
	p = get_paths();
	data_dir = sprintf('%s/%d_%f',p.data_dir,p.feature_len,p.miss_rate);
	p.data_path = data_dir

	set_file=fullfile(p.dataset_dir,p.test_set,'ImageSets',p.test_sub_set,p.test_gt);
	im_ids=load(set_file);
	image_num=length(im_ids);

	proposal_dir=sprintf('%s/proposals',data_dir);
	if ~exist(proposal_dir,'dir')
		mkdir(proposal_dir);
	end
	branch = p.branch;

	for br = 1:branch
		curr_dir = sprintf('%s/%d',proposal_dir,br);
		if ~exist(curr_dir,'dir')
			mkdir(curr_dir);
		end
		matlabpool(8);
		parfor ii=1:image_num
			bbox_file=sprintf('%s/%06d.mat',curr_dir,im_ids(ii));
			if exist(bbox_file,'file')
				continue
			else
				bbox=single_one(p,br,im_ids(ii));
				parsave(bbox_file,bbox);
			end
		end
		matlabpool close
	end
end
																															function parsave(bbox_file,bbox)
	save(bbox_file,'bbox');
end
