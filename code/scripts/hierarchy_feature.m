function hierarchy_feature(p,stage,branch,split)
	
	set_file = p.set_file;
	im_ids=load(set_file);
	image_num=length(im_ids);
	image_num

	bbox_dir=sprintf('%s/bbox/stage_%d_%d',p.data_path,stage,branch);
	if ~exist(bbox_dir,'dir')
		mkdir(bbox_dir);
	end
	
	matlabpool(8);
	parfor ii=1:image_num
		bbox_file=sprintf('%s/%06d.mat',bbox_dir,im_ids(ii));
		if exist(bbox_file,'file')
			continue
		else
			bbox=feature_bbox(p,stage,branch,im_ids(ii),split);
			parsave(bbox_file,bbox);
		end
	end
	matlabpool close
end

function parsave(bbox_file,bbox)
	save(bbox_file,'bbox');
end

