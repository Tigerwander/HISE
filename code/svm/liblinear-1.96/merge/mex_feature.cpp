#include "mex.h"
#include "matlab_multiarray.hpp"
#include <fstream>
#include <iostream>
#include <list>
#include <map>
#include <iomanip>
#include <set>
#include <algorithm>
#include <time.h>
#include "linear.h"
#include "linear_model_matlab.h"
#define Malloc(type,n) (type *)malloc((n)*sizeof(type))

using namespace std;

struct bdry{
	int bdry_length;
	double bdry_strength;
};

typedef map<double,list<set<unsigned int> > > map_type; 
double compute_feature(vector<double> feature_1,vector<double> feature_2)
{
	double simi_value=0;
	vector<double>::iterator feat_1_it=feature_1.begin();
	vector<double>::iterator feat_2_it=feature_2.begin();
	for( ;feat_1_it!=feature_1.end(),feat_2_it!=feature_2.end();++feat_1_it,++feat_2_it)
		simi_value+=min(*feat_1_it,*feat_2_it);
	return simi_value;
}

double compute_size(int reg_a, int reg_b, int reg_full)
{
	return 1-(double(reg_a+reg_b)/double(reg_full));
}

double compute_fill(vector<unsigned int> box_a, vector<unsigned int> box_b,int reg_a, int reg_b, int reg_full)
{
	size_t x_min=min(box_a[0],box_b[0]);
	size_t x_max=max(box_a[2],box_b[2]);
	size_t y_min=min(box_a[1],box_b[1]);
	size_t y_max=max(box_a[3],box_b[3]);
	int area=(x_max-x_min)*(y_max-y_min);
	return 1-(double(area-reg_a-reg_b)/double(reg_full));
}

double insert_pair(map_type& similarity,double simi_value,size_t id_a,size_t id_b)
{
	set<unsigned int> pair_region;
	pair_region.insert(id_a);
	pair_region.insert(id_b);

	if(similarity.find(simi_value)==similarity.end())
	{				
		list<set<unsigned int> > pair_list;
		pair_list.push_back(pair_region);
		similarity.insert(make_pair(simi_value,pair_list));
	}
	else
		similarity[simi_value].push_back(pair_region);
}

double compute_simi(vector<double> FeatureHist_1,vector<double> FeatureHist_2, int area_1,int area_2,int img_area,vector<unsigned int> box_1,vector<unsigned int> box_2)
{
	double simi_value=0;
	simi_value+=compute_feature(FeatureHist_1,FeatureHist_2);
	simi_value+=compute_size(area_1,area_2,img_area);
	simi_value+=compute_fill(box_1,box_2,area_1,area_2,img_area);
	return simi_value;
}

double x2_difference(vector<double> feature_1,vector<double> feature_2)
{
	double simi_value=0;
	vector<double>::iterator feat_1_it=feature_1.begin();
	vector<double>::iterator feat_2_it=feature_2.begin();
	for( ;feat_1_it!=feature_1.end(),feat_2_it!=feature_2.end();++feat_1_it,++feat_2_it)
	{
		double minus=*feat_1_it-*feat_2_it;
		double plus=*feat_1_it+*feat_2_it;
		if(plus!=0)	
			simi_value+=minus*minus/plus;
	}
	return simi_value/2;
}

