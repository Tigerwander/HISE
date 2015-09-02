#include <fstream>
#include <iostream>
#include <list>
#include <map>
#include <iomanip>
#include <set>
#include <algorithm>
#include "mex.h"
#include "matlab_multiarray.hpp"
#include "linear.h"

using namespace std;
typedef map<double,list<set<unsigned int> > > map_type; 

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
	map_type::iterator map_iter=similarity.find(simi_value);
	if(map_iter==similarity.end())
	{				
		set<unsigned int> pair_region;
		pair_region.insert(id_a);
		pair_region.insert(id_b);
		list<set<unsigned int> > pair_list;
		pair_list.push_back(pair_region);
		similarity.insert(make_pair(simi_value,pair_list));
	}
	else
	{
		list<set<unsigned int> >& pair_list=map_iter->second;
		list<set<unsigned int> >::iterator pair_it=pair_list.begin();
		for( ;pair_it!=pair_list.end();++pair_it)
		{
			if(find(pair_it->begin(),pair_it->end(),id_a)!=pair_it->end() && find(pair_it->begin(),pair_it->end(),id_b)!=pair_it->end())
				break;
		}
		if(pair_it==pair_list.end())
		{
			set<unsigned int> pair_region;
			pair_region.insert(id_a);
			pair_region.insert(id_b);
			pair_list.push_back(pair_region);
		}
	}
}

