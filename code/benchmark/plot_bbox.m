function plot_bbox(I,bbox)
	figure(2)
	I=rgb2gray(I);
	size(I)
	for ii=1:size(bbox,1)
		bbox(ii,:)
		for jj=bbox(ii,1):bbox(ii,3)
			I(bbox(ii,2),jj)=255;
			I(bbox(ii,4),jj)=255;
		end
		for jj=bbox(ii,2):bbox(ii,4)
			I(jj,bbox(ii,1))=255;
			I(jj,bbox(ii,3))=255;
		end
		imshow(I);
	end
end
