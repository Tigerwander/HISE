function extract_pair_feature(p,split,feature_file,stage,branch,image_id)
	
	%load image,segmentation
	image_file=sprintf('%s/%s/JPEGImages/%06d.jpg',p.dataset_dir,p.train_set,image_id);
	image=imread(image_file);
	segment_file=sprintf('%s/%s/SegmentationObject/%06d.png',p.dataset_dir,p.train_set,image_id);
	gt_segment=imread(segment_file);

	%load ucm and texton and owt
	owt_file=sprintf('%s/%s/owt/%06d.mat',p.dataset_dir,p.train_set,image_id);
	load(owt_file);
	texton_file=sprintf('%s/%s/texton/%06d.mat',p.dataset_dir,p.train_set,image_id);
	load(texton_file);
	if stage == 1
		superpixel_file=sprintf('%s/%s/superpixel/stage_%d_%d/%06d.mat',p.dataset_dir,p.train_set,stage,branch,image_id);
	else
		superpixel_file=sprintf('%s/superpixel_train/stage_%d_%d/%06d.mat',p.data_path,stage,branch,image_id);
	end
	load(superpixel_file);

	%assign every pair of adjacent region a label:0 or 1
	region_pairs=get_neighbors(superpixel);
	region_labels=grant_region_labels(superpixel,gt_segment);
	pair_map=grant_pair_labels(region_pairs,region_labels);

	%extract region feature
	region_features=extract_region_feature(image,texton,superpixel);
	
	n_leaves=max(superpixel(:));
	stats=regionprops(superpixel,'Area');
	region_area=zeros(n_leaves,1);
	for ii=1:n_leaves
		region_area(ii)=stats(ii).Area;
	end

	stats=regionprops(superpixel,'BoundingBox');
	region_bbox=zeros(n_leaves,4);
	for ii=1:n_leaves
		region_bbox(ii,:)=stats(ii).BoundingBox;
	end
	region_bbox(:,1:2)=ceil(region_bbox(:,1:2));
	region_bbox(:,3:4)=region_bbox(:,1:2)+region_bbox(:,3:4)-1;

	stats=regionprops(superpixel,'PixelList');
	region_pixel=cell(n_leaves,1);
	for ii=1:n_leaves
		region_pixel{ii}=stats(ii).PixelList;
	end

	%%extract pair feature
	pair_features=cell(2,1);
	for ii=1:size(pair_map,1)
		region_pair=pair_map(ii-1);
		curr_size=size(region_pair,1);
		for jj=1:curr_size
			region_a=region_pair(jj,1);
			region_b=region_pair(jj,2);
			curr_feature=compute_feature(owt,superpixel,region_features,region_area,region_bbox,region_pixel,region_a,region_b);
			pair_features{ii}(jj,:)=curr_feature;
		end
	end
	feature_map=containers.Map({0,1},{pair_features{1},pair_features{2}});

	%save feature in svm format
	parsave(feature_file,feature_map,split);
end


function [pair_feature]=compute_feature(owt,superpixel,region_features,region_area,region_bbox,region_pixel,region_a,region_b);
	%%Appearance feature
	%brightness,color and sift x2 difference
	assert(size(region_features,1)==5);
	L_diff=x2_difference(region_features{1}(region_a,:),region_features{1}(region_b,:));
	a_diff=x2_difference(region_features{2}(region_a,:),region_features{2}(region_b,:));
	b_diff=x2_difference(region_features{3}(region_a,:),region_features{3}(region_b,:));
	texton_diff=x2_difference(region_features{4}(region_a,:),region_features{4}(region_b,:));
	sift_diff=x2_difference(region_features{5}(region_a,:),region_features{5}(region_b,:));

	%%shape feature
	%area
	area=region_area(region_a)+region_area(region_b);

	%boundingbox area
	bbox_a=region_bbox(region_a,:);
	bbox_b=region_bbox(region_b,:);
	bbox=zeros(1,4);
	bbox(1,1)=min(bbox_a(1),bbox_b(1));
	bbox(1,2)=min(bbox_a(2),bbox_b(2));
	bbox(1,3)=max(bbox_a(3),bbox_b(3));
	bbox(1,4)=max(bbox_a(4),bbox_b(4));
	bbox_area=(bbox(1,3)-bbox(1,1)+1)*(bbox(1,4)-bbox(1,2)+1);

	%area_ratio, try to force small regions merge early
	[H,W]=size(superpixel);
	image_area=H*W;
	area_ratio=1-area/image_area;

	%fill_ratio, try to avoid bigger region eatting smaller region
	fill_ratio=1-(bbox_area-area)/image_area;

	%%Boundry feature,mainly the mean strength between region_a and region_b
	pixel_a=region_pixel{region_a};
	vx=[1,0,-1,0];
	vy=[0,1,0,-1];
	border_strength=0;
	border_length=0;
	for ii=1:size(pixel_a,1)
		curr_pixel=pixel_a(ii,:);
		for jj=1:4
			temp_y=curr_pixel(2)+vy(jj);
			temp_x=curr_pixel(1)+vx(jj);
			if(temp_y>0 && temp_y<=H && temp_x>0 && temp_x<=W)
				if superpixel(temp_y,temp_x)==region_b
					border_strength = border_strength+owt(temp_y+curr_pixel(2)+1,temp_x+curr_pixel(1)+1);
					border_length = border_length+1;
				end
			end
		end
	end
	assert(border_length ~= 0);
	mean_strength=border_strength/border_length;
	pair_feature=[L_diff,a_diff,b_diff,texton_diff,sift_diff,area_ratio,fill_ratio,mean_strength];
end

function [feature_diff]=x2_difference(feature_a,feature_b)
	feature_diff=0;
	for ii=1:size(feature_a,2)
		sub=feature_a(ii)-feature_b(ii);
		plus=feature_a(ii)+feature_b(ii);
		feature_diff=feature_diff+sub^2/(plus+1-logical(plus));
	end
	feature_diff=feature_diff/2;
end

function parsave(feature_file,feature_map,split)
	fid=fopen(feature_file,'w');
	for ii=1:2
		feature=feature_map(ii-1);
		feature_num=size(feature,1);
		feature_dim=size(feature,2);
		feature_label=logical(ii-1)+ii-2;
		for jj=1:feature_num
			fprintf(fid,'%d ',feature_label);
			curr_feature = feature(jj,:);
			part_feature = curr_feature(split);
			for kk=1:size(part_feature,2)
				fprintf(fid,'%d:%f ',kk,part_feature(kk));
			end
			fprintf(fid,'\n');
		end
	end
end
