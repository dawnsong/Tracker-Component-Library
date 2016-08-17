function lowerBound=assign3DLB(C,method)
%%3DASSIGNLB  Obtain a lower bound for the cost value of an axial 3D
%             assignment problem. Such problems are NP-hard and thus cannot
%             be solved in polynomial time. The optimization problem being
%             bounded is
%             minimize
%             \sum_{i=1}^{n1}\sum_{j=1}^{n2}\sum_{k=1}^{n3}C_{i,j,k}*\rho_{i,j,k}
%             subject to
%             \sum_{i=1}^{n1}\sum_{j=1}^{n2}\rho_{i,j,k}<=1 for all k
%             \sum_{i=1}^{n1}\sum_{k=1}^{n3}\rho_{i,j,k}<=1 for all j
%             \sum_{j=1}^{n2}\sum_{k=1}^{n3}\rho_{i,j,k} =1 for all i
%             assuming that n1<=n2<=n3, and C is and n1Xn2Xn3 cost matrix.
%             This is equivalent to the optimization problem
%             minimize sum_{i} C(i,phi_2(i),phi_3(i))
%             where phi_2 and phi_3 are length n1 arrangements of n2 and n3
%             items over which the minimization is performed. The lower
%             bound can usually be computed must faster than solving the
%             actual optimization problem. Indeed, the lower bounds are
%             often used in branch-and-bound algorithms to get an exact
%             solution.
%
%INPUTS:      C An n1Xn2Xn3 cost hypermatrix. The costs are real numbers >
%               -Inf. If it is not the case that n1<=n2<=n3, then the
%               indices of C are permuted so that is true.
%        method An optional parameter selecting the bound algorithm to use.
%               Possible values are:
%               0 (The default if omitted). Use the projection method
%                 followed by the Hungarian algorithm as in [1]
%                 (implemented using the Jonker-Volgenant algorrithm in
%                 assign2D in place of the Hungarian algorithm). This
%                 algorithm requires that n1=n2=n3, so if that is not the
%                 case, the cost matrix is implicitely augmented so the
%                 lower bound can still be used. The implicit augmentation
%                 is discussed in the comments to the code.
%               1 Use the simple (first) method of summing the minimum
%                 values across each first index of i as in [2]. 
%
%OUTPUTS: lowerBound A lower bound on the value of the axial 3D assignment
%                    optimization problem.
%
%An example is that given in [1], which is implemented as
% C=zeros(4,4,4);
% C(:,:,1)=[92, 51, 36, 81;
%            3, 40, 86, 11;
%            93, 10, 83, 43;
%            85, 31, 18, 19];
% C(:,:,2)=[63, 43, 44, 35;
%           58, 42, 58, 90;
%           80, 71, 8, 31;
%           44, 90, 3, 31];
% C(:,:,3)=[12, 75, 17, 97;
%           14, 7, 51, 39;
%           60, 25, 98, 24;
%           80, 73, 3, 92];
% C(:,:,4)=[29, 56, 36, 20;
%           85, 25, 28, 98;
%           52, 68, 22, 65;
%           44, 6, 20, 79];
% lowerBound0=assign3DLB(C,0);
% lowerBound1=assign3DLB(C,1);
%One will find lowerBound0=37, but lowerBound1=26, which is not as tight.
%
%REFERENCES:
%[1] B.-J. Kim, W. L. Hightower, P. M. Hahn, Y.-R. Zhu, and L. Sun, "Lower
%    bounds for the axial three-index assignment problem," European Journal
%    of Operational Research, vol. 202, no. 3, pp. 654-668, May 2010.
%[2] W. P. Pierskalla, "The tri-substitution method for the three-
%    dimensional assignment problem," Canadian Operational Research Society
%    Journal, vol. 5, no. 2, pp. 71-81, Jul. 1967.
%
%June 2014 David F. Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

%The algorthms were implemented assuming that n1<=n2<=n3 for the
%dimensionality of C. If a matrix having a different arrangement of indices
%is passed, we will permute the indices to make the assumptions below hold.
%We have to indicate the order of the permutation for return so that the
%user knows what dims1 and dims2 refer to.
nVals=size(C);
[nVals,dimsOrder]=sort(nVals,'ascend');
C=permute(C,dimsOrder);

n1=nVals(1);
n2=nVals(2);
n3=nVals(3);

if(nargin<2)
    method=0;
end

