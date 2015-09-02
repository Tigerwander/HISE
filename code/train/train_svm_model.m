function train_svm_model(p,stage,branch)
	feature_file=sprintf('%s/svm_feature/stage_%d_%d.txt',p.data_path,stage,branch);
	model_file=sprintf('%s/model/stage_%d_%d.mat',p.data_path,stage,branch);
	if ~exist(feature_file,'file')
		disp(['data file has not been computed:',color_data_file]);
		return
	end
	if exist(model_file,'file')
		return
	end

	disp('loading data....');
	[train_y,train_x]=libsvmread(feature_file);
	disp('training svm model....')
	feature_model=train(train_y,train_x);
	save(model_file,'feature_model');
end

