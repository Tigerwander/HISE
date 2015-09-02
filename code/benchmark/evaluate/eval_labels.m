function [intersection]=eval_labels(im_id,stage,branch)
	gt_file=sprintf('%s/benchmark/gt_bbox/%06d.xml',root_dir,im_id);
	bbox_file=sprintf('%s/benchmark/mtse_edge_bbox_%d_%d/%06d.mat',root_dir,stage,branch,im_id);
	bbox_file
	gt_bbox=load(gt_file);
	load(bbox_file);
	bbox_num=size(bbox,1);
	gt_num=size(gt_bbox,1);
	intersection=zeros(bbox_num,gt_num);
	for ii=1:bbox_num
		for jj=1:gt_num
			inter=bbox_inter(bbox(ii,:),gt_bbox(jj,:));
			union=bbox_union(bbox(ii,:),gt_bbox(jj,:));
			intersection(ii,jj)=inter/union;
		end
	end
end

function [inter]=bbox_inter(candidates,gt_bbox)
	bbox=zeros(1,4);
	bbox(1)=max(candidates(1),gt_bbox(1));
	bbox(2)=max(candidates(2),gt_bbox(2));
	bbox(3)=min(candidates(3),gt_bbox(3));
	bbox(4)=min(candidates(4),gt_bbox(4));

	if bbox(1)>bbox(3) | bbox(2)>bbox(4)
		inter=0;
	else
		inter=(bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);
	end
end

function [union]=bbox_union(candidates,gt_bbox)
	bbox=zeros(1,4);
	bbox(1)=min(candidates(1),gt_bbox(1));
	bbox(2)=min(candidates(2),gt_bbox(2));
	bbox(3)=max(candidates(3),gt_bbox(3));
	bbox(4)=max(candidates(4),gt_bbox(4));

	union=(bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);
end