double svm_predict(double weight[],vector<vector<double> > full_L_Hist,vector<vector<double> > full_a_Hist,vector<vector<double> > full_b_Hist,vector<vector<double> > full_t_Hist,vector<vector<double> > full_s_Hist,unsigned int reg_a,unsigned int reg_b)
{
	double L_x2=x2_difference(full_L_Hist[reg_a],full_L_Hist[reg_b]);
	double a_x2=x2_difference(full_a_Hist[reg_a],full_a_Hist[reg_b]);
	double b_x2=x2_difference(full_b_Hist[reg_a],full_b_Hist[reg_b]);
	double t_x2=x2_difference(full_t_Hist[reg_a],full_t_Hist[reg_b]);
	//double s_x2=x2_difference(full_s_Hist[reg_a],full_s_Hist[reg_b]);

	double decision_value=0;
	decision_value += L_x2*weight[1];
	decision_value += a_x2*weight[2];
	decision_value += b_x2*weight[3];
	decision_value += t_x2*weight[4];
	//decision_value += s_x2*weight[5];
	return decision_value;
}
	
			
void region_merge(vector<double>& feature_obj,vector<double> feature_1,vector<double> feature_2,int area_obj,int area_1,int area_2)
{
	vector<double>::iterator it_1=feature_1.begin();
	vector<double>::iterator it_2=feature_2.begin();
	for( ;it_1 != feature_1.end(),it_2!=feature_2.end(); ++it_1,++it_2)
	{
		double feat_value=(*it_1)*area_1+(*it_2)*area_2;
		feature_obj.push_back(feat_value/(double)area_obj);
	}
}

void vec_difference(vector<unsigned int> vec_1,vector<unsigned int> vec_2, vector<unsigned int>& vec_diff)
{
	vec_diff.resize(vec_1.size());
	vector<unsigned int>::iterator it=set_difference(
			vec_1.begin(),vec_1.end(),
			vec_2.begin(),vec_2.end(),
			vec_diff.begin());
	vec_diff.resize(it-vec_diff.begin());
}

void vec_union(vector<unsigned int> vec_1,vector<unsigned int> vec_2, vector<unsigned int>& vec_uni)
{
	vec_uni.resize(vec_1.size()+vec_2.size());
	vector<unsigned int>::iterator it=set_union(vec_1.begin(),vec_1.end(),
												vec_2.begin(),vec_2.end(),vec_uni.begin());
	vec_uni.resize(it-vec_uni.begin());
}

void insert_neighbor(map<unsigned int,set<unsigned int> >& neighbors,unsigned int object_id,unsigned int neighbor_id)
{	
	map<unsigned int,set<unsigned int> >::iterator map_iter=neighbors.find(object_id);
	if(map_iter==neighbors.end())
	{
		set<unsigned int> set_neigh;
		set_neigh.insert(neighbor_id);
		neighbors.insert(make_pair(object_id,set_neigh));
	}
	else
	{
		set<unsigned int>& set_neigh=map_iter->second;
		set_neigh.insert(neighbor_id);
	}
}

void remove_neighbor(map<unsigned int,set<unsigned int> >& neighbors,unsigned int reg_a,unsigned int reg_b)
{
	map<unsigned int,set<unsigned int> >::iterator neighbor_iter,tmp_iter;
	set<unsigned int>::iterator set_iter;

	//assert(neighbors.find(reg_a)!=neighbors.end());
	set_iter=neighbors[reg_a].begin();
	for( ;set_iter!=neighbors[reg_a].end();++set_iter)
	{
		//assert(neighbors.find(*set_iter)!=neighbors.end());
		neighbors[*set_iter].erase(reg_a);
	}

	//assert(neighbors.find(reg_b)!=neighbors.end());
	set_iter=neighbors[reg_b].begin();
	for( ;set_iter!=neighbors[reg_b].end();++set_iter)
	{
		//assert(neighbors.find(*set_iter)!=neighbors.end());
		neighbors[*set_iter].erase(reg_b);
	}

	//assert(neighbors.find(reg_a)!=neighbors.end());
	neighbors.erase(reg_a);
	//assert(neighbors.find(reg_b)!=neighbors.end());
	neighbors.erase(reg_b);
}
	
void union_neighbor(set<unsigned int> neighbor_a,set<unsigned int> neighbor_b,
					set<unsigned int>& neighbor_c)
{	
	set<unsigned int>::iterator set_iter;
	set_iter=neighbor_a.begin();
	for( ;set_iter!=neighbor_a.end();++set_iter)
		neighbor_c.insert(*set_iter);
	set_iter=neighbor_b.begin();
	for( ;set_iter!=neighbor_b.end();++set_iter)
		neighbor_c.insert(*set_iter);
}

