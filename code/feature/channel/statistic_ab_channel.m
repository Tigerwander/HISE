function [feature_hist]=statistic_ab_channel(channel,superpixels)
%statistic the value hist of a channel(may be color channel or brighness channel or texture channel)
%Input
%	channel:a certain channel of an image.
%	superpixels:an initial segmentation of an image
	nBin=32;
	bin_width=256/nBin;
	leaves=max(unique(superpixels(:)));
	feature_hist=zeros(leaves,nBin);
	region_area=zeros(leaves);
	[H,W]=size(channel);
	for ii=1:H
		for jj=1:W
			bin=min(floor((channel(ii,jj)+128)/bin_width)+1,nBin);
			instance_id=superpixels(ii,jj);
			region_area(instance_id)=region_area(instance_id)+1;
			feature_hist(instance_id,bin)=feature_hist(instance_id,bin)+1;
		end
	end
	for ii=1:leaves
		feature_hist(ii,:)=feature_hist(ii,:)/region_area(ii);
	end
end
