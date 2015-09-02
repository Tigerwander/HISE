function candidates_all(datasets,set_type,gt_set,stage,branch)
	if nargin < 1
		datasets='Pascal_07_test';
		set_type='Main';
		gt_set='test.txt';
		stage=4;
		branch=10;
	end

	set_file=fullfile(root_dir,'datasets',datasets,'ImageSets',set_type,gt_set);
	im_ids=load(set_file);
	image_num=length(im_ids);

	bbox_dir=sprintf('%s/benchmark/bbox_%d_%d',root_dir,stage,branch);
	if ~exist(bbox_dir,'dir')
		mkdir(bbox_dir);
	end

	matlabpool(8);
	parfor ii=1:image_num
		bbox_file=sprintf('%s/%06d.mat',bbox_dir,im_ids(ii));
		if exist(bbox_file,'file')
			continue
		else
			bbox=candidates(datasets,set_type,im_ids(ii),stage,branch);
			parsave(bbox_file,bbox);
		end
	end
	matlabpool close
end

function parsave(bbox_file,bbox)
	save(bbox_file,'bbox');
end
