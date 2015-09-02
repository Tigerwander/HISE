Multi-Thresholding Straddling Expansion (MTSE)
Copyright 2015 Xiaozhi Chen (chenxz12@mails.tsinghua.edu.cn).

---------------------------------------------------------------------------
1. Introduction
MTSE can be used to improve the accuracy of most existing object proposal generation models with little computation overhead.
If you use MTSE, please cite the following paper:

@inproceedings{cvpr15mtse,
  author    = {Xiaozhi Chen and Huimin Ma and Xiang Wang and Zhichen Zhao},
  title     = {Improving Object Proposals with Multi-Thresholding Straddling Expansion},
  booktitle = {IEEE CVPR},
  year      = {2015},
}

---------------------------------------------------------------------------
2. Installation

1) Edit 'startup.m' to point to the right locations for VOC images.
2) Run 'startup.m' to compile the mex functions and set up directories.

---------------------------------------------------------------------------
3. Demo for M-RS
M-RS is the a variant of MTSE using regular sampling (RS) for box initialization. It's fast and doesn't require any previous model for box initialization.

Run 'demo_mrs.m' to know the basic usage of M-RS.

---------------------------------------------------------------------------
4. Evaluation
If you only want to evaluate MTSE proposals, follow these steps:

1) Download precomputed MTSE proposals (e.g., M-MCG) from our project page (http://3dimage.ee.tsinghua.edu.cn/cxz/mtse).
2) Unzip it into folder 'proposals/mtse'.
3) Run:
	[~, methods] = mtse_config('MCG');
	eval_voc07(methods(2));
	
Operation is similar for other MTSE proposals (e.g., M-EB, M-RS).

---------------------------------------------------------------------------
5. Demo for MTSE
MTSE can be integrated into any previous object proposal generators. We provide configurations for seven baselines:
EB, MCG, BING, OBJ, SS, RP, GOP. To run their MTSE integrated versions, follow these steps:

1) Download precomputed baseline proposals (e.g., MCG) from our project page (http://3dimage.ee.tsinghua.edu.cn/cxz/mtse) or from J. Hosang's benchmark page (http://www.mpi-inf.mpg.de/departments/computer-vision-and-multimodal-computing/research/object-recognition-and-scene-understanding/how-good-are-detection-proposals-really/).
2) Unzip it into folder 'proposals/baseline'.
3) Run 'demo_mtse.m'.

---------------------------------------------------------------------------
6. Improve your own object proposals 
To apply MTSE to your own object proposals, follow these steps:

1) Edit 'get_methods.m' to add information of your own proposals.
2) Edit 'demo_mtse.m' to set variable 'base_model' to the name of your method.
3) Run 'demo_mtse.m'.

Optionally, you may edit 'mtse_config.m' to set NMS threshold 'beta' to get a desired number of proposals.

---------------------------------------------------------------------------
7. Acknowledgements
We used P. Dollar's code for regular sampling and P. Felzenszwalb's code for graph-based segmentation. We also modified codes from J. Hosang's benchmark for evaluation. Thanks J. Hosang for providing numerous object proposals in a standardized format.

