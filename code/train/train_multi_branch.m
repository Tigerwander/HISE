function train_multi_branch(p,split,stage)
	model_file = sprintf('%s/model/stage_%d.mat',p.data_path,stage);
	if ~exist(model_file,'file')
		branch = p.branch;
		if ~exist(model_file,'file')
			feature = cell(p.branch,1);
			label = cell(p.branch,1);
			for ii = 1:branch
				[feature{ii},label{ii}] = extract_all_feature(p,split(ii,:),stage,ii);
			end
			w = multi_svm(p,feature,label);
			save(model_file,'w');
		end
	end
end

	
