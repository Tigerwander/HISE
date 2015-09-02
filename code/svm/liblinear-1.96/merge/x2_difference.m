function [feature_diff]=x2_difference(feature_a,feature_b)
	%assert(size(feature_a)==size(feature_b));
	feature_diff=0;
	for ii=1:size(feature_a,2)
		sub=feature_a(ii)-feature_b(ii);
		plus=feature_a(ii)+feature_b(ii);
		feature_diff=feature_diff+sub^2/(plus+1-logical(plus));
	end
	feature_diff=feature_diff/2;
end
