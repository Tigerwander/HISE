function train_multi()

	p = get_paths();
	stage = p.stage;
	branch = p.branch;
	miss_rate = p.miss_rate;
	
	data_dir = sprintf('%s/%d_%f',p.data_dir,p.feature_len,p.miss_rate);
	if ~exist(data_dir,'dir')
		mkdir(data_dir);
	end
	p.data_path = data_dir;
	feature_dir = fullfile(data_dir,'feature');
	if ~exist(feature_dir,'dir')
		mkdir(feature_dir);
	end
	svm_feature_dir = fullfile(data_dir,'svm_feature');
	if ~exist(svm_feature_dir,'dir')
		mkdir(svm_feature_dir);
	end
	model_dir = fullfile(data_dir,'model');
	if ~exist(model_dir,'dir')
		mkdir(model_dir);
	end
	superpixel_dir = sprintf('%s/superpixel_%s',data_dir,p.train_set)
	if ~exist(superpixel_dir,'dir')
		mkdir(superpixel_dir)
	end
	set_file = fullfile(p.dataset_dir,p.train_set,'ImageSets',p.train_sub_set,p.train_gt);
	p.set_file = set_file;

	split_dir = sprintf('%s/%s/split_%d',p.dataset_dir,p.split,p.feature_len);
	for ii=1:stage
		disp(['stage:',num2str(ii)])
		split_file=sprintf('%s/stage_%d.mat',split_dir,ii);
		load(split_file);
		for jj=1:branch
			disp(['branch:',num2str(jj)])
			extract_all_feature(p,split(jj,:),ii,jj);
			train_svm_model(p,ii,jj);
			feature2hier_all(p,ii,jj,split(jj,:),p.train_set);
		end
	end

	disp(['last stage']);
	split_file=sprintf('%s/stage_%d.mat',split_dir,stage+1);
	load(split_file);
	for jj=1:branch
		extract_all_feature(p,split(jj,:),stage + 1,jj);
		train_svm_model(p,stage + 1,jj);
	end
end

