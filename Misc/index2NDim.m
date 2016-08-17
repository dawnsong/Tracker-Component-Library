function indices=index2NDim(dims,idx)
%%INDEX2NDIM Given the number of dimensions of a multidimensional array and
%            the linear index of an item in the array, find the set of
%            indices that addresses the point in the array. This function
%            is like the ind2sub function, but it returns a single vector
%            when dealing with multidimensional arrays rather than
%            returning multiple outputs. This function is useful if one
%            wishes to write a function where the number of dimensions
%            needed in a hypermatrix is not known a priori, such as when
%            handling multivariate polynomials.
%
%INPUTS: dims A 1XnumDim or numDimX1 vector holding the size of each of
%             the nDim dimensions. The values are >=1.
%        idx  A numIdxX1 or 1XnumIdx vector of linear indices (starting
%             from 1, not 0).
%
%OUTPUTS: indices A numDimXnumIdx matrix of sets of indices corresponding
%                 to each of the numIdx linear indices. Indexation starts
%                 from 1, not 0. If the index is above the maximum
%                 number of elements, an empty matrix is returned.
%
%EXAMPLE:
% idx=10;
% dims=[4;3;2];
% indices0=index2NDim(dims,idx)
%The result above is the same as one would get in i1,i2,i3 using 
% [i1,i2,i3]=ind2sub(dims,idx)
%
%The function nDim2Index is the inverse of this function.
%
%August 2015 David F. Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

numIdx=length(idx);
numDim=length(dims);

%If the index is above the maximum number of items.
if(idx>prod(dims))
   indices=[];
   return;
end

indices=zeros(numDim,numIdx);
idx=idx(:)';%Make it a row vector
dims=dims(:);%Make it a row vector

%The indices basically form a counting system where the bases of each
%position are determined by dim. Matlab makes the first dimension the
%least significant. Thus, finding the indices is done in the same manner as
%one would decompose a number into digits or bits.
maxVals=[1;cumprod(dims(1:(end-1)))];
for curIdx=numDim:-1:1
    %The number of complete multiples of 
    wholeVal=fix((idx-1)/maxVals(curIdx));%The number of complete
    indices(curIdx,:)=wholeVal+1;
    idx=idx-wholeVal*maxVals(curIdx);
end

end

%LICENSE:
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
%OF RECIPIENT IN THE USE OF THE SOFTWARE.
