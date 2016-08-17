function [phi2,phi3,dimsOrder,minCostVal,costGap]=assign3D(C,maximize,algorithm,n2Limits,n3Limits,maxIter,epsVal)
%ASSIGN3D Solve the axial 3D assignment problem. Such problems are NP-hard
%         and thus cannot be solved in polynomial time, so both exact (non-
%         polynomial) and approximate algorithms are given. The
%         optimization problem being solved is
%         minimize (or maximize)
%         \sum_{i=1}^{n1}\sum_{j=1}^{n2}\sum_{k=1}^{n3}C_{i,j,k}*\rho_{i,j,k}
%         subject to
%         \sum_{i=1}^{n1}\sum_{j=1}^{n2}\rho_{i,j,k}<=n3Limits(k) for all k
%         \sum_{i=1}^{n1}\sum_{k=1}^{n3}\rho_{i,j,k}<=n2Limits(j) for all j
%         \sum_{j=1}^{n2}\sum_{k=1}^{n3}\rho_{i,j,k} =1 for all i
%         \rho_{i,j,k} = 0 or 1
%         assuming that n1<=n2<=n3, and C is and n1Xn2Xn3 cost matrix. In
%         most instances, one assumes n2Limits and n3Limits are all ones.
%         This is equivalent to the optimization problem
%         minimize sum_{i} C(i,phi_2(i),phi_3(i))
%         where phi_2 and phi_3 are length n1 arrangements of n2 and n3
%         items over which the minimization is performed. The solution is
%         given in terms of the phi vectors.
%
%INPUTS: C An n1Xn2Xn3 cost hypermatrix. If it is not the case that
%          n1<=n2<=n3, then the indices of C are permuted so that is
%          true. The permutation of the indices is returned in the
%          dimsOrder vector so that the meaning of the phi2 and phi3 values
%          returned is clear. C cannot contain any NaNs and the largest
%          finite element minus the smallest element is a finite quantity
%          (does not overflow) when performing minimization and where
%          the smallest finite element minus the largest element is finite
%          when performing maximization.  Forbidden assignments can be
%          given costs of +Inf for minimization and -Inf for maximization.
%   maximize If true, the minimization problem is transformed into a
%            maximization problem. The default if this parameter is omitted
%            is false.
%     algorithm An optional parameter specifying the algorithm to use to
%            solve the 3D assignment problem. Possible values are
%          0 Use the relaxation approximation of [1], which is a special
%            case of [2]. Note that this method does not support the use of
%            n2Limits or n3Limits that are not all ones.
%          1 (The default if omitted or an empty matrix is passed) Use the
%            relaxation approximation of [3] applied to the problem at
%            hand.
%          2 Get an exact solution using brute-force enumeration of
%            possible solutions without bounding (i.e. more brute force 
%            than branch and bound). As described below, for an nXnXn cost
%            matrix and n3Limits all ones, this is done in a manner that is
%            O((n^3)*n!) complexity. This method does not support the use
%            of n2Limits that are not all ones.
%   n2Limits An optional n2X1 vector that provides the limits on the sums
%            over the first and third indices for each item in the second
%            index. All elements of n2Limits must be integers >=1. When
%            using n2Limits, it is required that n1<=n2<=n3 or n3<=n2<=n1.
%            That is, the final solution cannot permute n2 from its space.
%            If this parameter is omitted or an empty matrix is passed, the
%            limits are assumed to be all ones. 
%   n3Limits An optional n3X1 vector that provides the limits on the sums
%            over the first and second indices for each item in the third
%            index. All elements of n3Limits must be integers >=1. When
%            using n3Limits, it is required that n1<=n2<=n3 or n2<=n1<=n3.
%            That is, the final solution cannot permute n3 from its space.
%            If this parameter is omitted or an empty matrix is passed, the
%            limits are assumed to be all ones.
%    maxIter This parameter is only used if algorithm=0 or 1. It is the
%            maximum number of iterations to perform. The default value if
%            this parameter is omitted is 200.
%     epsVal This parameter is only used if algorithm=0. This parameter is
%            the threshold to use for determining convergence of the
%            algorithm based on the relative duality gap. The relative
%            duality gap is (f-q)/abs(q), where f is the smallest value of
%            the primal function found and q is the largest value of the
%            dual function found. If omitted, the default value is eps(1).
%
%OUTPUTS: phi2,phi3  If n1<=n2<=n3, then C(i,phi2(i),phi3(i)) is the cost
%                    for row i (row i is assigned to column phi2(i) and the
%                    third index phi3(i)). On the other hand, if it was not
%                    true that n1<=n2<=n3, then phi2 and phi3 are the same
%                    for the matrix with indices permutated such that
%                    n1<=n2<=n3.
%          dimsOrder The ordering of the dimensions of C for the assignment
%                    problem. If n1<=n2<=n3, then this is just [1,2,3].
%                    However, if the dimensions had to be permuted, then
%                    this is the permutation of them so that one knows what
%                    phi2 and phi3 refer to.
%         minCostVal The cost calue of the optimal assignment found.
%            costGap If algorithm=2, then costGap=0 as minCostVal is
%                    optimal. On the other hand, if algorithm~=2, then
%                    costGap is an upper bound for the difference between
%                    minCostVal and the true global minimum (the duality
%                    gap).
%
%The brute-force enumeration algorithm (number 2) goes through all
%permutations of assignments of the second dimension. Conditioned on those
%assignments, the problem is reduced to a 2D assignment problem. Thus, the
%function assign2D is used to solve that problem in O(n^3) time (or the
%function solveTransportationProblem is used to solve it when n3Limits are
%given). Thus, if a matrix of size nXnXn is passed, the algorithm takes
%O((n!)(n^3)) time as it has to run the 2D assignment algorithm n! times,
%one for each permutation in the first dimension.
%
%REFERENCES:
%[1] K. Pattipati, S. Deb, Y. Bar-Shalom, and R. B. Washburn Jr., "A
%    new relaxation algorithm and passive sensor data association," IEEE
%    Transactions on Automatic Control, vol. 37, no. 2, pp. 198-213, Feb.
%    1992.
%[2] S. Deb, M. Yeddanapudi, K. Pattipati, and Y. Bar-Shalom, "A
%    generalized S-D assignment algorithm for multisensor-multitarget state
%    estimation," IEEE Transactions on Aerospace and Electronic Systems,
%    vol. 33, no. 2, pp. 523-538, Apr. 1997.
%[3] A. M. Frieze and J. Yadegar, "An algorithm for solving 3-dimensional
%    assignment problems with application to scheduling a teaching
%    practice," The Journal of the Operational Research Society, vol. 32,
%    no. 11, pp. 989-995, Nov. 1981.
%
%June 2014 David F. Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