void update_neighbor(map<unsigned int,set<unsigned int> >& neighbors,unsigned int reg_id,set<unsigned int> reg_neighbor)
{
	neighbors.insert(make_pair(reg_id,reg_neighbor));
	map<unsigned int,set<unsigned int> >::iterator neighbor_iter;
	set<unsigned int>::iterator set_iter;
	set_iter=reg_neighbor.begin();
	for(;set_iter!=reg_neighbor.end();++set_iter)
	{
		if(neighbors.count(*set_iter)==0)
		{
			exit(-1);
		}
		else
			neighbors[*set_iter].insert(reg_id);
	}
}

void compute_bbox(vector<unsigned int> bbox_a,vector<unsigned int> bbox_b,unsigned int bbox[])
{
	bbox[0]=min(bbox_a[0],bbox_b[0]);
	bbox[1]=min(bbox_a[1],bbox_b[1]);
	bbox[2]=max(bbox_a[2],bbox_b[2]);
	bbox[3]=max(bbox_a[3],bbox_b[3]);
}

void update_bdry(map<unsigned int,map<unsigned int,struct bdry> >& bdry_map,map<unsigned int,set<unsigned int> > neighbor_map,unsigned int curr_id,unsigned int reg_a,unsigned int reg_b)
{
	// add bdry revelant to curr_id
	map<unsigned int,struct bdry> curr_bdry;
	set<unsigned int>::iterator it;
	set<unsigned int> neighbor_a,neighbor_b;

	neighbor_a=neighbor_map[reg_a];
	for(it=neighbor_a.begin();it!=neighbor_a.end();++it)
	{
		if(*it!=reg_b)
		{
			//assert(curr_bdry.find(*it)==curr_bdry.end());
			curr_bdry.insert(make_pair(*it,bdry_map[reg_a][*it]));
			//assert(bdry_map[*it].find(curr_id)==bdry_map[*it].end());
			bdry_map[*it].insert(make_pair(curr_id,bdry_map[reg_a][*it]));
		}
	}

	neighbor_b=neighbor_map[reg_b];
	for(it=neighbor_b.begin();it!=neighbor_b.end();++it)
	{
		if(*it!=reg_a)
		{
			if(curr_bdry.find(*it)==curr_bdry.end())
			{
				curr_bdry.insert(make_pair(*it,bdry_map[reg_b][*it]));
				//assert(bdry_map[*it].find(curr_id)==bdry_map[*it].end());
				bdry_map[*it].insert(make_pair(curr_id,bdry_map[reg_b][*it]));
			}
			else
			{
				curr_bdry[*it].bdry_strength += bdry_map[reg_b][*it].bdry_strength;
				curr_bdry[*it].bdry_length += bdry_map[reg_b][*it].bdry_length;

				//assert(bdry_map[*it].find(curr_id)!=bdry_map[*it].end());
				bdry_map[*it][curr_id].bdry_strength += bdry_map[reg_b][*it].bdry_strength;
				bdry_map[*it][curr_id].bdry_length += bdry_map[reg_b][*it].bdry_length;
			}
		}
	}
	
	//assert(bdry_map.find(curr_id)==bdry_map.end());
	bdry_map.insert(make_pair(curr_id,curr_bdry));

	//remove bdry revelant to reg_a and reg_b
	neighbor_a=neighbor_map[reg_a];
	for(it=neighbor_a.begin();it!=neighbor_a.end();++it)
	{
		//assert(bdry_map[*it].find(reg_a)!=bdry_map[*it].end());
		bdry_map[*it].erase(reg_a);
	}	

	neighbor_b=neighbor_map[reg_b];
	for(it=neighbor_b.begin();it!=neighbor_b.end();++it)
	{
		//assert(bdry_map[*it].find(reg_b)!=bdry_map[*it].end());
		bdry_map[*it].erase(reg_b);
	}	

	bdry_map.erase(reg_a);
	bdry_map.erase(reg_b);
}

