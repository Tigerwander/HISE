function benchmark()

	p = get_paths();
	data_dir = sprintf('%s/%d_%f',p.data_dir,p.feature_len,p.miss_rate);
	p.data_path = data_dir

	set_file=fullfile(p.dataset_dir,p.test_set,'ImageSets',p.test_sub_set,p.test_gt);
	im_ids=load(set_file);
	image_num=length(im_ids);

	intersection_dir=sprintf('%s/intersection',p.data_path);
	if ~exist(intersection_dir,'dir')
		mkdir(intersection_dir);
	end

	matlabpool(8);
	parfor ii=1:image_num
		intersection_file=sprintf('%s/%06d.mat',intersection_dir,im_ids(ii));
		if exist(intersection_file,'file')
			continue
		else
			intersection=eval_labels(p,im_ids(ii));
			parsave(intersection_file,intersection);
		end
	end
	matlabpool close
	

	cands=[1,10,50,100, 200, 500,1000,2000,4000,5000,8000,10000];
	precision=zeros(image_num,length(cands));
	for ii=1:image_num
		intersection_file=sprintf('%s/%06d.mat',intersection_dir,im_ids(ii));
		load(intersection_file);
		gt_num=size(intersection,2);
		for jj=1:length(cands)
			curr_intersection=intersection(1:min(cands(jj),size(intersection,1)),:);
			for kk=1:gt_num
				max_inter=max(curr_intersection(:,kk));
				if max_inter > p.IoU
					precision(ii,jj)=precision(ii,jj)+1;
				end
			end
		end
		precision(ii,:)=precision(ii,:)/gt_num;
	end

	precision_file=sprintf('%s/result/%d_%d_%d_%.2f_%.2f.mat',p.data_dir,p.stage,p.branch,p.merge,p.IoU);
	save(precision_file,'precision');

	rmdir(intersection_dir,'s');

	%plot 
	%plot(cands,mean(precision),'r');

end

function parsave(curr_file,intersection)
	save(curr_file,'intersection');
end


