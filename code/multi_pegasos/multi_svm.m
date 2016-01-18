function w = multi_svm(p,Data,label)
	svm_num = p.branch;
	feature_size = p.feature_len;
	w = cell(svm_num,1);
	for ii = 1:svm_num
		tmpW = randn(feature_size + 1,1);
		tmpW = tmpW/norm(tmpW);
		w{ii} = tmpW;
	end
	eps = 5e-2;
	iterNum = 100;
	iter = 1;
	stopCondition = false;
	while(iter < iterNum & ~stopCondition)
		disp(['iter:',num2str(iter)])
		w_prev = w;
		iter = iter + 1;
		eps_sum = 0;
		for ii = 1:svm_num
			w{ii} = PegasosSVM(Data{ii},label{ii},w,ii,p);
			eps_sum = eps_sum + norm(w{ii} - w_prev{ii})/norm(w_prev{ii});
		end
		eps_sum
		if eps_sum < eps
			stopCondition = true;
		end
	end
end


