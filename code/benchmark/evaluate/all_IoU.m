IoU = 0.1:0.1:0.9;
for ii = 1:length(IoU)
	benchmark(IoU(ii));
end
