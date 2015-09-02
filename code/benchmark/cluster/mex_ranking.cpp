// ------------------------------------------------------------------------ 
//  Copyright (C)
//  Universitat Politecnica de Catalunya BarcelonaTech (UPC) - Spain
//  University of California Berkeley (UCB) - USA
// 
//  Jordi Pont-Tuset <jordi.pont@upc.edu>
//  Pablo Arbelaez <arbelaez@berkeley.edu>
//  June 2014
// ------------------------------------------------------------------------ 
// This file is part of the MCG package presented in:
//    Arbelaez P, Pont-Tuset J, Barron J, Marques F, Malik J,
//    "Multiscale Combinatorial Grouping,"
//    Computer Vision and Pattern Recognition (CVPR) 2014.
// Please consider citing the paper if you use this code.
// ------------------------------------------------------------------------
#include "mex.h"
#include "matlab_multiarray.hpp"
#include <iostream>
#include <list>
#include <set>
#include <map>
#include <fstream>
#include <algorithm>

using namespace std;
typedef pair<string,double> string_pair;
struct string_CmpByValue{
	bool operator()(const string_pair& lhs,const string_pair& rhs){
		return lhs.second>rhs.second;
	}
};

typedef pair<int,int> int_pair;
struct int_CmpByValue{
	bool operator()(const int_pair& lhs,const int_pair& rhs){
		return lhs.second>rhs.second;
	}
};

double Jaccard_distance(vector<unsigned int> bbox_1, vector<unsigned int> bbox_2)
{
	//bbox: xmin,ymin,xmax,ymax
	unsigned int x_min=max(bbox_1[0],bbox_2[0]);
	unsigned int y_min=max(bbox_1[1],bbox_2[1]);
	unsigned int x_max=min(bbox_1[2],bbox_2[2]);
	unsigned int y_max=min(bbox_1[3],bbox_2[3]);

	if(y_min >= y_max || x_min >= x_max)
		return 0;

	double bbox_overlap=(y_max-y_min)*(x_max-x_min);

	x_min=min(bbox_1[0],bbox_2[0]);
	y_min=min(bbox_1[1],bbox_2[1]);
	x_max=max(bbox_1[2],bbox_2[2]);
	y_max=max(bbox_1[3],bbox_2[3]);

	double bbox_union=(y_max-y_min)*(x_max-x_min);

	return bbox_overlap/bbox_union;
}


void find_centroids(vector< vector<unsigned int> > bbox,vector<unsigned int>& groups)
{

	double threshold=0.7;

	for(size_t ii=0;ii<groups.size();++ii)
		groups[ii]=ii;

	//compute distance
	map<string,double> distance_map;
	char buffer[1024];
	for(size_t ii=0;ii<groups.size()-1;++ii)
	{
		for(size_t jj=ii+1;jj<groups.size();++jj)
		{
			double distance=Jaccard_distance(bbox[ii],bbox[jj]);
			if(distance>0.2)
			{
				sprintf(buffer,"%d#%d",ii,jj);
				distance_map.insert(make_pair(buffer,distance));
			}
		}
	}

	vector<string_pair> distance_vec(distance_map.begin(),distance_map.end());
	sort(distance_vec.begin(),distance_vec.end(),string_CmpByValue());
	if(distance_vec.size()==0)
		return;

	vector<string_pair>::iterator vec_iter=distance_vec.begin();
	while(1)
	{
		if(vec_iter->second<threshold)
			break;
		string curr_str=vec_iter->first;
		size_t found=curr_str.find("#");
		if(found==string::npos)
			cout<<"Some errors happend";
		int first=atoi(curr_str.substr(0,found).c_str());
		int second=atoi(curr_str.substr(found+1).c_str());
		
		if(groups[first]!=groups[second])
		{
			for(size_t ii=0;ii<groups.size();++ii)
			{
				if(groups[ii]==groups[second])
					groups[ii]=groups[first];
			}
		}
		++vec_iter;
	}
}

void ranking_bbox(vector< vector<unsigned int> > bbox, vector<unsigned int> groups, vector< vector<unsigned int> >& rank_bbox)
{
	map<unsigned int, int> count_map;
	map<unsigned int,vector<unsigned int> > bbox_map;
	for(int ii=0;ii<groups.size();++ii)
	{
		if(bbox_map.find(groups[ii])!=bbox_map.end())
		{
			assert(count_map.find(groups[ii])!=count_map.end());
			for(int jj=0;jj<4;++jj)
				bbox_map[groups[ii]][jj] += bbox[ii][jj];
			count_map[groups[ii]] += 1;
		}
		else
		{
			bbox_map.insert(make_pair(groups[ii],bbox[ii]));
			count_map.insert(make_pair(groups[ii],1));
		}
	}

	vector<int_pair> count_vec(count_map.begin(),count_map.end());
	sort(count_vec.begin(),count_vec.end(),int_CmpByValue());

	vector<int_pair>::iterator vec_iter=count_vec.begin();
	for( ;vec_iter!=count_vec.end();++vec_iter)
	{
		vector<unsigned int> curr_bbox=bbox_map[vec_iter->first];
		for(int jj=0;jj<4;++jj)
			curr_bbox[jj]/=double(vec_iter->second);
		rank_bbox.push_back(curr_bbox);
	}
}

void mexFunction( int nlhs, mxArray *plhs[], 
        		  int nrhs, const mxArray*prhs[] )
{
    if(nrhs!=1)
        mexErrMsgTxt("There should be 1 input parameters");
    
    /* Input parameters */
    ConstMatlabMultiArray<double> bbox_src(prhs[0]);

    std::size_t bbox_num   = bbox_src.shape()[0];
    std::size_t bbox_size   = bbox_src.shape()[1];

	vector< vector<unsigned int> > bbox(bbox_num);
	for(size_t ii=0;ii<bbox_num;++ii)
	{
		for(size_t jj=0;jj<bbox_size;++jj)
			bbox[ii].push_back(bbox_src[ii][jj]);
	}

	vector<unsigned int> groups(bbox_num,0);

	find_centroids(bbox,groups);

	vector< vector<unsigned int> > rank_bbox;

	ranking_bbox(bbox,groups,rank_bbox);
	

    /*-----------------------------------------------------------*/
   
    /* Output allocation */
    plhs[0] = mxCreateDoubleMatrix(rank_bbox.size(),bbox_size,mxREAL);
    MatlabMultiArray<double> out_bbox(plhs[0]);
    
    /* Copy data to output */
    for (size_t ii=0; ii<rank_bbox.size(); ++ii)
	{
		for(size_t jj=0;jj<bbox_size;++jj)
			out_bbox[ii][jj]=rank_bbox[ii][jj];
	}
}
    
