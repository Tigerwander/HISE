function split_feature(stage,branch,split)
	feature_file=sprintf('%s/svm/data/stage_%d_%d.txt',root_dir,stage,branch);
	if ~exist(feature_file,'file')
		disp(['feature has not been computed '],feature_file);
		return
	end

	part_file=sprintf('%s/svm/feature/stage_%d_%d.txt',root_dir,stage,branch);
	if exist(part_file,'file')
		return
	end

	split

	feature_fid=fopen(feature_file,'r');
	part_fid=fopen(part_file,'w');
	while ~feof(feature_fid)
		line=fgetl(feature_fid);
		line=deblank(line);
		list=regexp(line,'\s+','split');
		label=list{1};
		fprintf(part_fid,'%s ',label);
		feature=zeros(1,8);
		feature_iter=1;
		for ii=2:9
			if split(feature_iter)==ii-1
				item=list{ii};
				feature_value=item(findstr(item,':')+1:end);
				fprintf(part_fid,'%d:%s ',feature_iter,feature_value);
				feature_iter=feature_iter+1;
				if feature_iter > size(split,2)
					break;
				end
			end
		end
		fprintf(part_fid,'\n');
	end
	fclose(part_fid);
end
