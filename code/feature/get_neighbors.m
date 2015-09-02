function [neighbor_pairs,neighbor_pairs_size]=get_neighbors(superpixels)
% From a segmentation,Get all pairs of neighboring leave regions
% Inputs
%	superpixels:the initial segmentation

%Outputs
%	neighbor_pairs:the all neighbors of all regions in superpixels 
%	neighbor_pairs_size:the neighbor num of all regions in superpixels

	[~, idx_neighbors] = seg2gridbmap(superpixels);
	K = max(idx_neighbors.matrix_max(:)) + 1;
	neigh_pairs = unique(idx_neighbors.matrix_min+K*idx_neighbors.matrix_max);
	neigh_pairs(neigh_pairs==0) = [];
	neigh_pairs_min = mod(neigh_pairs,K);
	neigh_pairs_max = (neigh_pairs-neigh_pairs_min)/K;

	if isrow(neigh_pairs_min)
		neigh_pairs_min = neigh_pairs_min';
	end
	if isrow(neigh_pairs_max)
		neigh_pairs_max = neigh_pairs_max';
	end

	leaves=max(superpixels(:));
	neighbor_pairs=cell(leaves,1);
	neighbor_pairs_size=zeros(leaves,1);
	for ii=1:size(neigh_pairs_min,1)
		min_id=neigh_pairs_min(ii,1);
		max_id=neigh_pairs_max(ii,1);
		neighbor_pairs_size(min_id,1) = neighbor_pairs_size(min_id,1) + 1;
		neighbor_pairs_size(max_id,1) = neighbor_pairs_size(max_id,1) + 1;
		neighbor_pairs{min_id}(neighbor_pairs_size(min_id,1))=max_id;
		neighbor_pairs{max_id}(neighbor_pairs_size(max_id,1))=min_id;
	end
end
