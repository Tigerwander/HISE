function feature2hier_all(p,stage,branch,split,data_set)
	
	weight_file = sprintf('%s/model/stage_%d.mat',p.data_path,stage);
	load(weight_file);
	weight = w{branch};
	set_file = p.set_file;
	im_ids=load(set_file);
	image_num=length(im_ids);

	superpixel_dir=sprintf('%s/superpixel_%s/stage_%d_%d',p.data_path,data_set,stage+1,branch);
	if ~exist(superpixel_dir,'dir')
		mkdir(superpixel_dir);
	end
	
	matlabpool(8);
	parfor ii=1:image_num
		superpixel_file=sprintf('%s/%06d.mat',superpixel_dir,im_ids(ii));
		if exist(superpixel_file,'file')
			continue
		else
			superpixel=feature2hier(p,weight,stage,branch,im_ids(ii),split,data_set);
			parsave(superpixel_file,superpixel);
		end
	end
	matlabpool close
end

function parsave(superpixel_file,superpixel)
	save(superpixel_file,'superpixel');
end

