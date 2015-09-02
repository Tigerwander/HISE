function [owt,superpixel,texton]=extract_property(image)
%%Extract owt and superpixels for every image 
%Input 
%	image: the rgb format image.

	%load structured forest model
	model_file=fullfile(root_dir,'datasets','model','sf_modelFinal.mat');
	load(model_file);
	[E,~,O]=edgesDetect(image,model);
	[owt,superpixel]=contours2OWT(E,O);
	superpixel=superpixel+1;
	image=double(image)/255;
	texton=mex_pb_parts_final_selected(image(:,:,1),image(:,:,2),image(:,:,3));
end

	
