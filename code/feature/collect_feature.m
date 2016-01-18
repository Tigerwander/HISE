%%extract all images' features
function [feature,label] = collect_feature(p,stage,branch) 

	set_file = p.set_file;
	im_ids=load(set_file);
	image_num=length(im_ids);

	feature_file=sprintf('%s/svm_feature/stage_%d_%d.txt',p.data_path,stage,branch);
	if ~exist(feature_file,'file')
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

	tmp = load(feature_file);
	label = tmp(:,1)';
	feature = tmp(:,2:size(tmp,2)); 
	feature(:,size(tmp,2)) = 1;
	feature = feature';
end
