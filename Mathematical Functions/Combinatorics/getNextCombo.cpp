/*GETNEXTCOMBO A C++ function to return the next combination in
*              lexicographic order given the current combination. If the
*              final combination in the sequence has been reached, then an
*              empty matrix is returned. The first element in the
*              combination is the least significant element for defining
*              the lexicographic order.
*
*INPUTS:    I  The current combination of r elements. The next combination
*              in lexicographic order is desired. The first element is the
*              most significant and one begins with I=[0;1;2;...r].
*           n  The number of items from which r items are chosen for
*              combinations. The elements of I can range from 0 to n-1.
*
*OUTPUTS:   I  The next combination in the lexicographic sequence, or an
*              empty matrix if the final combination in the lexicographic
*              ordering is provided.
*
* This function can be useful for generating combinations when used in a
* loop. It is more computationally efficient than sequentially unranking
* the combinations. If the final combination is put in, an empty matrix
* will be returned.
*
* The algorithm is from [1].
*
* The algorithm can be compiled for use in Matlab  using the 
* CompileCLibraries function.
*
* The algorithm is run in Matlab using the command format
* I=getNextCombo(I,n)
*
*REFERENCES:
*[1] C. J. Mifsud, "Algorithm 154: Combination in lexicographical order," 
*    Communications of the ACM, vol. 6, no. 3 pp. 103, Mar. 1963.
*    modified to start from zero instead of one.
*
*December 2013 David F. Crouse, Naval Research Laboratory, Washington D.C.
*/
/*(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.*/

#include "MexValidation.h"
/*This header is required by Matlab*/
#include "mex.h"
#include "getNextComboCPP.hpp"

void mexFunction(const int nlhs, mxArray *plhs[], const int nrhs, const mxArray *prhs[]) {
    size_t n, r;
    size_t *I;
    
    if(nrhs<2){
        mexErrMsgTxt("Not enough inputs.");
    }
    
    if(nrhs>2) {
        mexErrMsgTxt("Too many inputs.");
    }
    
    if(nlhs>1) {
        mexErrMsgTxt("Too many outputs.");
    }
    
    n=getSizeTFromMatlab(prhs[1]);
    I=copySizeTArrayFromMatlab(prhs[0],&r);

    //Verify that the I vector is not so messed up it will crash Matlab.
    {
        size_t i;
        size_t maxEl=0;
        
        //Find the maximum value in I.
        for(i=0;i<r;i++) {
            if(maxEl<I[i]) {
                maxEl=I[i];
            }
        }
        
        //If the maximum value in I is too big, or I is too big or too
        //small.
        if(maxEl>n-1||r>n||r<1) {
            mexErrMsgTxt("The I vector is invalid.");
        }
    }
    
    //If the final combination in lexicographic order was passed.
    if(getNextComboCPP(I,n,r)==true){
        plhs[0]=mxCreateDoubleMatrix(0, 0,mxREAL);
    } else {
        plhs[0]=mat2MatlabDoubles(I,r,1);
    }
}

/*LICENSE:
%
%The source code is in the public domain and not licensed or under
%copyright. The information and software may be used freely by the public.
%As required by 17 U.S.C. 403, third parties producing copyrighted works
%consisting predominantly of the material produced by U.S. government
%agencies must provide notice with such work(s) identifying the U.S.
%Government material incorporated and stating that such material is not
%subject to copyright protection.
%
%Derived works shall not identify themselves in a manner that implies an
%endorsement by or an affiliation with the Naval Research Laboratory.
%
%RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF THE
%SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY THE NAVAL
%RESEARCH LABORATORY FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE ACTIONS
%OF RECIPIENT IN THE USE OF THE SOFTWARE.*/
