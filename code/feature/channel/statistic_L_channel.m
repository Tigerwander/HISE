function [feature_hist]=statistic_L_channel(channel,superpixels)
%statistic the value hist of a channel(may be color channel or brighness channel or texture channel)
%Input
%	channel:a certain channel of an image.
%	superpixels:an initial segmentation of an image
	nBin=32;
	bin_width=floor(100/nBin);
	leaves=max(unique(superpixels(:)));
	feature_hist=zeros(leaves,nBin);
	[H,W]=size(channel);
	region_area=zeros(leaves,1);
	for ii=1:H
		for jj=1:W
			bin=min(floor(channel(ii,jj)/bin_width)+1,nBin);
			instance_id=superpixels(ii,jj);
			region_area(instance_id)=region_area(instance_id)+1;
			feature_hist(instance_id,bin)=feature_hist(instance_id,bin)+1;
		end
	end
	for ii=1:leaves
		feature_hist(ii,:)=feature_hist(ii,:)/region_area(ii);
	end
end