void mexFunction( int nlhs, mxArray *plhs[], 
        		  int nrhs, const mxArray*prhs[] )
{   

	/* Input parameters */

	if(nrhs!=14)
        mexErrMsgTxt("There should be exactly 14 input parameters");
    ConstMatlabMultiArray<double> L_Hist(prhs[0]);
    ConstMatlabMultiArray<double> a_Hist(prhs[1]);
    ConstMatlabMultiArray<double> b_Hist(prhs[2]);
    ConstMatlabMultiArray<double> t_Hist(prhs[3]);
    ConstMatlabMultiArray<double> s_Hist(prhs[4]);
    ConstMatlabMultiArray<double> region_area(prhs[5]);
    ConstMatlabMultiArray<double> region_bbox(prhs[6]);
    ConstMatlabMultiArray<double> owt(prhs[7]);
    ConstMatlabMultiArray<double> superpixel(prhs[8]);
    ConstMatlabMultiArray<double> neigh_pairs_min(prhs[9]);
    ConstMatlabMultiArray<double> neigh_pairs_max(prhs[10]);
    ConstMatlabMultiArray<double> miss(prhs[11]);
    ConstMatlabMultiArray<double> split_ori(prhs[12]);
    ConstMatlabMultiArray<double> w(prhs[13]);

    std::size_t n_leaves= L_Hist.shape()[0];
	std::size_t L_size  = L_Hist.shape()[1];
	std::size_t a_size  = a_Hist.shape()[1];
	std::size_t b_size  = b_Hist.shape()[1];
	std::size_t t_size  = t_Hist.shape()[1];
	std::size_t s_size  = s_Hist.shape()[1];

	std::size_t n_pairs    = neigh_pairs_min.shape()[0];
	std::size_t n_regs     = n_leaves*2-1;
	std::size_t sx=superpixel.shape()[0];
	std::size_t sy=superpixel.shape()[1];

	double image_area=sx*sy;
	double miss_rate=miss[0][0];
	int miss_thr=int(miss_rate*n_leaves);
	int merge_num=n_leaves-miss_thr-1;


	    // *********************************************************************************
    //   Compute the neighbors of each region
    // *********************************************************************************
    // Prepare cells to store results
	map<unsigned int,set<unsigned int> > neighbors;
    
	//Initialize weight
	vector<double> weight;
	int w_size = w.shape()[0];
	for(int ii = 0;ii < w_size; ++ ii)
		weight.push_back(w[ii][0]);


	//Initialize split
	int split[8]={0};
	int split_num=split_ori.shape()[0];
	for(int ii=0;ii<split_num;++ii)
		split[int(split_ori[ii][0]-1)]=1;


    // Add initial pairs
    for (std::size_t ii=0; ii<n_pairs; ++ii)
    {
        unsigned int min_id = neigh_pairs_min[ii][0];
        unsigned int max_id = neigh_pairs_max[ii][0];        
		insert_neighbor(neighbors,min_id,max_id);
		insert_neighbor(neighbors,max_id,min_id);
    }


	//Initial bdry
	map<unsigned int,map<unsigned int,struct bdry> > bdry_map;
	int vx[4]={1,0,-1,0};
	int vy[4]={0,1,0,-1};
	for(int ii=0;ii<sx;++ii)
	{
		for(int jj=0;jj<sy;++jj)
		{
			unsigned int curr_id=superpixel[ii][jj];
			for(int kk=0;kk<4;++kk)
			{
				unsigned int curr_x=ii+vx[kk];
				unsigned int curr_y=jj+vy[kk];
				if((curr_x>=0) && (curr_x<sx) && (curr_y>=0) && (curr_y<sy) && (curr_id!=superpixel[curr_x][curr_y]))
				{
					unsigned int neighbor_id=superpixel[curr_x][curr_y];
					if(bdry_map.find(curr_id)==bdry_map.end())
					{
						struct bdry curr_bdry={0,0};
						curr_bdry.bdry_length += 1;
						curr_bdry.bdry_strength += owt[ii+curr_x+1][jj+curr_y+1];
						map<unsigned int,struct bdry> tmp_map;
						tmp_map.insert(make_pair(neighbor_id,curr_bdry));
						bdry_map.insert(make_pair(curr_id,tmp_map));
					}
					else
					{
						if(bdry_map[curr_id].find(neighbor_id)==bdry_map[curr_id].end())
						{
							struct bdry curr_bdry={0,0};
							curr_bdry.bdry_length += 1;
							curr_bdry.bdry_strength += owt[ii+curr_x+1][jj+curr_y+1];
							bdry_map[curr_id].insert(make_pair(neighbor_id,curr_bdry));
						}
						else
						{
							bdry_map[curr_id][neighbor_id].bdry_length += 1;
							bdry_map[curr_id][neighbor_id].bdry_length += owt[ii+curr_x+1][jj+curr_y+1];
						}
					}
				}
			}
		}
	}

	//base region color,texture,box_size feature
	vector<vector<double> > full_L_Hist(n_regs);
	vector<vector<double> > full_a_Hist(n_regs);
	vector<vector<double> > full_b_Hist(n_regs);
	vector<vector<double> > full_t_Hist(n_regs);
	vector<vector<double> > full_s_Hist(n_regs);
	vector<int> full_region_area(n_regs);
	vector<vector<unsigned int> > full_region_bbox(n_regs);

	//Initialize leave features
	for(size_t ii=0;ii<n_leaves;++ii)
	{
		for(size_t jj=0;jj<L_size;++jj)
			full_L_Hist[ii].push_back(L_Hist[ii][jj]);

		for(size_t jj=0;jj<a_size;++jj)
			full_a_Hist[ii].push_back(a_Hist[ii][jj]);

		for(size_t jj=0;jj<b_size;++jj)
			full_b_Hist[ii].push_back(b_Hist[ii][jj]);

		for(size_t jj=0;jj<t_size;++jj)
			full_t_Hist[ii].push_back(t_Hist[ii][jj]);

		for(size_t jj=0;jj<s_size;++jj)
			full_s_Hist[ii].push_back(s_Hist[ii][jj]);

		full_region_area[ii]=region_area[ii][0];

		for(size_t jj=0;jj<4;++jj)
			full_region_bbox[ii].push_back(region_bbox[ii][jj]);
	}

	//some variables
	vector<vector<unsigned int> > merge_matrix(merge_num);

	//Similarity computation
	map_type similarity;
	map<unsigned int,set<unsigned int> >::iterator neigh_iter;
	neigh_iter=neighbors.begin();
	for( ;neigh_iter!=neighbors.end();++neigh_iter)
	{
		unsigned int reg_a=neigh_iter->first;
		set<unsigned int>& set_neigh=neigh_iter->second;
		set<unsigned int>::iterator set_iter=set_neigh.begin();
		for( ;set_iter!=set_neigh.end();++set_iter)
		{
			unsigned int reg_b=*set_iter;
			if(reg_a<reg_b)
			{
				double split_feature[8];
				int feature_iter=0;
				if(split[0]!=0)
					split_feature[feature_iter++]=x2_difference(full_L_Hist[reg_a],full_L_Hist[reg_b]);
				if(split[1]!=0)
					split_feature[feature_iter++]=x2_difference(full_a_Hist[reg_a],full_a_Hist[reg_b]);
				if(split[2]!=0)
					split_feature[feature_iter++]=x2_difference(full_b_Hist[reg_a],full_b_Hist[reg_b]);
				if(split[3]!=0)
					split_feature[feature_iter++]=x2_difference(full_t_Hist[reg_a],full_t_Hist[reg_b]);
				if(split[4]!=0)
					split_feature[feature_iter++]=x2_difference(full_s_Hist[reg_a],full_s_Hist[reg_b]);

				if(split[5]!=0)
				{
					int  area =full_region_area[reg_a]+full_region_area[reg_b];
					split_feature[feature_iter++]=1-area/image_area;
				}

				if(split[6]!=0)
				{
					unsigned int bbox[4];
					int  area =full_region_area[reg_a]+full_region_area[reg_b];
					compute_bbox(full_region_bbox[reg_a],full_region_bbox[reg_b],bbox);
					int bbox_area=(bbox[2]-bbox[0]+1)*(bbox[3]-bbox[1]+1);
					split_feature[feature_iter++]=1-(bbox_area-area)/image_area;
				}

				if(split[7]!=0)
				{
					double bdry_strength=bdry_map[reg_a][reg_b].bdry_strength;
					int bdry_length=bdry_map[reg_a][reg_b].bdry_length;
					split_feature[feature_iter++]=bdry_strength/bdry_length;
				}
				
				double simi_value=0;
				for(int ii=0;ii<split_num;++ii)
					simi_value += weight[ii]*split_feature[ii];
				simi_value += weight[split_num];

				insert_pair(similarity,simi_value,reg_a,reg_b);
			}
		}
	}

	//Evolve through merging sequence
	size_t curr_id=n_leaves;
	int merge_id=0;
	while(merge_id<merge_num)
	{
		map_type::iterator map_iter,map_iter2;
		map_type::reverse_iterator rmap_iter=similarity.rbegin();
		list<set<unsigned int> >& pair_list=rmap_iter->second;
		list<set<unsigned int> >::iterator list_iter =pair_list.begin();
		set<unsigned int>::iterator set_iter=list_iter->begin();
		unsigned int reg_a=*set_iter;
		unsigned int reg_b=*(++set_iter);

		//region feature merge
		full_region_area[curr_id]=full_region_area[reg_a]+full_region_area[reg_b];

		unsigned int bbox[4];
		compute_bbox(full_region_bbox[reg_a],full_region_bbox[reg_b],bbox);
		for(int ii=0;ii<4;++ii)
			full_region_bbox[curr_id].push_back(bbox[ii]);

		region_merge(full_L_Hist[curr_id],full_L_Hist[reg_a],full_L_Hist[reg_b],full_region_area[curr_id],full_region_area[reg_a],full_region_area[reg_b]);
		region_merge(full_a_Hist[curr_id],full_a_Hist[reg_a],full_a_Hist[reg_b],full_region_area[curr_id],full_region_area[reg_a],full_region_area[reg_b]);
		region_merge(full_b_Hist[curr_id],full_b_Hist[reg_a],full_b_Hist[reg_b],full_region_area[curr_id],full_region_area[reg_a],full_region_area[reg_b]);
		region_merge(full_t_Hist[curr_id],full_t_Hist[reg_a],full_t_Hist[reg_b],full_region_area[curr_id],full_region_area[reg_a],full_region_area[reg_b]);
		region_merge(full_s_Hist[curr_id],full_s_Hist[reg_a],full_s_Hist[reg_b],full_region_area[curr_id],full_region_area[reg_a],full_region_area[reg_b]);
		
		//add curr_id as reg_a and reg_b 's parent
		merge_matrix[merge_id].push_back(reg_a);
		merge_matrix[merge_id].push_back(reg_b);

		//add reg_a and reg_b's neighbor to reg_c 
		set<unsigned int> reg_c_neigh;
		neigh_iter=neighbors.find(reg_a);
		//assert(neigh_iter!=neighbors.end());
		set<unsigned int> reg_a_neigh=neigh_iter->second;

		neigh_iter=neighbors.find(reg_b);	
		//assert(neigh_iter!=neighbors.end());
		set<unsigned int> reg_b_neigh=neigh_iter->second;

		union_neighbor(reg_a_neigh,reg_b_neigh,reg_c_neigh);
		if(reg_c_neigh.find(reg_a)!=reg_c_neigh.end())
			reg_c_neigh.erase(reg_a);
		if(reg_c_neigh.find(reg_b)!=reg_c_neigh.end())
			reg_c_neigh.erase(reg_b);
		update_neighbor(neighbors,curr_id,reg_c_neigh);

		//add reg_a and reg_b's bdry to reg_c
		update_bdry(bdry_map,neighbors,curr_id,reg_a,reg_b);
		
		//add simi_value between reg_c and its neighbor to map:similarity
		set_iter=reg_c_neigh.begin();
		for( ;set_iter!=reg_c_neigh.end();++set_iter)
		{
			unsigned int neighbor_id=*set_iter;

			double split_feature[8];
			int feature_iter=0;
			if(split[0]!=0)
				split_feature[feature_iter++]=x2_difference(full_L_Hist[neighbor_id],full_L_Hist[curr_id]);
			if(split[1]!=0)
				split_feature[feature_iter++]=x2_difference(full_a_Hist[neighbor_id],full_a_Hist[curr_id]);
			if(split[2]!=0)
				split_feature[feature_iter++]=x2_difference(full_b_Hist[neighbor_id],full_b_Hist[curr_id]);
			if(split[3]!=0)
				split_feature[feature_iter++]=x2_difference(full_t_Hist[neighbor_id],full_t_Hist[curr_id]);
			if(split[4]!=0)
				split_feature[feature_iter++]=x2_difference(full_s_Hist[neighbor_id],full_s_Hist[curr_id]);

			if(split[5]!=0)
			{
				int  area =full_region_area[neighbor_id]+full_region_area[curr_id];
				split_feature[feature_iter++]=1-area/image_area;
			}

			if(split[6]!=0)
			{
				unsigned int bbox[4];
				int  area =full_region_area[neighbor_id]+full_region_area[curr_id];
				compute_bbox(full_region_bbox[neighbor_id],full_region_bbox[curr_id],bbox);
				int bbox_area=(bbox[2]-bbox[0]+1)*(bbox[3]-bbox[1]+1);
				split_feature[feature_iter++]=1-(bbox_area-area)/image_area;
			}

			if(split[7]!=0)
			{
				double bdry_strength=bdry_map[curr_id][neighbor_id].bdry_strength;
				int bdry_length=bdry_map[curr_id][neighbor_id].bdry_length;
				split_feature[feature_iter++]=bdry_strength/bdry_length;
			}

			double simi_value=0;
			for(int ii=0;ii<split_num;++ii)
				simi_value += weight[ii]*split_feature[ii];
			simi_value += weight[split_num];

			insert_pair(similarity,simi_value,neighbor_id,curr_id);
		}

		//remove all reg_a and reg_b from neighbors
		remove_neighbor(neighbors,reg_a,reg_b);

		//remove all similarity which includes reg_a or reg_b
		map_iter=similarity.begin();
		while(map_iter!=similarity.end())
		{
			list<set<unsigned int> >& pair_list=map_iter->second;
			list<set<unsigned int> >::iterator list_it = pair_list.begin();
			list<set<unsigned int> >::iterator list_it2;
			while(list_it!=pair_list.end())
			{
				if(list_it->find(reg_a)!=list_it->end() || list_it->find(reg_b)!=list_it->end())
				{
					/*
					list_it2=list_it;
					++list_it;
					pair_list.erase(list_it2);
					*/
					list_it=pair_list.erase(list_it);
				}
				else
					++list_it;
			}
			if(pair_list.size()==0)
			{
				map_iter2=map_iter;
				++map_iter;
				similarity.erase(map_iter2);
			}
			else
				++map_iter;
		}

		++merge_id;
		++curr_id;
	}

    // Store at output variable cell
    plhs[0]=mxCreateDoubleMatrix(merge_num, 3,mxREAL);
	MatlabMultiArray<double> ms_matrix(plhs[0]);
	for(size_t ii=0;ii<merge_num;++ii)
	{
		vector<unsigned int>::iterator vector_iter=merge_matrix[ii].begin();
		for(size_t jj=0;vector_iter!=merge_matrix[ii].end();++jj,++vector_iter)
			ms_matrix[ii][jj]=*vector_iter+1;
		ms_matrix[ii][2]=ii+n_leaves+1;
	}
}
