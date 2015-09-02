function [p] = get_paths()
	p.dataset_dir = '/home/lujianghu/Pascal/Datasets/Origin';
	p.train_set = 'train';
	p.test_set = 'test';
	p.train_sub_set = 'Segmentation';
	p.test_sub_set = 'Main';
	p.train_gt = 'trainval.txt';
	p.test_gt = 'test.txt';
	p.model = 'model';
	p.split = 'split';

	p.stage = 4;
	p.branch = 10;
	p.miss_rate = 0.7;
	p.feature_len = 4;


	p.data_dir = '/home/lujianghu/Pascal/Datasets/Data';
end
