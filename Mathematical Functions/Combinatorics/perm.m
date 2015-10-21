function val=perm(A,boolRowsSkip,boolColsSkip)
%%PERM  Calculate the matrix permanent allowing for rows and columns to be
%       skipped if desired (operate on a submatrix). The permanent is
%       equivalent to calculating the determininant in the standard
%       summation manner taught in school, except all of the minus signs
%       are replaced with plus signs. Permanents play a role in
%       combinatorics and the ability to skip rows and columns can be
%       useful when using permanents to compute target-measurement
%       association probabilities.
%
%INPUTS: A   An mXn matrix. If m<=n, then the standard matrix permanent is
%            found. If m>n, then the permanent of A' is found to be
%            consistent with the permanents of A and A' being equal in
%            square matrices. Empty matrices have a permanent of one by
%            definition.
%   boolRowsSkip  An optional list of rows in A that should be skipped when
%                 computing the matrix permanent. This is an mX1 or 1Xm
%                 boolean vector where a 1 means that row should be
%                 skipped. If omitted or an empty matrix is passed, no rows
%                 are skipped.
%   boolColsSkip  An optional list of columsn in A that should be skipped
%                 when computing the matrix permanent. This is an nX1 or
%                 1Xn boolean vector where a 1 means that column should be
%                 skipped. If omitted or an empty matrix is passed, no
%                 columns are skipped.
%
%OUTPUTS: val The matrix permanent of A, omitting any rows or columns as
%             necessary.
%
%Whereas polynomial-time algorithms exist for calculating determinants, it
%was proven in
%L. G. Valiant, "The complexity of computing the permanent," Theoretical
%Computer Science, vol. 8, no. 2, pp. 189-201, 1979.
%that matrix permanents can not be computed in polynomial time unless P=NP.
%However, efficient non-polynomial time algorithms exist. This file
%implements the method in theorem 4.1 on page 26 in Chapter 2 of
%H. J. Ryser, Combinatorial Mathematics, ser. The Carus Mathematical
%Monographs. The Mathematical Association of America, 1963, no. 14.
%when dealing with general rectangular matrices. When dealing with square
%matrices, the algorithm PERMAN from Chapter 23 of
%A. Nijenhuis and H. S. Wilf, Combinatorial Algorithms for Computers
%and Calculators, 2nd ed. New York: Academic press, 1978.
%is used as it is more efficient and appears to be less susceptible to
%finite precision errors. When skipping rows or columns, only Ryser's
%algorithm is used.
%
%October 2014 David F. Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

%Empty matrices have a permanent of 1 by definition.
    if(isempty(A))
        val=1;
        return;
    elseif(numel(A)==1)
        val=A;
        return;
    end

    m=size(A,1);
    n=size(A,2);
    
    %Use a modified version of Ryser's algorithm if skip lists are
    %provided.
    if(nargin>1)
        mTotal=m;
        nTotal=n;
        if(nargin<3||isempty(boolColsSkip))
            boolColsSkip=false(nTotal,1);
        end
        
        if(isempty(boolRowsSkip))
            boolRowsSkip=false(mTotal,1); 
        end
        
        numRowsSkipped=sum(boolRowsSkip);
        numColsSkipped=sum(boolColsSkip);
    
        m=mTotal-numRowsSkipped;
        n=nTotal-numColsSkipped;
        
        %Empty matrices have a permanent of 1 by definition.
        if(isempty(A)||m==0||n==0)
            val=1;
            return; 
        end

        if(m>n)
            A=A';
            temp=m;
            m=n;
            n=temp;
        end
        
        %Set the mapping of indices of the rows in the submatrix to indices in
        %the full matrix.
        rows2Keep=zeros(m,1);%Allocate space
        cumSkip=0;
        curIdx=1;
        for curRow=1:mTotal
            if(boolRowsSkip(curRow)==true)
                cumSkip=cumSkip+1;
                continue;
            else
                rows2Keep(curIdx)=curIdx+cumSkip;
                curIdx=curIdx+1;
            end
        end
    
        %Set the mapping of indices of the columns in the submatrix to indices in
        %the full matrix.
        cols2Keep=zeros(n,1);%Allocate space
        cumSkip=0;
        curIdx=1;
        for curCol=1:nTotal
            if(boolColsSkip(curCol)==true)
                cumSkip=cumSkip+1;
                continue;
            else
                cols2Keep(curIdx)=curIdx+cumSkip;
                curIdx=curIdx+1;
            end
        end
        
        binomTerm=1;
        val=0;
        for x=0:(m-1)
            val=val+SigmaSSkip(A,n-m+x,rows2Keep,cols2Keep)*binomTerm;

            binomTerm=binomTerm*(1-m+n+x)/(1+x)*(-1);
        end
        
        return;
    end
    
    if(m~=n)%Use Ryser's algorithm
        if(m>n)
            A=A';
            temp=m;
            m=n;
            n=temp;
        end

        binomTerm=1;
        val=0;
        for x=0:(m-1)
            val=val+SigmaS(A,n-m+x)*binomTerm;

            binomTerm=binomTerm*(1-m+n+x)/(1+x)*(-1);
        end
    else%If the matrix is square, use the PERMAN algorithm.
        x=zeros(n,1);%Temporary storage space.
        p=0;

        for i=1:n
            sumVal=sum(A(i,:));
            x(i)=A(i,n)-sumVal/2;
        end

        sgn=-1;
        code=[];
        nCard=n-1;
        while(1)
            sgn=-sgn;
            prodVal=sgn;
            [code,nCard,isLast,j]=getNextGrayCode(code,nCard);

            if(nCard~=0)
                z=2*code(j)-1;
                x=x+z*A(:,j);
            end
            for i=1:n
                prodVal=prodVal*x(i);
            end
            p=p+prodVal;

            if(isLast)
                break;
            end
        end
        val=2*(2*mod(n,2)-1)*p;
    end
end

function val=S(A)
%This function gives us the product of the row sums of A.
    val=prod(sum(A,2));
end

function val=SigmaS(A,r)
    %This adds up all of the possible values of S(A) where r columns of A
    %have been replaced by zeros. We shall choose the 
    %n-r columns of A that are NOT zero.
    n=size(A,2);
    combLen=n-r;
    curComb=0:(combLen-1);
    val=0;
    while(~isempty(curComb))
        val=val+S(A(:,curComb+1));
        curComb=getNextCombo(curComb,n);
    end
end

function val=SigmaSSkip(A,r,rows2Keep,cols2Keep)
    %This adds up all of the possible values of S(A) where r columns of A
    %have been replaced by zeros. We shall choose the 
    %n-r columns of A that are NOT zero.
    n=length(cols2Keep);
    combLen=n-r;
    curComb=0:(combLen-1);

    val=0;
    while(~isempty(curComb))        
        val=val+S(A(rows2Keep,cols2Keep(curComb+1)));
        curComb=getNextCombo(curComb,n);
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