if(nargin<2||isempty(maximize))
   maximize=false; 
end

if(nargin<3||isempty(algorithm))
    algorithm=1;
end

if(nargin<6||isempty(maxIter))
    maxIter=200;
end

if(nargin<7||isempty(epsVal))
    epsVal=eps(1);
end

if(maximize==true)
    C=-C;
end

%The algorthms were implemented assuming that n1<=n2<=n3 for the
%dimensionality of C. If a matrix having a different arrangement of indices
%is passed, we will permute the indices to make the assumptions below hold.
%We have to indicate the order of the permutation for return so that the
%user knows what dims1 and dims2 refer to. If one wishes to impose more
%general constraints using n3Limits, then we have to make sure that n3 was
%not permuted from its original position. Similarly, to impose more general
%constraints on n2, we must make sure that n2 is not permuted.
nVals=size(C);
[nVals,dimsOrder]=sort(nVals,'ascend');

if(nargin<4||isempty(n2Limits)||all(n2Limits==1))
    n2Limits=[];
else
%We have n2Limits; this is if n2 was permuted and the limits are not just
%all 1.
    if(dimsOrder(2)~=2)
        error('The indices of C cannot permute the second index from its original position when using n2Limits');
    end
end

if(nargin<5||isempty(n3Limits)||all(n2Limits==1))
    n3Limits=[];
else
%We have n3Limits; this is if n3 was permitted and the limits are not
%just all 1.
    if(dimsOrder(3)~=3)
        error('The indices of C cannot permute the third index from its original position when using n3Limits');
    end
end

C=permute(C,dimsOrder);

n1=nVals(1);
n2=nVals(2);
n3=nVals(3);