double svm_predict(struct model *model_,vector<vector<double> > full_L_Hist,vector<vector<double> > full_a_Hist,vector<vector<double> > full_b_Hist,vector<vector<double> > full_t_Hist,vector<vector<double> > full_s_Hist,unsigned int reg_a,unsigned int reg_b)
{
	double L_x2=x2_difference(full_L_Hist[reg_a],full_L_Hist[reg_b]);
	double a_x2=x2_difference(full_a_Hist[reg_a],full_a_Hist[reg_b]);
	double b_x2=x2_difference(full_b_Hist[reg_a],full_b_Hist[reg_b]);
	double t_x2=x2_difference(full_t_Hist[reg_a],full_t_Hist[reg_b]);
	double s_x2=x2_difference(full_s_Hist[reg_a],full_s_Hist[reg_b]);
	struct feature_node *x;
	x[0].index=1;
	x[0].value=0;
	for(int ii=1;ii<6;++ii)
		x[ii].index=ii+1;
	x[1].value=L_x2;
	x[2].value=a_x2;
	x[3].value=b_x2;
	x[4].value=t_x2;
	x[5].value=s_x2;
	if(model_->bias>=0)
	{
		x[6].index=7;
		x[6].value=model_->bias;
	}
	x[7].index=-1;
	int nr_class=get_nr_class(model_);
	double *prob_estimates=NULL;
	prob_estimates=(double*)malloc(sizeof(double)*nr_class);	double predict_label;
	predict_label=predict_probability(model_,x,prob_estimates);
	double simi_value=prob_estimates[0];
	free(prob_estimates);
	return simi_value;
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
	map<unsigned int,set<unsigned int> >::iterator map_iter;
	set<unsigned int>::iterator set_iter;
	
	map_iter=neighbors.find(reg_a);
	assert(map_iter!=neighbors.end());
	set<unsigned int>& set_a=map_iter->second;
	set_iter=set_a.begin();
	for( ;set_iter!=set_a.end();++set_iter)
	{
		map_iter=neighbors.find(*set_iter);
		set<unsigned int>& set_tmp=map_iter->second;
		assert(set_tmp.find(reg_a)!=set_tmp.end());
		set_tmp.erase(reg_a);
	}

	map_iter=neighbors.find(reg_b);
	assert(map_iter!=neighbors.end());
	set<unsigned int>& set_b=map_iter->second;
	set_iter=set_b.begin();
	for( ;set_iter!=set_b.end();++set_iter)
	{
		map_iter=neighbors.find(*set_iter);
		set<unsigned int>& set_tmp=map_iter->second;
		assert(set_tmp.find(reg_b)!=set_tmp.end());
		set_tmp.erase(reg_b);
	}

	assert(neighbors.find(reg_a)!=neighbors.end());
	neighbors.erase(reg_a);
	assert(neighbors.find(reg_b)!=neighbors.end());
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

void update_neighbor(map<unsigned int,set<unsigned int> >& neighbors,
					unsigned int reg_id,set<unsigned int> reg_neighbor)
{
	neighbors.insert(make_pair(reg_id,reg_neighbor));
	map<unsigned int,set<unsigned int> >::iterator map_iter;
	set<unsigned int>::iterator set_iter;
	set_iter=reg_neighbor.begin();
	for( ;set_iter!=reg_neighbor.end();++set_iter)
	{
		map_iter=neighbors.find(*set_iter);
		set<unsigned int>& set_tmp=map_iter->second;
		set_tmp.insert(reg_id);
	}
}
void mexFunction( int nlhs, mxArray *plhs[], 
        		  int nrhs, const mxArray*prhs[] )
{   
    if(nrhs!=8)
        mexErrMsgTxt("There should be exactly 8 input parameters");

	/* Input parameters */
	struct model *model_;
	const char *model_file="color_model.model";
	if((model_=load_model(model_file))==0)
	{
		cout<<"cant load model file "<<model_file<<endl;
		exit(1);
	}
    ConstMatlabMultiArray<double> L_Hist(prhs[0]);
    ConstMatlabMultiArray<double> a_Hist(prhs[1]);
    ConstMatlabMultiArray<double> b_Hist(prhs[2]);
    ConstMatlabMultiArray<double> t_Hist(prhs[3]);
    ConstMatlabMultiArray<double> s_Hist(prhs[4]);
    ConstMatlabMultiArray<double> region_area(prhs[5]);
    ConstMatlabMultiArray<double> neigh_pairs_min(prhs[5]);
    ConstMatlabMultiArray<double> neigh_pairs_max(prhs[7]);
       
    std::size_t n_leaves= L_Hist.shape()[0];
	std::size_t L_size  = L_Hist.shape()[1];
	std::size_t a_size  = a_Hist.shape()[1];
	std::size_t b_size  = b_Hist.shape()[1];
	std::size_t t_size  = t_Hist.shape()[1];
	std::size_t s_size  = s_Hist.shape()[1];

	std::size_t n_pairs    = neigh_pairs_min.shape()[0];
	std::size_t n_regs     = n_leaves*2-1;

    // *********************************************************************************
    //   Compute the neighbors of each region
    // *********************************************************************************
    
    // Add initial pairs
	map<unsigned int,set<unsigned int> > neighbors;
    for (std::size_t ii=0; ii<n_pairs; ++ii)
    {
        unsigned int min_id = neigh_pairs_min[ii][0];
        unsigned int max_id = neigh_pairs_max[ii][0];        
		insert_neighbor(neighbors,min_id,max_id);
		insert_neighbor(neighbors,max_id,min_id);
    }

	//base region color,texture,box_size feature
	vector<vector<double> > full_L_Hist(n_regs);
	vector<vector<double> > full_a_Hist(n_regs);
	vector<vector<double> > full_b_Hist(n_regs);
	vector<vector<double> > full_t_Hist(n_regs);
	vector<vector<double> > full_s_Hist(n_regs);
	vector<int> full_region_area(n_regs);
	vector<vector<unsigned int> > childs(n_regs);

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
	}

	//Initial childs
	for(size_t ii=0;ii<n_leaves;++ii)
		childs[ii].push_back(ii);

	//Similarity computation
	map<unsigned int,set<unsigned int> >::iterator neigh_iter;
	map_type similarity;
	neigh_iter=neighbors.begin();
	for( ;neigh_iter!=neighbors.end();++neigh_iter)
	{
		unsigned int reg_a=neigh_iter->first;
		set<unsigned int>& set_neigh=neigh_iter->second;
		set<unsigned int>::iterator set_iter=set_neigh.begin();
		for( ;set_iter!=set_neigh.end();++set_iter)
		{
			unsigned int reg_b=*set_iter;
			double simi_value=svm_predict(model_,full_L_Hist,full_a_Hist,full_b_Hist,full_t_Hist,full_s_Hist,reg_a,reg_b);
			insert_pair(similarity,simi_value,reg_a,reg_b);
		}
	}

	map_type::iterator map_it=similarity.begin();

	vector<unsigned int> parent_label(n_regs,0);
	//Evolve through merging sequence
	size_t curr_id=n_leaves;
	while(neighbors.size()>1)
	{
		map_type::iterator map_iter=similarity.end();
		--map_iter;
		list<set<unsigned int> >& pair_list=map_iter->second;
		list<set<unsigned int> >::iterator list_iter =pair_list.begin();
		set<unsigned int>::iterator set_iter=list_iter->begin();
		unsigned int reg_a=*set_iter;
		unsigned int reg_b=*(++set_iter);

		//add new merging region about color,texture,size,box
		full_region_area[curr_id]=full_region_area[reg_a]+full_region_area[reg_b];

		region_merge(full_L_Hist[curr_id],full_L_Hist[reg_a],full_L_Hist[reg_b],full_region_area[curr_id],full_region_area[reg_a],full_region_area[reg_b]);
		region_merge(full_a_Hist[curr_id],full_a_Hist[reg_a],full_a_Hist[reg_b],full_region_area[curr_id],full_region_area[reg_a],full_region_area[reg_b]);
		region_merge(full_b_Hist[curr_id],full_b_Hist[reg_a],full_b_Hist[reg_b],full_region_area[curr_id],full_region_area[reg_a],full_region_area[reg_b]);
		region_merge(full_t_Hist[curr_id],full_t_Hist[reg_a],full_t_Hist[reg_b],full_region_area[curr_id],full_region_area[reg_a],full_region_area[reg_b]);
		region_merge(full_s_Hist[curr_id],full_s_Hist[reg_a],full_s_Hist[reg_b],full_region_area[curr_id],full_region_area[reg_a],full_region_area[reg_b]);
		
		//add curr_id as reg_a and reg_b 's parent
		parent_label[reg_a]=curr_id;
		parent_label[reg_b]=curr_id;

		//add reg_a and reg_b's neighbor to reg_c 
		set<unsigned int> reg_c_neigh;
		neigh_iter=neighbors.find(reg_a);
		set<unsigned int> reg_a_neigh=neigh_iter->second;
		neigh_iter=neighbors.find(reg_b);	
		set<unsigned int> reg_b_neigh=neigh_iter->second;
		union_neighbor(reg_a_neigh,reg_b_neigh,reg_c_neigh);
		if(reg_c_neigh.find(reg_a)!=reg_c_neigh.end())
			reg_c_neigh.erase(reg_a);
		if(reg_c_neigh.find(reg_b)!=reg_c_neigh.end())
			reg_c_neigh.erase(reg_b);
		update_neighbor(neighbors,curr_id,reg_c_neigh);
		
		//add simi_value between reg_c and its neighbor to map:similarity
		set_iter=reg_c_neigh.begin();
		for( ;set_iter!=reg_c_neigh.end();++set_iter)
		{
			unsigned int neighbor_id=*set_iter;
			double simi_value=svm_predict(model_,full_L_Hist,full_a_Hist,full_b_Hist,full_t_Hist,full_s_Hist,curr_id,neighbor_id);
			insert_pair(similarity,simi_value,curr_id,neighbor_id);
		}


		//remove all reg_a and reg_b from neighbors
		remove_neighbor(neighbors,reg_a,reg_b);

		//remove all similarity which includes reg_a or reg_b
		map_iter=similarity.begin();
		while(map_iter!=similarity.end())
		{
			list<set<unsigned int> >& pair_list=map_iter->second;
			list<set<unsigned int> >::iterator list_it = pair_list.begin();
			while(list_it!=pair_list.end())
			{
				if(list_it->find(reg_a)!=list_it->end() || list_it->find(reg_b)!=list_it->end())
					list_it=pair_list.erase(list_it);
				else
					++list_it;
			}
			if(pair_list.size()==0)
			{
				//Windows has two methods
				//fisrt map_iter=similarity.erase(map_iter);
				//second similarity.erase(map_iter++);
				//Linux
				similarity.erase(map_iter++);
			}
			else
				++map_iter;
		}

		//add childs to new region
		vector<unsigned int> tmp;
		vec_union(childs[reg_a],childs[reg_b],tmp);
		childs[curr_id]=tmp;
		sort(childs[curr_id].begin(),childs[curr_id].end());

		++curr_id;
	}
	
	vector<vector<unsigned int> > merge_matrix(n_leaves-1);
	for(size_t ii=0;ii<n_regs-1;++ii)
	{
		unsigned int parent=parent_label[ii];
		merge_matrix[parent-n_leaves].push_back(ii);
	}

    // Store at output variable cell
	free_and_destroy_model(&model_);
    plhs[0]=mxCreateDoubleMatrix(n_leaves-1, 3,mxREAL);
	MatlabMultiArray<double> ms_matrix(plhs[0]);
	for(size_t ii=0;ii<n_leaves-1;++ii)
	{
		vector<unsigned int>::iterator vector_iter=merge_matrix[ii].begin();
		for(size_t jj=0;vector_iter!=merge_matrix[ii].end();++jj,++vector_iter)
			ms_matrix[ii][jj]=*vector_iter+1;
		ms_matrix[ii][2]=ii+n_leaves+1;
	}
}
