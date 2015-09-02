function [feature_hist]=statistic_texton_channel(channel,superpixels)
%statistic the value hist of a channel(may be color channel or brighness channel or texture channel)
%Input
%	channel:a certain channel of an image.
%	superpixels:an initial segmentation of an image
	nBin=32;
	leaves=max(unique(superpixels(:)));
	feature_hist=zeros(leaves,nBin);
	[H,W]=size(channel);
	region_area=zeros(leaves,1);
	for ii=1:H
		for jj=1:W
			bin=channel(ii,jj)+1;
			instance_id=superpixels(ii,jj);
			region_area(instance_id)=region_area(instance_id)+1;
			feature_hist(instance_id,bin)=feature_hist(instance_id,bin)+1;
		end
	end
	for ii=1:leaves
		feature_hist(ii,:)=feature_hist(ii,:)/region_area(ii);
	end
end
