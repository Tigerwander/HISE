function w = PegasosSVM(Data, Label,weight,id, param)
	% training binary SVM via stochastic subgradient descent 
	% Data     nDim x nSample
	% Label    1 x nSample, with entry of {+1, -1}
	% solving the problem
	%          (lambda/2)*|| w ||^2 + (1/nSample) * sum Loss(w; (x, y)), 
	%               where Loss is hinge loss, x is instance, y is label
	%
	% by Kui Jia, shared with Lin on Aug. 7, 2014

	[nDim, nSample] = size(Data);

	lambda = 1;
	batchSize = 1;
	%maxEpoch = (2000/lambda) / (nSample/batchSize);
	maxEpoch = 100;
	constant = matrix_square(weight,id);
	%constant
	eps = 1e-3;

	% initialize as any vector with || w || <= 1/sqrt(lambda)
	%w = weight{id}
	w = weight{id};
	lambda = 0.001;
	normBallConst = 1/sqrt(lambda) ; 
	w = normBallConst * w / norm(w) ;

	gamma = 1;

	epoch = 0;
	iter = 0;
	stopCondition = false;
	while (epoch <= maxEpoch) && (~stopCondition)
		%epoch
		%w'
		w_prev = w;
		epoch = epoch + 1;
		
		tmpidx = randperm(nSample); % randomize data in each epoch
		Data = Data(:, tmpidx);
		Label = Label(:, tmpidx);
		
		for idx = 1:(nSample/batchSize)
			iter = iter + 1;
			
			batchData = Data(:, (idx-1)*batchSize+1:idx*batchSize);
			batchLabel = Label(1, (idx-1)*batchSize+1:idx*batchSize);
			
			% choosing samples from batchData which have non-zero loss
			tmpidx = find( batchLabel.*(w' * batchData) < 1 ) ;
			nUsedBatchSample = length(tmpidx);
			if nUsedBatchSample > 0 
				batchData = batchData(:, tmpidx);
				batchLabel = batchLabel(1, tmpidx);
				
				% update eta
				eta = 1 / (lambda*iter) ; % alternatively, eta = eta_0 / (1 + lambda*eta_0*iter), with a proper eta_0
				
				% update w
				%w = (eye(length(w)) - eta*lambda - 2 * 0.001 * constant) * w + (eta/nUsedBatchSample)*sum( bsxfun(@times, batchData, batchLabel), 2);
				w = ((1 - 1 / iter) * eye(length(w)) - (gamma / iter) * constant) * w + (eta/nUsedBatchSample)*sum( bsxfun(@times, batchData, batchLabel), 2);
				%w = (1 - eta*lambda) * w + (eta/nUsedBatchSample)*sum( bsxfun(@times, batchData, batchLabel), 2);
				
				% projecting onto the 1/sqrt(lambda) ball
				w = min(1, normBallConst/norm(w)) * w ;
			end
		end
		weight{id} = w;
		
		%{
		%new stoping condition
		min_val = 0
		for ii = 1:length(weight)
			min_val = min_val + w' * weight{ii};
		end
		min_val
		%}

		% stopping conditin
		tmp = norm(w - w_prev) / norm(w_prev) ;
		if tmp < eps
			stopCondition = true;
		end
	end
end

function [constant] = matrix_square(weight,id)
	svm_size = size(weight,1);
	Dim = size(weight{1},1);
	tmp = zeros(Dim,Dim);
	for ii = 1:svm_size 
		if(ii ~= id)
			tmp = tmp + weight{ii} * weight{ii}';
		end
	end
	constant = tmp;
end




