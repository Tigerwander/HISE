function [mean_strength]=compute_strength(owt,superpixel,region_a,region_b)
	[H,W]=size(superpixel);
	stats=regionprops(superpixel==region_a,'PixelList');
	a_list=stats.PixelList;
	vx=[1,0,-1,0];
	vy=[0,1,0,-1];
	border_strength=0;
	border_length=0;
	for ii=1:size(a_list,1)
		curr_pixel=a_list(ii,:);
		for jj=1:4
			temp_y=curr_pixel(2)+vy(jj);
			temp_x=curr_pixel(1)+vx(jj);
			if(temp_y>0 && temp_y<=H && temp_x>0 && temp_x<=W)
				if superpixel(temp_y,temp_x)==region_b
					border_strength = border_strength+owt(temp_y+curr_pixel(2)+1,temp_x+curr_pixel(1)+1);
					border_length = border_length+1;
				end
			end
		end
	end
	assert(border_length ~= 0);
	mean_strength=border_strength/border_length;
end

