%%extract all images' features
function extract_all_property(datasets,set_type,gt_set)
	if nargin<1
		datasets='Pascal_07_test';
		set_type='Main';
		gt_set='test.txt';
	end

	superpixel_dir=fullfile(root_dir,'datasets',datasets,'superpixel','stage_1_1');
	if ~exist(superpixel_dir,'dir')
		mkdir(superpixel_dir);
	end
	owt_dir=fullfile(root_dir,'datasets',datasets,'owt');
	if ~exist(owt_dir,'dir')
		mkdir(owt_dir);
	end
	texton_dir=fullfile(root_dir,'datasets',datasets,'texton');
	if ~exist(texton_dir,'dir')
		mkdir(texton_dir);
	end

	set_file=fullfile(root_dir,'datasets',datasets,'ImageSets',set_type,gt_set);
	im_ids=load(set_file);
	image_num=length(im_ids);
	matlabpool(8);
	parfor ii=1:image_num
		superpixel_file=sprintf('%s/%06d.mat',superpixel_dir,im_ids(ii));
		owt_file=sprintf('%s/%06d.mat',owt_dir,im_ids(ii));
		texton_file=sprintf('%s/%06d.mat',texton_dir,im_ids(ii));
		if exist(superpixel_file,'file')
			continue
		else
			image_file=sprintf('%s/datasets/%s/JPEGImages/%06d.jpg',root_dir,datasets,im_ids(ii));
			image=imread(image_file);
			[owt,superpixel,texton]=extract_property(image);
			parsave(superpixel_file,owt_file,texton_file,superpixel,owt,texton);
		end
	end
	matlabpool close
end

function parsave(superpixel_file,owt_file,texton_file,superpixel,owt,texton);
	save(superpixel_file,'superpixel');
	save(owt_file,'owt');
	save(texton_file,'texton');
end
