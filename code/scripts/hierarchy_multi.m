function hierarchy_multi()

	p = get_paths();
	stage = p.stage;
	branch = p.branch;
	miss_rate = p.miss_rate;

	data_dir = sprintf('%s/%d_%f',p.data_dir,p.feature_len,p.miss_rate);
	if ~exist(data_dir,'dir')
		mkdir(data_dir);
	end
	p.data_path = data_dir;

	superpixel_dir = sprintf('%s/superpixel_%s',data_dir,p.test_set);
	if ~exist(superpixel_dir,'dir')
		mkdir(superpixel_dir);
	end
	bbox_dir = fullfile(data_dir,'bbox');
	if ~exist(bbox_dir,'dir')
		mkdir(bbox_dir);
	end

	set_file = fullfile(p.dataset_dir,p.test_set,'ImageSets',p.test_sub_set,p.test_gt);
	p.set_file = set_file;
	p

	split_dir = sprintf('%s/%s/split_%d',p.dataset_dir,p.split,p.feature_len);

	for ii=1:stage
		%generate curr split mode.
		split_file=sprintf('%s/stage_%d.mat',split_dir,ii);
		load(split_file);
		for jj=1:branch
			disp(['stage:',num2str(ii),'  branch:',num2str(jj)]);
			feature2hier_all(p,ii,jj,split(jj,:),p.test_set);
		end
	end

	disp(['last stage']);
	p.miss_rate=0;
	split_file=sprintf('%s/stage_%d.mat',split_dir,stage+1);
	load(split_file);
	for jj=1:branch
		hierarchy_feature(p,stage+1,jj,split(jj,:));
	end
end

