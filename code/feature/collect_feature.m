%%extract all images' features
function collect_feature(p,stage,branch) 

	set_file = p.set_file;
	im_ids=load(set_file);
	image_num=length(im_ids);

	feature_file=sprintf('%s/svm_feature/stage_%d_%d.txt',p.data_path,stage,branch);
	feature_fid=fopen(feature_file,'w');
	for ii=1:image_num
		curr_file=sprintf('%s/feature/stage_%d_%d/%06d.txt',p.data_path,stage,branch,im_ids(ii));
		curr_fid=fopen(curr_file,'r');
		curr_content=fread(curr_fid,inf);
		fwrite(feature_fid,curr_content);
		fclose(curr_fid);
	end
	fclose(feature_fid);
end