switch(method)
    case 0%The projection-Hungarian algorithm of [1].
        lowerBound=0;
        
        for curIdx=1:3
            %curIdx is the index in C over which M holds the minimum values
            %over the other two indices.
            
            %The algorithm [1] is written for matrices with the same number
            %of elements in each dimensions, so we want to add dummy 
            %entries to the matrix if the matrix is rectangular to make it
            %n3Xn3Xn3. Thus, if n1<=n2<=n3, this means that that all of the
            %extra i values assigned have zero cost for all entries of the
            %matrix, and all of the extra j values added have  infinite
            %cost for all of the existing i1 values so that they are never
            %assigned. However, it is not necessary to add all of those
            %values to the full matrix. By adding extra i values to
            %C(i,j,k), when curIdx=1, the M matrix is zero, C does not
            %change, and lowerBound=0, so that iteration is not necessary.
            %When curIdx=2, then the M matrix is used, but the infinite
            %values added to C for the extra j entries never show up in M,
            %(as it takes a minimum) and the extra i entries are all
            %zero. The extra i entries matter, because they lengthen the
            %dual vector, which changes the dual costs. With curIndex=3,
            %the dual costs do not matter and the extra entries in M could
            %have been omitted.
            
            %Thus, there is no need to actually add the extra elements to
            %C when n1~=n2 or n2~=n3 with n1<=n2<=n3. Rather, one can just
            %skip the first iteration, augment M with n3-n1 extra rows of
            %zeros for the second iteration, and then use a rectangular M
            %for the final iteration, which does not change any dual
            %values.
            
            if((n1~=n2||n2~=n3)&&(curIdx==1))
                continue;
            end
            
            %Step 1: Create the M matrix and modify the C matrix.
            if(curIdx==1)
                numRow=n2;
                numCol=n3;
                M=reshape(min(C,[],curIdx),[numRow,numCol]);
                for i=1:n1
                    C(i,:,:)=C(i,:,:)-reshape(M,[1,numRow,numCol]);
                end
            elseif(curIdx==2)
                numRow=n1;
                numCol=n3;
                M=zeros(numCol,numCol);%Zero-padded.
                M(1:numRow,:)=reshape(min(C,[],curIdx),[numRow,numCol]);
                for j=1:n2
                    C(:,j,:)=C(:,j,:)-reshape(M(1:numRow,:),[numRow,1,numCol]);
                end
            else%curIdx==3
                numRow=n1;
                numCol=n2;
                M=zeros(numRow,numCol);
                M(1:numRow,:)=reshape(min(C,[],curIdx),[numRow,numCol]);
                for k=1:n3
                    C(:,:,k)=C(:,:,k)-M(1:numRow,:);
                end
            end
    
            %Step 2: Find the minimum assignment and compute the reduced M
            %matrix.
            %The reduced cost matrix M will not be identical to that
            %obtained using the traditional Hungarian method ([1] suggested
            %using the Hungarian method) but it should be suitable to serve
            %the same purpose for reducing the C matrix.
            [~, ~, gain, u, v]=assign2D(M,false);
            lowerBound=lowerBound+gain;

            if(curIdx~=3)
                %The dual variables returned by assign2D are not the same
                %as those returned by a true shortest augmenting path
                %algorithm (the Hungarian algorithm), because a
                %preprocessing step offsets them to make the algorithm work
                %with C matrices with negative entries. Adding the minimum
                %element of M to the u dual variables gets rid of this
                %offset.
                u=u+min(min(M));

                %Create the reduced cost matrix of M using u and v.
                for curRow=1:numRow
                    for curCol=1:numCol
                        M(curRow,curCol)=M(curRow,curCol)-u(curCol)-v(curRow);
                    end
                end

                %Step 3: Modify the C matrix
                if(curIdx==1)
                    for i=1:n1
                        C(i,:,:)=C(i,:,:)+reshape(M(1:numRow,:),[1,numRow,numCol]);
                    end
                else%curIdx==2; it does not get here if curIdx==3.
                    for j=1:n2
                        C(:,j,:)=C(:,j,:)+reshape(M(1:numRow,:),[numRow,1,numCol]);
                    end

                end
            end
        end
    case 1%The very simple (first) method of [2].
        %And from Pierskala, we have a simple lower bound that will work
        %with a more general C.
        
        lowerBound=0;
        for i=1:n1
            lowerBound=lowerBound+min(reshape(C(i,:,:),[n2*n3,1]));
        end
    otherwise
        error('Invalid method chosen');
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
