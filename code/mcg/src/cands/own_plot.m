I=imread('./data/images/img_5118.png');
gray=rgb2gray(I);
box=cpp(6,:);
for ii=box(2):box(4)
	gray(box(1),ii)=0;
	gray(box(3),ii)=0;
end
for ii=box(1):box(3)
	gray(ii,box(2))=0;
	gray(ii,box(4))=0;
end
imshow(gray)
