function mtse_all(datasets,set_type,gt_set,stage,branch)
	if nargin < 1
		datasets='Pascal_07_test';
		set_type='Main';
		gt_set='test.txt';
		stage = 4;
		branch = 10;
	end

	set_file=fullfile(root_dir,'datasets',datasets,'ImageSets',set_type,gt_set);
	im_ids=load(set_file);
	image_num=length(im_ids);

	rank_dir=sprintf('%s/benchmark/mtse_bbox_%d_%d',root_dir,stage,branch);
	if ~exist(rank_dir,'dir')
		mkdir(rank_dir);
	end

	matlabpool(8);
	parfor ii=1:image_num
		bbox_file=sprintf('%s/%06d.mat',rank_dir,im_ids(ii));
		if exist(bbox_file,'file')
			continue
		else
			bbox=mtse(datasets,set_type,im_ids(ii),stage,branch);
			parsave(bbox_file,bbox);
		end
	end
	matlabpool close
end

function parsave(bbox_file,bbox)
	save(bbox_file,'bbox');
end
