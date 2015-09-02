%%extract all images' features
function extract_all_feature(p,split,stage,branch)
	set_file = p.set_file;
	im_ids=load(set_file);
	image_num=length(im_ids);

	feature_dir = sprintf('%s/feature/stage_%d_%d',p.data_path,stage,branch);
	if ~exist(feature_dir,'dir')
		mkdir(feature_dir);
	end

	matlabpool(8);
	parfor ii=1:image_num
		feature_file=sprintf('%s/%06d.txt',feature_dir,im_ids(ii));
		if exist(feature_file,'file')
			continue
		else
			extract_pair_feature(p,split,feature_file,stage,branch,im_ids(ii));
		end
	end
	matlabpool close

	collect_feature(p,stage,branch)
end