switch(algorithm)
    case 0%The relaxation approximation of 1. equation numbers refer to
          %those in [1].
        if(~isempty(n2Limits)||~isempty(n3Limits))
           error('The selected algorithm does not support custom n2Limits nor custom n3Limits.')
        end
          
        alpha=2;
        %Initial value for the beta parameter.
        beta=1;
        
        u=zeros(n3,1);%Allocate and initialize the dual variables.
        H=eye(n3,n3);%The H matrix is initialized .
        
        %qStar is the best (maximum) dual cost encountered thus far.
        qStar=-Inf;
        %fTildeStar is the best (minimum) feasible primal cost encountered
        %thus far.
        fTildeStar=Inf;
        for curIter=1:maxIter
            %The H matrix is initialized on the first iteration and reset
            %to the identity matrix every n3 iterations.
            if(mod(curIter,n3)==1)
               H=eye(n3,n3);
            else
                %If the H matrix is not reinitialized, then update it using 
                %Eq. 3.17 with the value of p and g that were computed on
                %the previous iteration.
                H=H+(1-alpha^(-2))*(p*p')/(g'*p);
            end

            %The minimum values are Eq. 3.8; the minimum indices are needed
            %for Eq. 3.14b
            CDiff=bsxfun(@minus,C,reshape(u,[1,1,n3]));
            [d,minIdx]=min(CDiff,[],3);

            %Perform the minimization in (3.7) for a fixed u. As opposed to
            %directly returning omega, the columns for rows (nonzero
            %elements) are returned.
            [dim2ForDim1Cur, ~, minVal]=assign2D(d,false);
            q=minVal+sum(u);%The q(u) cost in (3.7).
            
            %Keeping track of the maximum value of q and updating beta as
            %described in the section after Eq 3.18.
            if(q>qStar)
                qStar=q;
                beta=beta+1;
            else
                beta=max(beta-1,1);
            end
            
            %Next, get a feasible solution from. This solves the
            %minimization problem of Eqs. 3.19-3.20.
            CFeas=zeros(n1,n3);
            for i=1:n1
                CFeas(i,:)=reshape(C(i,dim2ForDim1Cur(i),:),[1,n3]);
            end
            
            %Instead of the auction algorithm, assign2D, a shortest
            %augmenting path algorithm, is used.
            [dim3ForDim1Cur, ~,fTilde,mu]=assign2D(CFeas,false);
            %As noted in the comments in assign2D, the function modifies
            %the cost matrix, meaning the dual variables change. Here, we
            %put the dual variables back to where they should be.
            mu=mu+min(min(CFeas));%Add back in the minimum costs
            if(fTilde<fTildeStar)
                fTildeStar=fTilde;

                %Save the best feasible solution found thus far so that it
                %can be returned.
                phi2=dim2ForDim1Cur;
                phi3=dim3ForDim1Cur;
                minCostVal=fTildeStar;
            end
            
            %Check whether the termination criterion has been fulfilled.
            %Declare convergence based on the duality gap.
            %If convergence has been obtained. fTilde-q is the duality
            %gap. Because the problem is not convex, even at the global
            %minimum, there might still be a duality gap. The relative
            %duality gap is used as the convergence criterion.
            costGap=fTildeStar-qStar;
            relGap=costGap/abs(qStar);
            %The isfinite condition is added because if costGap==0 and
            %qStar==0, then the relative ratio will be a NaN and an
            %if-statement would have an error.
            if(costGap<=eps(fTildeStar)||(~isfinite(relGap)&&(relGap<epsVal)))
               break; 
            end
            
            %Get the rho terms. Though we have a feasible solution from
            %which we could get the rho terms, we shall use the rho terms
            %from the dual solution in Eq. 3.14b as the results are better
            %and that is how the algorithm was derived.
            rho=zeros(n1,n2,n3);
            for i1=1:n1
                rho(i1,dim2ForDim1Cur(i1),minIdx(i1,dim2ForDim1Cur(i1)))=1;
            end
            
            %Get the g vector in Eq. 3.14a.
            g=reshape(1-sum(sum(rho,1),2),[n3,1]);
            
            %If g is all zero, then no constraints were violated and the
            %algorithm should have converged to the globally optimal
            %solution. At any rate, it cannot continue due to the division
            %by the norm of g in Eq. 3.21.
            if(all(g==0))
               break; 
            end
            
            %Compute p as in Eq. 3.16.
            p=H*g;
            %The H matrix is updated at the beginning of the next
            %iteration.

            %This is the ad-hoc step adjustment in the paper.
            %Update the dual variables as in 3.21
            u=u+((fTildeStar-qStar)/norm(g)^2)*(n3/sum(mu))*(mu.*g);

            %This is not in [1], because the paper incorrectly uses
            %equality conditions when inequality conditions must be used
            %for when n1, n2, and n3 are not all equal. The Karush-Kuhn
            %Tucker conditions of [Ch. 3.3, 2] require that the Lagrange
            %multipliers be (positive or negative depending on the signs of
            %thing) when inequality constraints are used. This enforces the
            %constraints. If this were not present, we could end up with a
            %negative (invalid) duality gap.
            if(n2~=n1)
                u(u>0)=0;
            end
        end
    case 1%The relaxation approximation of [2]. Equation numbers refer to
          %those in [2].
        %This algorithm tries to maximize cost, so we will just flip the
        %sign of the costs to use it to minimize cost.
        C=-C;
        
        u=zeros(n3,1);%Allocate and initialize the dual variables.
        
        %Upper and lower bounds for the cost function encountered thus far.
        lb=-Inf;
        ub=Inf;
        %Allocate space
        dim2ForDim1Cur=zeros(n1,1);
        dim3ForDim1Cur=zeros(n1,1);
        for curIter=1:maxIter
            %Compute the w values in Equation 3.
            CDiff=bsxfun(@minus,C,reshape(u,[1,1,n3]));
            %The maxIdx is used in the computation of the subgradient.
            [w,maxIdx]=max(CDiff,[],3);
            
            %Perform the maximization in Equation 4 over xi. As opposed to
            %directly returning xi, the columns for rows (nonzero elements)
            %are returned.
            if(~isempty(n2Limits))
                n1Limits=ones(n1,1);
                [X, maxVal]=solveTransportationProblem(w,n1Limits,n2Limits,true);
                for curRow=1:n1
                   dim2ForDim1Cur(curRow)=find(X(curRow,:));
                end
            else
                [dim2ForDim1Cur, ~, maxVal]=assign2D(w,true);
            end

            phi=maxVal+sum(u);%The dual cost.
            ub=min(ub,phi);%Adjust the upper bound of the dual cost.
        
            %Next, we have to get a primal solution.            
            %The unnumbered equation before Equation 18.
            a=zeros(n1,n3);
            for i=1:n1
                a(i,:)=reshape(C(i,dim2ForDim1Cur(i),:),[1,n3]);
            end
                        
            %Perform the miximization in 8 to get eta so the primal
            %variables can be found.
            %If custom limits over the third dimension are provided.
            if(~isempty(n3Limits))
                n1Limits=ones(n1,1);
                [X, primalVal]=solveTransportationProblem(a,n1Limits,n3Limits,true);
                for curRow=1:n1
                   dim3ForDim1Cur(curRow)=find(X(curRow,:));
                end
            else
                [dim3ForDim1Cur,~,primalVal]=assign2D(a,true);
            end
         
            if(primalVal>lb)
                lb=primalVal;
                
                %Save the best feasible solution found thus far so that it
                %can be returned.
                phi2=dim2ForDim1Cur;
                phi3=dim3ForDim1Cur;
                %The - is because we want minimization, but this algorithm
                %does maximization.
                minCostVal=-lb;
            end
            
            %Check for convergence as in Algorithm 0.
            costGap=ub-lb;
            relGap=costGap/abs(ub);
            %The isfinite condition is added because if costGap==0 and
            %ub==0, then the relative ratio will be a NaN and an
            %if-statement would have an error.
            if(costGap<=eps(lb)||(~isfinite(relGap)&&(relGap<epsVal)))
               break; 
            end
            
            %For the subgradient, we have to compute xhat from xi according
            %to the unnumbered equations in the middle of Equation 4. This
            %is done in the same manner as computing rho in Eq. 3.14b of
            %[1].
            x=zeros(n1,n2,n3);
            for i1=1:n1
                x(i1,dim2ForDim1Cur(i1),maxIdx(i1,dim2ForDim1Cur(i1)))=1;
            end

            %The direction of search from Eq. 10.
            v=1-reshape(sum(sum(x,1),2),[n3,1]);
            
            if(all(v==0))
                break;
            end
            
            %Compute the stepsize from Eq. 11.
            sigma=(phi-lb)/norm(v)^2;
            
            %Take the step.
            u=u+sigma*v;
            
            %The bounding of the step to enforce the inequality constraints
            %is described in the steps before Equation 3. If n2=n1, then
            %the constraint is an equality constraint and u does not have
            %to be bounded.
            if(n2~=n1)
                u=max(0,u);
            end
        end    
    case 2%Brute-force search without branch-and-bound using 2D assignment
          %to reduce the complexity from O((n!)^2) to O((n!)(n^3)).
        if(~isempty(n2Limits))
           error('The selected algorithm does not support custom n2Limits.')
        end

        %Find the brute-force solution.
        n1Fact=factorial(n1);
        %The number of ways n2 elements can be permuted into n1 spaces.
        numArrange2=binomial(n2,n1)*n1Fact;

        %Allocate space
        CInner=zeros(n1,n3);
        minCostVal=Inf;
        col4Row=zeros(n1,1);
        for rank1=0:(numArrange2-1)
            arrange1=unrankArrangement(rank1,n2,n1);

            for i=1:n1
                CInner(i,:)=reshape(C(i,arrange1(i),:),[1,n3]);
            end
            
            %If custom limits over the third dimension are provided.
            if(~isempty(n3Limits))
                n1Limits=ones(n1,1);
                [X, costVal]=solveTransportationProblem(CInner,n1Limits,n3Limits,false);
                for curRow=1:n1
                   col4Row(curRow)=find(X(curRow,:));
                end
            else
                [col4Row, ~, costVal]=assign2D(CInner,false);
            end

            if(costVal<minCostVal)
                minCostVal=costVal;
                phi2=arrange1;
                phi3=col4Row;
            end
        end
        
        %The globally optimal solution has no cost gap.
        costGap=0;
    otherwise
        error('Invalid algorithm specified')
end

%Adjust the gains for the case where the initial cost matrix is transformed
%so that maximization can be performed.
if(maximize==true)
    minCostVal=-minCostVal;
    costGap=-costGap;
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
