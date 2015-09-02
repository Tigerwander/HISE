// Multi-Thresholding Straddling Expansion (MTSE)
// Copyright 2015 Xiaozhi Chen (chenxz12@mails.tsinghua.edu.cn).
        
#include "mex.h"
#include <vector>
#include <algorithm>
#include <time.h>
#include <math.h>
using namespace std;

int clamp( int v, int a, int b ) { return v<a?a:v>b?b:v; }
#define fast_max(x,y) (x - ((x - y) & ((x - y) >> (sizeof(int) * CHAR_BIT - 1))))
#define fast_min(x,y) (y + ((x - y) & ((x - y) >> (sizeof(int) * CHAR_BIT - 1))))

typedef vector<int> vectori;
typedef vector<float> vectorf;

typedef struct { int x1, y1, x2, y2; float s; } Box;
typedef vector<Box> Boxes;
bool boxesComp( const Box &a, const Box &b ) { return a.s < b.s; }

// sort indexes descending by scores
void sort_scores(float *scores, int *idxes, int n)
{
    int i, j, tmpi;
    float tmp;
    for (i = 0; i < n; ++i)
    {
        for (j = i + 1; j < n; ++j)
        {
            if ( scores[j] > scores[i] )
            {
                tmp = scores[i];
                scores[i] = scores[j];
                scores[j] = tmp;
                
                tmpi = idxes[i];
                idxes[i] = idxes[j];
                idxes[j] = tmpi;
            }
        }
    }
}

// compute intersecion over union overlap
// This function is borrowed from P. Dollar's Edge Boxes
float boxesOverlap( Box &a, Box &b ) 
{
  float areai, areaj, areaij;
  int r0, r1, c0, c1;
  if( a.y1>=a.y2 || a.x1>=a.x2 ) return 0;
  if( a.y1>=b.y2 || a.x1>=b.x2 ) return 0;
  areai = (float) (a.x2 - a.x1) * (a.y2 - a.y1); r0=max(a.x1, b.x1); r1=min(a.x2,b.x2);
  areaj = (float) (b.x2 - b.x1) * (b.y2 - b.y1); c0=max(a.y1, b.y1); c1=min(a.y2,b.y2);
  areaij = (float) max(0,r1-r0) * max(0, c1-c0);
  return areaij / (areai + areaj - areaij);
}

// Non Maximal Suppression
// This function is borrowed from P. Dollar's Edge Boxes
void boxesNms( Boxes &boxes, float thr, int maxBoxes )
{
  sort(boxes.rbegin(),boxes.rend(),boxesComp);
  if( thr>.99 ) return; const int nBin=10000;
  const float step=1/thr, lstep=log(step);
  vector<Boxes> kept; kept.resize(nBin+1);
  int i=0, j, k, n=(int) boxes.size(), m=0, b;
  while( i<n && m<maxBoxes ) {
    b = (boxes[i].x2 - boxes[i].x1 + 1) * (boxes[i].y2 - boxes[i].y1 + 1);
    bool keep=1;
    b = clamp(int(ceil(log(float(b))/lstep)),1,nBin-1);
    for( j=b-1; j<=b+1; j++ )
      for( k=0; k<kept[j].size(); k++ ) if( keep )
        keep = boxesOverlap( boxes[i], kept[j][k] ) <= thr;
    if(keep) { kept[b].push_back(boxes[i]); m++; } i++;
  }
  boxes.resize(m); i=0;
  for( j=0; j<nBin; j++ )
    for( k=0; k<kept[j].size(); k++ )
      boxes[i++]=kept[j][k];
  sort(boxes.rbegin(),boxes.rend(),boxesComp);
}

