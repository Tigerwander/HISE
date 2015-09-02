function [pair_map]=grant_pair_labels(region_pairs,region_labels)
% grant every pair of adjacent regions with label 1 or -1
%Inputs
%	region_pairs:all neighbors of all regions,the neighbor ids of every region is stored in a cell
%	region_labels:the corresponding label relative to groundtruth instance for every region
%Outputs
%	pair_map:labeled pairs,stored as a map

	assert(size(region_pairs,1)==size(region_labels,1));
	pair_labels=cell(2,1);
	pair_nums=zeros(2,1);
	for ii=1:size(region_pairs,1)
		curr_id=ii;
		curr_label=region_labels(curr_id);
		for jj=1:size(region_pairs{curr_id},2)
			neighbor_id=region_pairs{curr_id}(jj);
			neighbor_label=region_labels(neighbor_id);
			if neighbor_id > curr_id
				if curr_label ~= neighbor_label
					pair_nums(1)=pair_nums(1)+1;
					pair_labels{1}(pair_nums(1),:)=[curr_id,neighbor_id];
				elseif curr_label ~= 0
					pair_nums(2)=pair_nums(2)+1;
					pair_labels{2}(pair_nums(2),:)=[curr_id,neighbor_id];
				end
			end
		end
	end
	pair_map=containers.Map({0,1},{pair_labels{1},pair_labels{2}});
end

