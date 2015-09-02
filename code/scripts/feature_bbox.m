function [bbox]=feature_bbox(p,stage,branch,im_id,split)
	[~,ms_matrix]=feature2hier(p,stage,branch,im_id,split,p.test_set);
	superpixel_file=sprintf('%s/superpixel_%s/stage_%d_%d/%06d.mat',p.data_path,p.test_set,stage,branch,im_id);

	load(superpixel_file);
	leaves_num=length(unique(superpixel));

	bbox=zeros(leaves_num*2-1,4);
	assert(size(ms_matrix,1)==leaves_num-1);

	% bbox format: xmin,ymin,xmax,ymax
	stats=regionprops(superpixel,'BoundingBox');
	for ii=1:leaves_num
		bbox(ii,:)=stats(ii).BoundingBox;
		bbox(ii,1:2)=ceil(bbox(ii,1:2));
		bbox(ii,3:4)=bbox(ii,1:2)+bbox(ii,3:4)-1;
	end
	for ii=1:leaves_num-1
		assert(ms_matrix(ii,3)==ii+leaves_num);
		bbox(ii+leaves_num,:)=merge_bbox(bbox(ms_matrix(ii,1),:),bbox(ms_matrix(ii,2),:));
	end
	bbox=bbox(leaves_num+1:end,:);
end

function [bbox]=merge_bbox(bbox_1,bbox_2)
	bbox=zeros(1,4);
	bbox(1)=min(bbox_1(1),bbox_2(1));
	bbox(2)=min(bbox_1(2),bbox_2(2));
	bbox(3)=max(bbox_1(3),bbox_2(3));
	bbox(4)=max(bbox_1(4),bbox_2(4));
end




	
