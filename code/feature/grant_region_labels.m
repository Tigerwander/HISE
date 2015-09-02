function [region_labels]=grant_region_labels(superpixel,segment_object)
	segment_object(segment_object==255)=0;
	object_num=length(unique(segment_object));
	segment_object(segment_object==0)=object_num;
	leaves_num=length(unique(superpixel));
	intersection=zeros(leaves_num,object_num);
	[H,W]=size(segment_object);
	for ii=1:H
		for jj=1:W
			leave=superpixel(ii,jj);
			object=segment_object(ii,jj);
			intersection(leave,object)=intersection(leave,object)+1;
		end
	end
	region_labels=zeros(leaves_num,1);
	[~,index]=max(intersection,[],2);
	region_labels=index;
	region_labels(region_labels==object_num)=0;
end
	
