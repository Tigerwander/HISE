function [Lab_image]=rgb2lab(rgb_image)
%Convert rgb format image to lab format image
	rgb = rgb_image; 
	cform = makecform('srgb2lab'); 
	lab = applycform(rgb, cform); 
	Lab_image = lab2double(lab);
end
