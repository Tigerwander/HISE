function [total_bbox]=single_one(p,branch,im_id)
	total_bbox=[];
	for ii=2:stage+1
		superpixel_file=sprintf('%s/superpixel_test/stage_%d_%d/%06d.mat',p.data_path,ii,branch,im_id);
		load(superpixel_file);
		bbox=superpixel2bbox(superpixel);
		total_bbox=[total_bbox;bbox];
	end
	bbox_file=sprintf('%s/bbox/stage_%d_%d/%06d.mat',p.data_path,stage+1,branch,im_id);
	load(bbox_file);
	total_bbox=[total_bbox;bbox];

	total_bbox=BoxRemoveDuplicates(total_bbox);
end

function [bbox]=superpixel2bbox(superpixel)
	leaves_num=length(unique(superpixel));
	stats=regionprops(superpixel,'BoundingBox');
	for ii=1:leaves_num
		bbox(ii,:)=stats(ii).BoundingBox;
		bbox(ii,1:2)=ceil(bbox(ii,1:2));
		bbox(ii,3:4)=bbox(ii,1:2)+bbox(ii,3:4)-1;
	end
end
