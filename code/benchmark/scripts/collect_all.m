function collect_all()
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
				bbox=collect_one(p,br,im_ids(ii));
				parsave(bbox_file,bbox);
			end
		end
		matlabpool close
	end

	full_dir = sprintf('%s/proposals/full',data_dir);
	if ~exist(full_dir,'dir')
		mkdir(full_dir);
	end
	for ii = 1:image_num
		full_dir
		im_ids(ii)
		full_file = sprintf('%s/%06d.mat',full_dir,im_ids(ii));
		full_file
		if exist(full_file,'file')
			continue;
		end
		curr_bbox = [];
		for jj = 1:branch
			bbox_file=sprintf('%s/%d/%06d.mat',proposal_dir,jj,im_ids(ii));
			load(bbox_file);
			curr_bbox = [curr_bbox;bbox];
		end
		bbox = curr_bbox;
		parsave(full_file,bbox);
	end
end
																															function parsave(bbox_file,bbox)
	save(bbox_file,'bbox');
end
