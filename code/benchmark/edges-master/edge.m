function [bbs,I]=edge(datasets,set_type,im_id)
	if nargin < 1
		datasets='Pascal_07_test';
		set_type='Main';
		im_id=79;
	end
	image_file=sprintf('%s/datasets/%s/JPEGImages/%06d.jpg',root_dir,datasets,im_id);
	I=imread(image_file);
	bbox_file=sprintf('%s/benchmark/mtse_bbox_4_10/%06d.mat',root_dir,im_id);
	load(bbox_file);
	bbox=double(bbox);
	%% load pre-trained edge detection model and set opts (see edgesDemo.m)
	model_file=sprintf('%s/datasets/model/modelBsds.mat',root_dir);
	model=load(model_file); model=model.model;
	model.opts.multiscale=0; model.opts.sharpen=2; model.opts.nThreads=4;

	%% set up opts for edgeBoxes (see edgeBoxes.m)
	opts = edgeBoxes;
	opts.alpha = .65;     % step size of sliding window search
	opts.beta  = .75;     % nms threshold for object proposals
	opts.minScore = .01;  % min score of boxes to detect
	opts.maxBoxes = 1e4;  % max number of boxes to detect

	%% detect Edge Box bounding box proposals (see edgeBoxes.m)
	bbs=edgeBoxes(I,model,bbox,opts);
	bbs(:,3:4)=bbs(:,1:2)+bbs(:,3:4)-1;
end

function bbs = edgeBoxes( I, model,bbox, varargin)
	% get default parameters (unimportant parameters are undocumented)
	dfs={'name','', 'alpha',.65, 'beta',.75, 'eta',1, 'minScore',.01, ...
	  'maxBoxes',1e4, 'edgeMinMag',.1, 'edgeMergeThr',.5,'clusterMinMag',.5,...
	  'maxAspectRatio',3, 'minBoxArea',1000, 'gamma',2, 'kappa',1.5 };
	o=getPrmDflt(varargin,dfs,1); if(nargin==0), bbs=o; return; end
	%bbs=edgeBoxsImg(I,model,o,bbox);
	bbs=edgeBoxImg(I,model,o,bbox);
end

function bbs = edgeBoxImg( I, model, o,bbox )
	% Generate Edge Boxes object proposals in single image.
	if(all(ischar(I))), I=imread(I); end
	model.opts.nms=0; [E,O]=edgesDetect(I,model);
	if(0), E=gradientMag(convTri(single(I),4)); E=E/max(E(:)); end
	E=edgesNmsMex(E,O,2,0,1,model.opts.nThreads);
	bbs=edgeBoxesMex(E,O,o.alpha,o.beta,o.eta,o.minScore,o.maxBoxes,...
	  o.edgeMinMag,o.edgeMergeThr,o.clusterMinMag,...
	  o.maxAspectRatio,o.minBoxArea,o.gamma,o.kappa,bbox);
end
