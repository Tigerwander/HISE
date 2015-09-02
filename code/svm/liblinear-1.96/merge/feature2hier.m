function [superpixel,ms_matrix]=feature2hier(p,stage,branch,image_id,split,data_set) 
%%Extract adjacent region features

	miss_rate = p.miss_rate;
	split=split';

	%load svm model
	model_file=sprintf('%s/model/stage_%d_%d.mat',p.data_path,stage,branch);
	load(model_file);

	%load image
	image_file=sprintf('%s/%s/JPEGImages/%06d.jpg',p.dataset_dir,data_set,image_id);
	image=imread(image_file);

	%load owt and superpixel and texton 
	owt_file=sprintf('%s/%s/owt/%06d.mat',p.dataset_dir,data_set,image_id);
	load(owt_file);
	if stage == 1
		superpixel_file=sprintf('%s/%s/superpixel/stage_%d_%d/%06d.mat',p.dataset_dir,data_set,stage,branch,image_id);
	else
		superpixel_file=sprintf('%s/superpixel_%s/stage_%d_%d/%06d.mat',p.data_path,data_set,stage,branch,image_id);
	end
	load(superpixel_file);
	texton_file=sprintf('%s/%s/texton/%06d.mat',p.dataset_dir,data_set,image_id);
	load(texton_file);

	%get neighbors
	[~, idx_neighbors] = seg2gridbmap(superpixel);
	K = max(idx_neighbors.matrix_max(:)) + 1;
	neigh_pairs = unique(idx_neighbors.matrix_min+K*idx_neighbors.matrix_max);
	neigh_pairs(neigh_pairs==0) = [];
	neigh_pairs_min = mod(neigh_pairs,K);
	neigh_pairs_max = (neigh_pairs-neigh_pairs_min)/K;
	if isrow(neigh_pairs_min)
		neigh_pairs_min = neigh_pairs_min';
	end
	if isrow(neigh_pairs_max)
		neigh_pairs_max = neigh_pairs_max';
	end

	%extract region feature
	region_feature=extract_region_feature(image,texton,superpixel);
	
	%compute the area of every superpixel
	stats=regionprops(superpixel,'Area');
	region_area=zeros(size(stats,1),1);
	for ii=1:size(stats,1)
		region_area(ii)=stats(ii).Area;
	end

	%Bounding box
	stats=regionprops(superpixel,'BoundingBox');
	region_bbox=zeros(size(stats,1),4);
	for ii=1:size(stats,1)
		region_bbox(ii,:)=stats(ii).BoundingBox;
	end
	region_bbox(:,1:2)=ceil(region_bbox(:,1:2));
	region_bbox(:,3:4)=region_bbox(:,1:2)+region_bbox(:,3:4)-1;

	ms_matrix=mex_feature(region_feature{1},region_feature{2},region_feature{3},region_feature{4},region_feature{5},region_area,region_bbox,owt,superpixel-1,neigh_pairs_min-1,neigh_pairs_max-1,miss_rate,split,feature_model);

	superpixel=merge_superpixel(superpixel,ms_matrix);
end

function [superpixel]=merge_superpixel(superpixel,ms_matrix)
	merge_num=size(ms_matrix,1);
	for ii=1:merge_num
		superpixel(superpixel==ms_matrix(ii,1) | superpixel==ms_matrix(ii,2))=ms_matrix(ii,3);
	end
	ori_index=unique(superpixel(:));
	index_num=size(ori_index,1);
	for ii=1:index_num
		superpixel(superpixel==ori_index(ii))=ii;
	end
end
	
