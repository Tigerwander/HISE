function drawBox(I,bbox)
	bbox(3)=bbox(1)+bbox(3)-1;
	bbox(4)=bbox(2)+bbox(4)-1;
	for ii=bbox(1):bbox(3)
		I(bbox(2),ii)=255;
		I(bbox(4),ii)=255;
	end
	for ii=bbox(2):bbox(4)
		I(ii,bbox(1))=255;
		I(ii,bbox(3))=255;
	end
	imshow(I);
end