// MTSE
void mtse(const int* sp_boxes, const int numS,
        const int* init_boxes, const int numI, 
        const vectorf thetas, const int numT, 
        const float beta, const bool combine, 
        Boxes& outBBs)
{
#define S(row,col) sp_boxes[(col) * numS + row]
#define I(row,col) init_boxes[(col) * numI + row]
    
    // preallocate memory    
    int *areaS = new int[numS];
    int *inter_ids = new int[numS];
    int *outer_ids = new int[numS];
    float *overlaps = new float[numS];    
    
    // some variables
    int i, j, k;
    int inner_count, inter_count, outer_count, cover_count;
    int x1, x2, y1, y2, mx1, mx2, my1, my2, ox1, ox2, oy1, oy2;
    int rx1, rx2, ry1, ry2;
    int areaI, area_inter, area_inner, areaM;
    float overlap_max, overlap_new, inter;
    int nnzbox = 0;        
            
    // box initialization
    Boxes boxes;
    for(i = 0; i < numI; i++)
    {
        Box b; 
        b.x1 = I(i,0); b.y1 = I(i,1); 
        b.x2 = I(i,2); b.y2 = I(i,3);
        b.s = float(numI - i);
        boxes.push_back(b);
    }
       
    // areas of sp_boxes    
    for(i = 0; i < numS; i++)
    {
        areaS[i] = (S(i,2) - S(i,0) + 1) * (S(i,3) - S(i,1) + 1);
    }    
    
    // stage 1: box alignment
    for(i = 0; i < boxes.size(); i++)
    {
        x1 = boxes[i].x1; y1 = boxes[i].y1; 
        x2 = boxes[i].x2; y2 = boxes[i].y2;
        areaI = (x2 - x1 + 1) * (y2 - y1 + 1);
        rx1 = x1; ry1 = y1; rx2 = x2; ry2 = y2;
        
        outer_count = 0;
        inter_count = 0;
        inner_count = 0;
        cover_count = 0;
        for (j = 0; j < numS; j++)
        {
            // overlap
            ox1 = fast_max(x1, S(j,0));
            oy1 = fast_max(y1, S(j,1));
            ox2 = fast_min(x2, S(j,2));
            oy2 = fast_min(y2, S(j,3));
            
            // inner regions
            if (ox1 == S(j,0) && oy1 == S(j,1) && ox2 == S(j,2) && oy2 == S(j,3))
            {
                cover_count ++;
                inner_count ++;
                // combine regions
                if (inner_count == 1)
                {
                    rx1 = ox1; ry1 = oy1; rx2 = ox2; ry2 = oy2;
                }
                else
                {
                    rx1 = fast_min(rx1, ox1);
                    ry1 = fast_min(ry1, oy1);
                    rx2 = fast_max(rx2, ox2);
                    ry2 = fast_max(ry2, oy2);
                }
            }
            else
            {
                outer_ids[outer_count] = j;
                outer_count ++;
                if (ox2 >= ox1 && oy2 >= oy1)        // intersect
                {
                    inter_ids[inter_count] = j;
                    inter_count ++;
                }
            }
        }        
        
        // Greedily add superpixels according to the intersect overlap
        if (inter_count > 0 && inner_count > 0)
        {
            // inner overlap
            area_inner = (rx2 - rx1 + 1) * (ry2 - ry1 + 1);
            overlap_max = (float)area_inner / areaI;
        
            // sort straddling set 
            for (j = 0; j < inter_count; j++)
            {
                k = inter_ids[j];
                // regions combination
                mx1 = fast_min(S(k,0), rx1);
                my1 = fast_min(S(k,1), ry1);
                mx2 = fast_max(S(k,2), rx2);
                my2 = fast_max(S(k,3), ry2);
                
                // overlap
                ox1 = fast_max(x1, mx1);
                oy1 = fast_max(y1, my1);
                ox2 = fast_min(x2, mx2);
                oy2 = fast_min(y2, my2);
                
                areaM = (mx2 - mx1 + 1) * (my2 - my1 + 1);
                area_inter = (ox2 - ox1 + 1) * (oy2 - oy1 + 1);
                overlaps[j] = (float)area_inter / (areaM + areaI - area_inter);
            }
            // sort overlaps in descending order
            sort_scores(overlaps, inter_ids, inter_count);
            overlap_new = overlaps[0];
            
            // greedy expansion
            if (overlap_new >= overlap_max)
            {
                j = 0;
                overlap_max = overlap_new;
                // combine regions
                k = inter_ids[j];
                mx1 = fast_min(S(k,0), rx1);
                my1 = fast_min(S(k,1), ry1);
                mx2 = fast_max(S(k,2), rx2);
                my2 = fast_max(S(k,3), ry2);
                rx1 = mx1; ry1 = my1; rx2 = mx2; ry2 = my2;
                
                while (overlap_new >= overlap_max && j < inter_count - 1)
                {
                    // update box
                    overlap_max = overlap_new;
                    rx1 = mx1; ry1 = my1; rx2 = mx2; ry2 = my2;
                    cover_count ++;
                                        
                    // combine regions
                    j = j + 1;
                    k = inter_ids[j];
                    mx1 = fast_min(S(k,0), rx1);
                    my1 = fast_min(S(k,1), ry1);
                    mx2 = fast_max(S(k,2), rx2);
                    my2 = fast_max(S(k,3), ry2);
                    
                    // overlap
                    ox1 = fast_max(x1, mx1);
                    oy1 = fast_max(y1, my1);
                    ox2 = fast_min(x2, mx2);
                    oy2 = fast_min(y2, my2);
                    
                    areaM = (mx2 - mx1 + 1) * (my2 - my1 + 1);
                    area_inter = (ox2 - ox1 + 1) * (oy2 - oy1 + 1);
                    overlap_new = (float)area_inter / (areaM + areaI - area_inter);
                }
            }
        }
        
        // update box
        int flag = 0 ;
        for (j = 0; j < i; j++) // remove duplicate
        {
            if (rx1 == boxes[j].x1 && ry1 == boxes[j].y1 && 
                    rx2 == boxes[j].x2 && ry2 == boxes[j].y2)
            {
                boxes[i].s = -1;
                flag = 1;
                break;
            }
        }
        if (flag == 0)
        {
            boxes[i].x1 = rx1; boxes[i].y1 = ry1; 
            boxes[i].x2 = rx2; boxes[i].y2 = ry2;
            nnzbox ++;
        }   
    }
    
    // sort in descending order w.r.t score
    sort(boxes.rbegin(), boxes.rend(), boxesComp);
    boxes.resize(nnzbox);
            
    // stage 2: straddling expansion
    // We use bounding box instead of segment to compute straddling degree
    // as they yield similar performance while bounding box saves computation
    srand((unsigned)time(0));    
    outBBs.resize(0);
    float theta;
    for(i = 0; i < boxes.size(); i++)
    {
        rx1 = boxes[i].x1; ry1 = boxes[i].y1;
        rx2 = boxes[i].x2; ry2 = boxes[i].y2;
        vectorf inters;
        vectori sp_index;
        for (k = 0; k < numS; k++)
        {            
            // overlap
            ox1 = fast_max(S(k,0), rx1); 
            oy1 = fast_max(S(k,1), ry1);
            ox2 = fast_min(S(k,2), rx2);
            oy2 = fast_min(S(k,3), ry2);

            if (ox2 >= ox1 && oy2 >= oy1)
            {
                area_inter = (ox2 - ox1 + 1) * (oy2 - oy1 + 1);
                inter = (float)area_inter / areaS[k];
                inters.push_back(inter);
                sp_index.push_back(k);
            }
        }

        // add segments with straddling degree >= theta        
        for (int t = 0; t < numT; t++)
        {
            theta = thetas[t];
            int flag = 0;
            for (j = 0; j < inters.size(); j++)
            {
                if (inters[j] >= theta)
                {
                    // combine regions
                    k = sp_index[j];
                    rx1 = fast_min(S(k,0), rx1);
                    ry1 = fast_min(S(k,1), ry1);
                    rx2 = fast_max(S(k,2), rx2);
                    ry2 = fast_max(S(k,3), ry2);

                    inters[j] = 0;
                    flag = 1;
                }
            }

            // final result
            if (flag == 1)
            {
                Box box;
                box.x1 = rx1;
                box.y1 = ry1;
                box.x2 = rx2;
                box.y2 = ry2;
                // scoring with randomness
                box.s = -i * (rand() / float(RAND_MAX)); 
                outBBs.push_back(box);
            } 
        }
    }
        
    // include initial boxes
    if (combine)
    {
        for(i = 0; i < numI; i++)
        {
            Box b; 
            b.x1 = I(i,0); b.y1 = I(i,1); 
            b.x2 = I(i,2); b.y2 = I(i,3);
            b.s = -i * (rand() / float(RAND_MAX));
            outBBs.push_back(b);
        }
    }
    
    // non maximal suppression, return no more than 10000 proposals
    boxesNms(outBBs, beta, 10000);
    
    // release memory
    delete areaS, inter_ids, outer_ids, overlaps;    
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs != 5) mexErrMsgTxt("Five inputs required.\nUsage: boxes = mtse_mex(sp_boxes, init_boxes, thetas, beta, combine)");
	if (nlhs != 1) mexErrMsgTxt("Only one output allowed.");
    
	if(mxGetClassID(prhs[0])!=mxINT32_CLASS) mexErrMsgTxt("sp_boxes must be a INT32*");
	if(mxGetClassID(prhs[1])!=mxINT32_CLASS) mexErrMsgTxt("init_boxes must be a INT32*");
	if(mxGetClassID(prhs[2])!=mxSINGLE_CLASS) mexErrMsgTxt("thetas must be a float*");

    int numS = (int)mxGetM(prhs[0]);
    int colNum0 = (int)mxGetN(prhs[0]);
    if (colNum0  != 4)
        mexErrMsgTxt("size of the first parameter sp_boxes should be N*4!\n");
    int* sp_boxes = (int *)mxGetData(prhs[0]);

    int numI = (int)mxGetM(prhs[1]);
    colNum0 = (int)mxGetN(prhs[1]);
    if (colNum0  != 4)
        mexErrMsgTxt("size of the second parameter init_boxes should be N*4!\n");
    int* init_boxes = (int *)mxGetData(prhs[1]);
	        
    int numT = (int)mxGetM(prhs[2]);
    colNum0 = (int)mxGetN(prhs[2]);
    if (numT !=1 && colNum0  != 1)
        mexErrMsgTxt("the third parameter thetas should be a vector!\n");
    float* thr = (float *)mxGetData(prhs[2]);
	numT = max(numT, colNum0);
	vectorf thetas(thr, thr + numT);
	sort(thetas.rbegin(), thetas.rend());

    float beta = float(mxGetScalar(prhs[3]));	
    bool combine = bool(mxGetScalar(prhs[4]));
    
    Boxes outBBs;    
    mtse(sp_boxes, numS, init_boxes, numI, thetas, numT, beta, combine, outBBs);
    
    // Output
    int num = (int)outBBs.size();
    plhs[0] = mxCreateNumericMatrix(num, 5, mxSINGLE_CLASS, mxREAL);
    float *bbs = (float*) mxGetData(plhs[0]);
    for(int i = 0; i < num; i++)    
    {
        bbs[ i + 0*num ] = (float) outBBs[i].x1;
        bbs[ i + 1*num ] = (float) outBBs[i].y1;
        bbs[ i + 2*num ] = (float) outBBs[i].x2;
        bbs[ i + 3*num ] = (float) outBBs[i].y2;
        bbs[ i + 4*num ] = (float) outBBs[i].s;
    }
}