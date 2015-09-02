function [region_features]=extract_region_feature(image,texton,superpixels)
% extract feature of every region,includes color historgram,sift,boundry feature
%Inputs
%	image: rgb format image
%	superpixels: initial segmentation of image
%Outputs
%	region_feature:include brightness L,color a and b,sift feature stored as cell format.

	%compute base apperance feature
	Lab_image=rgb2lab(image);
	L_hist=statistic_L_channel(Lab_image(:,:,1),superpixels);
	a_hist=statistic_ab_channel(Lab_image(:,:,2),superpixels);
	b_hist=statistic_ab_channel(Lab_image(:,:,3),superpixels);
	texton_hist=statistic_texton_channel(texton,superpixels);
	sift_hist=SiftTextureHist(superpixels,image);

	%assign apperance feature to every region
	region_features=cell(5,1);
	region_features{1}=L_hist;
	region_features{2}=a_hist;
	region_features{3}=b_hist;
	region_features{4}=texton_hist;
	region_features{5}=sift_hist;

	%{
	n_leaves=max(superpixels(:));
	region_features=cell(n_leaves,1);
	for ii=1:n_leaves
		feature=cell(5,1);
		feature{1}=L_hist(ii,:);
		feature{2}=a_hist(ii,:);
		feature{3}=b_hist(ii,:);
		feature{4}=texton_hist(ii,:);
		feature{5}=sift_hist(ii,:);
		region_features{ii}=feature;
	end
	%}
end
